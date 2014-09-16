from pprint import pprint
from datetime import datetime
from csv import DictReader

import pymongo

from flask.ext.script import Manager

from taarifa_api import add_document, delete_documents

from taarifa_schools import app
from taarifa_schools.schemas import facility_schema, service_schema


manager = Manager(app)


def check(response, success=201, print_status=True):
    data, _, _, status = response
    if status == success:
        if print_status:
            print " Succeeded"
        return True

    print "Failed with status", status
    pprint(data)
    return False


@manager.command
def create_facility():
    """Register project facility."""
    check(add_document('facilities', facility_schema))


@manager.command
def create_service():
    """Register project service."""
    check(add_document('services', service_schema))


@manager.command
def delete_facilities():
    """Delete all facilities."""
    check(delete_documents('facilities'), 200)


@manager.command
def delete_services():
    """Delete all services."""
    check(delete_documents('services'), 200)


@manager.option("filename", help="CSV file to upload (required)")
@manager.option("--skip", type=int, default=0, help="Skip a number of records")
@manager.option("--limit", type=int, help="Only upload a number of records")
def upload_resources(filename, skip=0, limit=None):
    """Upload  from a CSV file."""
    # Use sys.stdout.write so resources can be printed nicely and succinctly
    import sys

    date_converter = lambda s: datetime.strptime(s, '%Y-%m-%d')
    bool_converter = lambda s: s == "true"
    resource_schema = facility_schema['fields']
    
    convert_map = {
		'integer': int,
		'float': float,
		'datetime': date_converter,
		'boolean': bool_converter
    }

    convert = {}
    
    for k, v in resource_schema.items():
		field_type = v.get('type')
		if convert_map.has_key(field_type):
			convert[k] = convert_map[field_type]

    def print_flush(msg):
        sys.stdout.write(msg)
        sys.stdout.flush()

    facility_code = facility_schema['facility_code']
    print_every = 1000
    print_flush("Adding resources. Please be patient.")

    with open(filename) as f:
        reader = DictReader(f)
        for i in range(skip):
            reader.next()
        for i, d in enumerate(reader):
            actual_index = i + skip + 2
            do_print = actual_index % print_every == 0
            try:
                d = dict((k, convert.get(k, str)(v)) for k, v in d.items() if v)
                coords = [d.pop('longitude', None), d.pop('latitude', None)]
                if coords[0] and coords[1]:
                    d['location'] = {'type': 'Point', 'coordinates': coords}
                d['facility_code'] = facility_code
                if not check(add_document(facility_schema['endpoint'], d), 201, False):
                    raise Exception()
                if do_print:
                    print_flush(".")

            except Exception as e:
                print "Error adding resource", e
                pprint(d)
                exit()

            if limit and i >= limit:
                break
    # Create a 2dsphere index on the location field for geospatial queries
	app.data.driver.db['resources'].create_index([('location', '2dsphere')])
    print "Resources uploaded!"


@manager.command
def delete_resources():
    """Delete all existing resources"""
    print delete_documents(facility_schema['endpoint'])


@manager.command
def rebuild_indexes():
    """Make sure all important database indexes are created."""
    query_index = [
        ('school_type', pymongo.ASCENDING),
        ('region', pymongo.ASCENDING),
        ('district', pymongo.ASCENDING),
        ('national_rank', pymongo.ASCENDING),
    ]

    spatial_index = [('location', pymongo.GEOSPHERE)]

    text_index = [
        ('name', pymongo.TEXT),
        ('code', pymongo.TEXT),
        ('region', pymongo.TEXT),
        ('district', pymongo.TEXT),
        ('village', pymongo.TEXT),
    ]
    
    text_weights = {
        'name': 2,
        'code': 2
    }

    print "Droping existing indexes ..."
    app.data.driver.db['resources'].drop_indexes()
    app.data.driver.db['facilities'].drop_indexes()
    app.data.driver.db['services'].drop_indexes()
    print "Creating resources index for more efficient querying ..."
    app.data.driver.db['resources'].ensure_index(query_index, name='QueryIndex', background=True)
    print "Creating location index for spatial queries ..."
    app.data.driver.db['resources'].ensure_index(spatial_index, name='2dSphereIndex', background=True)
    print "Creating resources index for text search ..."
    app.data.driver.db['resources'].ensure_index(text_index, name='TextIndex', background=True, weights=text_weights)
    print "Indexes created!"


if __name__ == "__main__":
    manager.run()
