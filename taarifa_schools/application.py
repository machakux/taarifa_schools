from flask import request, send_from_directory, Response
from eve.render import send_response
from werkzeug.contrib.cache import SimpleCache
cache = SimpleCache()

try:
    import simplejson as json
except ImportError:
    import json

from taarifa_api import api as app, main

from . import settings
from .utils import csv_dictwritter


RESOURCE_URL = getattr(settings, 'RESOURCE_URL',
                       app.config['URL_PREFIX'])


@app.route(RESOURCE_URL + 'download/')
def resource_download():
    """
    Return resources.
    """
    params = dict(request.args.items())
    fmt = params.pop('fmt', 'csv')
    fields = params.pop('fields', None)
    limit = params.pop('max_results', 1000)
    sort = params.pop('sort', None)
    search = params.pop('search', None)
    if sort:
        sort = json.loads(sort)
    if limit:
        try:
            limit = int(limit)
            if limit > 1000 or limit < 0:
                limit = 1000
        except:
            limit = 1000
    if fields:
        fields = fields.split(',')
    if search:
        params['$text'] = {'$search': '\"' + search + '\"'}
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    data = list(
        app.data.driver.db['resources'].find(
            params, sort=sort).limit(limit))
    if fmt == 'csv':
        for item in data:
            location = item.get('location')
            if location:
                try:
                    item['longitude'] = location['coordinates'][0]
                    item['latitude'] = location['coordinates'][1]
                    item.pop('location')
                except:
                    pass
        headers = {
            'Content-Type': 'text/csv',
            'Content-Disposition': 'attachment; filename="schools.csv"'
        }
        try:
            csvdata = csv_dictwritter(data, fields)
            return Response(csvdata, mimetype='text/csv', headers=headers)
        except:
            pass
    return send_response('resources', [data])


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
    params = dict(request.args.items())
    fmt = params.pop('fmt', None) 
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    data = app.data.driver.db['resources'].group(
        field.split(','), params,
        initial={'count': 0},
        reduce="function(curr, result) {result.count++;}")
    if fmt == 'csv':
        headers = {
            'Content-Type': 'text/csv',
            'Content-Disposition': 'attachment; filename="count_%s.csv"' %field
        }
        return Response(csv_dictwritter(data), mimetype='text/csv', headers=headers)
    return send_response('resources', [data])


@app.route(RESOURCE_URL + 'sum/<group>/<field>')
def resource_sum(group, field):
    """
    Return sum of a given field per group.
    """
    fields = field.split(',')
    params = dict(request.args.items())
    fmt = params.pop('fmt', None) 
    # FIXME: Direct call to the PyMongo driver, should be abstracted
    data = app.data.driver.db['resources'].aggregate([
        {
            "$match": params
        },
        {
            "$group": {
                "_id": '$' + group,
                "sum": {'$sum': {'$add': ['$' + f for f in fields] }},
            }
        },
        {"$sort": {group: 1}}])['result']
    if fmt == 'csv':
        headers = {
            'Content-Type': 'text/csv',
            'Content-Disposition': 'attachment; filename="sum_%s-%s.csv"' %(field, group)
            }
        return Response(csv_dictwritter(data), mimetype='text/csv', headers=headers)
    if fmt == 'csv':
        headers = {
            'Content-Type': 'text/csv',
            'Content-Disposition': 'attachment; filename="sum_%s-%s.csv"' %(field, group)
        }
        return Response(csv_dictwritter(data), mimetype='text/csv', headers=headers)
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
    
    params = dict(request.args.items())
    fmt = params.pop('fmt', None) 
    data = app.data.driver.db['resources'].aggregate(
        [
            {
                "$match": params
            },
            {
                "$group": {
                    "_id": '$' + group,
                    "numberPass": {'$sum': '$number_pass'},
                    "numberPassLast": {'$sum': '$number_pass_last'},
                    "numberPassBeforeLast": {'$sum': '$number_pass_before_last'},
                    "candidates": {'$sum': '$candidates'},
                    "candidatesLast": {'$sum': '$candidates_last'},
                    "candidatesBeforeLast": {'$sum': '$candidates_before_last'}        
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
                    "percentPass": {
                        '$cond': {'if': { '$ne': [ "$candidates", 0 ] },
                        'then': {'$multiply': [{'$divide': ['$numberPass', '$candidates']}, 100]},
                        'else': None }},
                    "percentPassLast": {
                        '$cond': {'if': { '$ne': [ "$candidatesLast", 0 ] },
                        'then': {'$multiply': [{'$divide': ['$numberPassLast', '$candidatesLast']}, 100]},
                        'else': None }},
                    "percentPassBeforeLast": {
                        '$cond': {'if': { '$ne': [ "$candidatesBeforeLast", 0 ] },
                        'then': {'$multiply': [{'$divide': ['$numberPassBeforeLast', '$candidatesBeforeLast']}, 100]},
                        'else': None }}
                }
            },
            {"$sort": {group: 1}}
        ])['result']
    if fmt == 'csv':
        headers = {
            'Content-Type': 'text/csv',
            'Content-Disposition': 'attachment; filename="performance_%s.csv"' %group
        }
        return Response(csv_dictwritter(data), mimetype='text/csv', headers=headers)
    return send_response('resources', [data])


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


@app.route("/")
def index():
    return send_from_directory(app.root_path + '/dist/', 'index.html')


@app.route("/favicon.ico")
def favicon():
    return send_from_directory(app.root_path + '/dist/', 'favicon.ico')

if __name__ == '__main__':
    main()

