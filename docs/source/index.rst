.. Taarifa Schools documentation master file, created by
   sphinx-quickstart on Tue Aug 26 11:36:25 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to Taarifa Schools' documentation!
==========================================


Introduction
============
The core ``TaarifaAPI`` provides a base platform for building various types of services management systems.


How to create a new Taarifa Service with Taarifa API
====================================================

Setting up Taarifa API development enviroment
---------------------------------------------

In order to create a new application based on Taarifa API you may need to setup TaarifaAPI development environment.
The instructions for setting up the development environment are available at https://github.com/taarifa/TaarifaAPI.

Starting your project
-------------------------

You can bootstrap your new project by creating a new directory for the project.
Assuming your project directory is called ``projectname`` then add files and directories based on the following structure:

::

    projectname/
    |__ manage.py
    |__ projectname/
    |     |__ __init__.py
    |     |__ application.py
    |     |__ schemas.py
    |__ requirements.txt
    

This is just a basic project structure therefore you can add other files and directories whenever you want.


Defining schemas
----------------

The file ``projectname/projectname/schemas.py`` will hold project schemas.
This file will contain defitions of various data structures.

Resource schema
~~~~~~~~~~~~~~~

A resource schema defines the data structure of each resource.
A **resource:** is particular addressable piece of infrastructure (e.g., Church Street, the waterpoint)

*Example: Defining resource schema ( ``projectname/projectname/schemas.py`` )*

::

    # Resource schema
    myresource_schema = {
        'gid': {
            'type': 'integer',
            'label': 'GID',
        },
        'object_id': {
            'type': 'integer',
            'label': 'Object ID',
            'unique': True
        },
        'breakdown_date': {
            'type': 'datetime',
            'label': 'Breakdown date',
        },
    }


Facility schema
~~~~~~~~~~~~~~~

Facility and resources go hand in hand.
Following Open311 the facility schema uses fields attribute to include the resource schema for all resources that are part of the facility.

*Example: Defining facility schema ( ``projectname/projectname/schemas.py`` )*

::

    # Facility schema
    facility_schema = {
        'facility_code': 'mfc001',
        'facility_name': 'My Resources',
        'fields': myresource_schema,
        'description': 'My resource infrastructure in My country',
        'keywords': ['location', 'mycategory', 'infrastructure'],
        'group': "mycategory",
        'endpoint': "myresources"
    }


Service schema
~~~~~~~~~~~~~~
Service may define what the schema of a request (report) should look like.

*Example: Defining service schema ( ``projectname/projectname/schemas.py`` )*

::

    # Service schema
    service_schema = {
        "service_name": "Public My resource Service",
        "attributes": [],
        "description": "My resource dessription",
        "keywords": ["location", "infrastructure", "mycategory"],
        "group": "mycategory",
        "service_code": "msc001"
    }

Creating a minimal Application
------------------------------

In ``projectname/projectname/application.py`` file add the following code

::

    from taarifa_api import api as app, main

    if __name__ == '__main__':
        main()

For future convenience add the following to ``projectname/projectname/__init__.py``

::

    from application import app  # noqa


Creating project management script
----------------------------------

In ``projectname/manage.py`` add the following to create management commands that will simplify the process of registering facility and service to the database.

::

    from flask.ext.script import Manager

    from taarifa_api import add_document
    
    from projectname import app
    from projectname.schemas import facility_schema, service_schema

    manager = Manager(app)

    @manager.command
    def create_facility():
        """Register project service."""
        check(add_document('facilities', facility_schema))
    
    
    @manager.command
    def create_service():
        """Register project service."""
        check(add_document('services', service_schema))

    if __name__ == "__main__":
        manager.run()


Schema registation
------------------

To register your facility schema run

::

    python manage.py create_facility

Then register your service by running

::

    python manage.py create_service


Running the API server
----------------------

To start your API server you can just run

::

    python manage.py create_service -r- d

The ``-r`` and ``d`` optional parameter are to enable autoreload and debug mode respectively.

And thats it. Now you can check your API service from a web browser by just visting http://127.0.0.1:5000/



