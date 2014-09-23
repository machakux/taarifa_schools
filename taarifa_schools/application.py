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

app.name = 'TaarifaSchools'

# Override the maximum number of results on a single page
# This is needed by the dashboard
# FIXME: this should eventually be replaced by an incremental load
# which is better for responsiveness
app.config['PAGINATION_LIMIT'] = 100000

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


@app.route(RESOURCE_URL + 'sum/<group>/<field>')
def resource_sum(group, field):
    """
    Return sum of a given field per group.
    """
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    fields = field.split(',')
    data = app.data.driver.db['resources'].aggregate([
        {
            "$match": dict(request.args.items())
        },
        {
            "$group": {
                "_id": '$' + group,
                "sum": {'$sum': {'$add': ['$' + f for f in fields] }},
            }
        },
        {"$sort": {group: 1}}])['result']
    return send_response('resources', [data])


@app.route(RESOURCE_URL + 'total_count')
def resource_total_count():
    """
    Return number of resources matching a given query.
    """
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    resources = app.data.driver.db['resources']
    query = dict(request.args.items())
    if query.has_key('$where'):
        try:
            query = json.loads(query['$where'])
        except:
            pass
    print query
    return send_response('resources', ({'count': resources.find(query).count()},))


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


@app.route(RESOURCE_URL + 'performance/<group>')
def performance(group):
    """
    Return performance stats.
    """
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    # TODO: Provide generic implementation to allow more dynamic grouping
    resources = app.data.driver.db['resources']
    return send_response('resources', (
        resources.aggregate([
            {
                "$match": dict(request.args.items())
            },
            {
                "$group": {
                    "_id": '$' + group,
                    "numberPass": {'$sum': '$number_pass'},
                    "numberPassLast": {'$sum': '$number_pass_last'},
                    "numberPassBeforeLast": {'$sum': '$number_pass_before_last'},
                    "candidates": {'$sum': '$candidates'},
                    "candidatesLast": {'$sum': '$candidates_last'},
                    "candidatesBeforeLast": {'$sum': '$candidates_before_last'},
        
                }
            },
            {
                "$project": {
                    "_id": 0,
                    group: "$_id",
                    "numberPass": 1,
                    "numberPassLast": 1,
                    "numberPassBeforeLast": 1,
                    "candidates": 1,
                    "candidatesLast": 1,
                    "candidatesBeforeLast": 1,
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

