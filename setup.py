#!/usr/bin/env python2

import json

def load_config():
	variables = {}

	try:
		with open('./terraform/local-vars.json') as local_vars_file:
			# Read local variables
			local_vars_config = json.load(local_vars_file)['variable']

			for variable_name in local_vars_config.keys():
				variable_value = local_vars_config[variable_name]['default']

				variables[variable_name] = variable_value
	except IOError:
		pass

	return variables

def show_config(variables):
	if len(variables) == 0:
		return

	print('Local configuration:')
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

print('Examining configuration...')
local_vars = load_config()
show_config(local_vars)
