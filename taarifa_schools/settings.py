from os import environ

from taarifa_api import api as app

RESOURCE_URL = '/' + app.config['URL_PREFIX'] + '/schools/'

app.name = 'TaarifaSchools'

app.config['PAGINATION_LIMIT'] = 100000

app.config['RESOURCE_METHODS'] = ['GET']

app.config['ITEM_METHODS'] = ['GET']
