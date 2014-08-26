Taarifa Schools
===============

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

Schools
_______

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
  python manage.py create_service

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

.. _Python: http://python.org
.. _pip: https://pip.pypa.io/en/latest/installing.html
.. _MongoDB: http://mongodb.org
.. _virtualenv: http://virtualenv.org
.. _Set up virtualenvwrapper: http://virtualenvwrapper.readthedocs.org/en/latest/install.html#shell-startup-file
.. _Taarifa: http://taarifa.org
.. _taarifa-dev: https://groups.google.com/forum/#!forum/taarifa-dev
.. _Taarifa API: http://github.com/taarifa/TaarifaAPI

