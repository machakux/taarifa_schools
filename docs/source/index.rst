.. Taarifa Schools documentation master file, created by
   sphinx-quickstart on Tue Aug 26 11:36:25 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to Taarifa Schools documentation!
==========================================

Background
__________

Taarifa_ is an open source platform for the crowd sourced reporting and
triaging of infrastructure related issues. Think of it as a bug tracker
for the real world which helps to engage citizens with their local
government.

The Taarifa platform is built around the `Taarifa API`_, a RESTful
service offering that clients can interact with to create and triage
'bugreports' relating to public infrastructure (e.g., the public toilet
is broken).

For information on how to get inovoled, scroll to the Contributing section
at the bottom of the page.

Taarifa Schools
_______________

This repository contains an example application around Schools
Management built on top of the core API.

.. _Taarifa: http://taarifa.org
.. _Taarifa API: http://github.com/taarifa/TaarifaAPI

Prerequisites
_____________

Taarifa requires Python_, pip_, and MongoDB_ to be available on
the system.

Installation
____________

Requires Python, pip and the `Taarifa API`_ to be installed and MongoDB to
be running.

To ease development and debugging we suggest you use virtualenv_. 
Install virtualenv_ and virtualenvwrapper (you might need admin rights for this): ::

  pip install virtualenv virtualenvwrapper

`Set up virtualenvwrapper`_ according to your shell and create a virtualenv: ::

  mkvirtualenv TaarifaAPI

If you already created the virtualenv for the `Taarifa API`_, activate it: ::

  workon TaarifaAPI

Clone the repository ::

  git clone https://github.com/machakux/taarifa_schools

Change into directory and install the requirements ::
  
  cd taarifa_schools
  pip install -r requirements/dev.txt

Usage
_____

Make sure the virtualenv is active: ::

  workon TaarifaAPI

From the taarifa_schools directory run the following commands to
create the school schemas: ::

  python manage.py create_facility

Start the application from the taarifa_schools directory by running: ::

  python manage.py runserver -r -d

By default the API server is only accessible from the local machine. If access
from the outside is required (e.g. when running from inside a VM), run: ::

  python manage.py runserver -h 0.0.0.0 -r -d

The flags ``-r`` and ``-d`` cause the server to run in debug mode and reload
automatically when files are changed.

To verify things are working, open a browser (on the host when using the VM)
and navigate to: ::

  http://localhost:5000/api/schools

This should show a list of all the school resources currently in the
database.

Building documentation
______________________

Sphinx based documentation is available under the ``docs`` folder.
You can generate html documetation from ``docs`` directory by running:

::

    make html

This will generate html documentation within a build directory.
For more information visit http://sphinx-doc.org/tutorial.html#running-the-build
or http://sphinx-doc.org/invocation.html.



How to create a new Taarifa Service with Taarifa API
____________________________________________________

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

.. _Python: http://python.org
.. _pip: https://pip.pypa.io/en/latest/installing.html
.. _MongoDB: http://mongodb.org
.. _virtualenv: http://virtualenv.org
.. _Set up virtualenvwrapper: http://virtualenvwrapper.readthedocs.org/en/latest/install.html#shell-startup-file
.. _Taarifa: http://taarifa.org
.. _taarifa-dev: https://groups.google.com/forum/#!forum/taarifa-dev
.. _Taarifa API: http://github.com/taarifa/TaarifaAPI

