#!/usr/bin/env python2

import json
import socket
import urllib2

local_vars_path = './terraform/local-vars.tf'

def load_config():
  variables = {}

  try:
    with open(local_vars_path, 'r') as local_vars_file:
      # Read local variables
      local_vars_config = json.load(local_vars_file)['variable']

      for variable_name in local_vars_config.keys():
        variable_value = local_vars_config[variable_name]['default']

        variables[variable_name] = variable_value
  except IOError:
    pass # No existing configuration.

  return variables

def save_config(variables):
  local_vars_data = {
    'variable': {}
  }
  for name, value in variables.items():
    local_vars_data['variable'][name] = {
      'default': value
    }

  with open(local_vars_path, 'w') as local_vars_file:
    json.dump(local_vars_data, local_vars_file, indent=2)

def show_config(variables):
  if 'client_ip' in variables:
    print('Client IP              = "{}"'.format(
      variables['client_ip'])
    )
  if 'ssh_public_key_file' in variables:
    print('SSH public key file    = "{}"'.format(
      variables['ssh_public_key_file'])
    )
  if 'ssh_bootstrap_password' in variables:
    print('SSH bootstrap password = "{}"'.format(
      variables['ssh_bootstrap_password'])
    )

def ask_variable(variables, key, prompt):
  value = raw_input('{} (currently "{}"): '.format(
    prompt, variables.get(key, '')
  ))
  if value != "":
    local_vars[key] = value

def detect_client_ip(variables):
  request = urllib2.Request(
    'http://{}/json'.format(
      socket.gethostbyname('ifconfig.co') # We need the IPv4 address
    ),
    headers = {'Host': 'ifconfig.co'}
  )

  response = json.loads(
    urllib2.urlopen(request).read()
  )
  
  variables['client_ip'] = response['ip']

local_vars = load_config()

if len(local_vars) > 0:
  print('Existing configuration:\n')
  show_config(local_vars)

print('')
print('=' * 80)
print('')

ask_variable(local_vars, 'client_ip', 'Client IP address')
if 'client_ip' not in local_vars:
  print('Detecting client IP...')
  detect_client_ip(local_vars)
ask_variable(local_vars, 'ssh_public_key_file', 'SSH public key file')
ask_variable(local_vars, 'ssh_bootstrap_password', 'SSH bootstrap password file')

save_config(local_vars)

print('')
print('=' * 80)
print('')

print('Current configuration:\n')
show_config(local_vars)
