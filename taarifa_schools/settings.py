from os import environ

from taarifa_api import api as app

RESOURCE_URL = '/' + app.config['URL_PREFIX'] + '/schools/'
