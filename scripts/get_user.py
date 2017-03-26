#!/usr/bin/env python
from ConfigParser import ConfigParser
from os import environ
from AssemblyUtil.authclient import KBaseAuth as _KBaseAuth


token = environ.get('KB_AUTH_TOKEN', None)
config_file = environ.get('KB_DEPLOYMENT_CONFIG', '/kb/module/deploy.cfg')
cfg = {}
config = ConfigParser()
config.read(config_file)
for nameval in config.items('AssemblyRAST'):
	cfg[nameval[0]] = nameval[1]
authServiceUrl = cfg.get('auth-service-url', "https://kbase.us/services/authorization/Sessions/Login")
auth_client = _KBaseAuth(authServiceUrl)
user_id = auth_client.get_user(token)
print user_id
