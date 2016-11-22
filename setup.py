#!/usr/bin/env python2

from collections import OrderedDict
import json
import os
from os import path
import socket
import urllib2

local_vars = {}
local_vars_path = path.join(path.dirname(__file__), 'terraform/local-vars.tf')

# Quick-and-dirty questions and answers
variable_descriptions = OrderedDict()
variable_descriptions['client_ip'] = 'Client IP address'
variable_descriptions['ssh_public_key_file'] = 'SSH public key file'
variable_descriptions['ssh_bootstrap_password'] = 'SSH bootstrap password'
variable_descriptions['dns_domain_name'] = 'Top-level domain name'
variable_descriptions['dns_subdomain_name'] = 'Sub-domain name'
variable_descriptions['dns_hosted_zone_id'] = 'AWS hosted DNS zone Id'
variable_descriptions['aws_access_key'] = 'AWS access key'
variable_descriptions['aws_secret_key'] = 'AWS secret key'

# For padding questions so text lines up
variable_description_max = max(
    len(description) for description in variable_descriptions.values()
)


def load_config():
    local_vars['ssh_public_key_file'] = path.join(
        os.getenv('HOME'), ".ssh/id_rsa"
    )

    try:
        with open(local_vars_path, 'r') as local_vars_file:
            # Read local variables
            local_vars_config = json.load(local_vars_file)['variable']

            for variable_name in local_vars_config.keys():
                variable_value = local_vars_config[variable_name]['default']

                local_vars[variable_name] = variable_value
    except IOError:
        print('(no existing configuration)')
        pass  # No existing configuration.


def save_config():
    local_vars_data = {
        'variable': {}
    }
    for name, value in local_vars.items():
        local_vars_data['variable'][name] = {
            'default': value
        }

    with open(local_vars_path, 'w') as local_vars_file:
        json.dump(local_vars_data, local_vars_file, indent=2)


def show_config():
    for variable_name in variable_descriptions.keys():
        if variable_name not in local_vars:
            continue

        print('{} = "{}"'.format(
            variable_descriptions[variable_name].ljust(
                variable_description_max, ' '
            ),
            local_vars[variable_name]
        ))


def ask_variable(key):
    value = raw_input('{} (currently "{}")] = '.format(
        variable_descriptions[key],
        local_vars.get(key, '')
    ))

    if value != "":
        local_vars[key] = value.strip()


def clear_variable(key):
    local_vars.pop(key, None)


def detect_client_ip():
    request = urllib2.Request(
        'http://{}/json'.format(
            socket.gethostbyname('ifconfig.co')  # We need the IPv4 address
        ),
        headers={'Host': 'ifconfig.co'}
    )

    response = json.loads(
        urllib2.urlopen(request).read()
    )

    local_vars['client_ip'] = response['ip']


def have_dns_config():
    try:
        os.stat(
            path.join(path.dirname(__file__), 'terraform/dns.tf')
        )
    except FileNotFoundError:
        return False
    else:
        return True


load_config()
if len(local_vars) > 0:
    print('Existing configuration:\n')
    show_config()

print('')
print('=' * 80)
print('')

ask_variable('client_ip')
if 'client_ip' not in local_vars:
    print('Detecting client IP...')
    detect_client_ip()
ask_variable('ssh_public_key_file')
ask_variable('ssh_bootstrap_password')
if have_dns_config():
    ask_variable('dns_domain_name')
    ask_variable('dns_subdomain_name')
    ask_variable('dns_hosted_zone_id')
    ask_variable('aws_access_key')
    ask_variable('aws_secret_key')
else:
    clear_variable('dns_domain_name')
    clear_variable('dns_subdomain_name')
    clear_variable('dns_hosted_zone_id')
    clear_variable('aws_access_key')
    clear_variable('aws_secret_key')

save_config()

print('')
print('=' * 80)
print('')

print('Current configuration:\n')
show_config()
