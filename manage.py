from pprint import pprint

from flask.ext.script import Manager

from taarifa_api import add_document

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

if __name__ == "__main__":
    manager.run()
