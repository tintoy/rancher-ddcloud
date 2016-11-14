#!/usr/bin/env python2

import json
import urllib2

local_vars_path = './terraform/local-vars.json'

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
  with open(local_vars_path, 'w') as local_vars_file:
    local_vars_data = {
      'variable': {}
    }
    for name, value in variables.items():
      local_vars_data['variable'] = {
        'name': {
          'default': value
        }
      }

    json.dump(local_vars_data, local_vars_file)

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

local_vars = load_config()

if len(local_vars) > 0:
  print('Existing configuration:\n')
  show_config(local_vars)

print('')
print('=' * 80)
print('')

print('Detecting client IP...')
response = json.loads(
  urllib2.urlopen('http://ifconfig.co/json').read()
)
local_vars['client_ip'] = response['ip']

print('')
print('=' * 80)
print('')

print('Current configuration:\n')
show_config(local_vars)
