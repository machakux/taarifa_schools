from flask import request, send_from_directory
from eve.render import send_response
from werkzeug.contrib.cache import SimpleCache
cache = SimpleCache()

try:
    import simplejson as json
except ImportError:
    import json

from taarifa_api import api as app, main

from . import settings


RESOURCE_URL = getattr(settings, 'RESOURCE_URL',
                       app.config['URL_PREFIX'])


# Resources of different types are stored in one collection.
# TODO: Perform queries per resource type.
 
@app.route(RESOURCE_URL + 'values/<field>')
def resource_values(field):
    """
    Return the unique values for a given field in the resource
    collection.
    """
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    if request.args:
        resources = resources.find(dict(request.args.items()))
    return send_response('resources',
                         (sorted(resources.distinct(field)),))


@app.route(RESOURCE_URL + 'count/<field>')
def resource_count(field):
    """
    Return number of resources grouped a given field.
    """
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (resources.group(
        field.split(','), dict(request.args.items()),
        initial={'count': 0},
        reduce="function(curr, result) {result.count++;}"),))


@app.route(RESOURCE_URL + 'group_count/<field>/<group>')
def resource_stats(field, group):
    """
    Return number of resources per given field grouped by a certain
    attribute (Example: number of waterpoints of a given status
    grouped by region.
    """
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    return send_response('resources', (
        resources.aggregate([
            {
                "$match": dict(request.args.items())
            },
            {
                "$group": {
                        "_id": {group: '$' + group, field: '$' + field},
                        field + "Count": {"$sum": 1},
                    }
                },
            {
                "$group": {
                    "_id": "$_id." + group,
                    'group': {
                        '$push': {
                            field: "$_id." + field,
                            "count": '$' + field + 'Count',
                        },
                    },
                    "count": {
                        "$sum": '$' + field + 'Count'
                    }
                }
            },
            {
                "$project":{
                    "_id": 0,
                    group: "$_id",
                    'group': 1,
                    "count": 1
                }
            },
            {"$sort": {group: 1}}
        ])['result'],))


@app.route('/scripts/<path:filename>')
def scripts(filename):
    return send_from_directory(app.root_path + '/dist/scripts/',
                               filename)


@app.route('/styles/<path:filename>')
def styles(filename):
    return send_from_directory(app.root_path + '/dist/styles/',
                               filename)


@app.route('/images/<path:filename>')
def images(filename):
    return send_from_directory(app.root_path + '/dist/images/',
                               filename)


@app.route('/data/<path:filename>.topojson')
def geojson(filename):
    return send_from_directory(app.root_path + '/app/data/',
                               filename + '.topojson',
                               mimetype="application/json")


@app.route('/data/<path:filename>')
def data(filename):
    # FIXME: if we ever want to send non-JSON data this needs fixing
    return send_from_directory(app.root_path + '/dist/data/', filename,
                               mimetype="application/json")


@app.route('/views/<path:filename>')
def views(filename):
    return send_from_directory(app.root_path + '/dist/views/', filename)

if __name__ == '__main__':
    main()

