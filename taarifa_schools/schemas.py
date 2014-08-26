# Resource schema
school_schema = {
    'object_id': {
        # Idealy this should be unique and parmanent
        'type': 'integer',
        'label': 'Object ID',
    },
    'name': {
        'type': 'string',
        'label': 'Name',
    },
    'region': {
        'type': 'string',
        'label': 'Region',
    },
    'region_code': {
        'type': 'integer',
        'label': 'Region Code',
    },
    'district': {
        'type': 'string',
        'label': 'District',
    },
    'district_code': {
        'type': 'integer',
        'label': 'District Code',
    },
    'ward': {
        'type': 'string',
        'label': 'Ward',
    },
    'ward_code': {
        'type': 'string',
        'label': 'Ward Code',
    },
    'district': {
        'type': 'string',
        'label': 'District',
    },
    'village': {
        'type': 'string',
        'label': 'Village',
    }
}

# Facility schema
facility_schema = {
    'facility_code': 'scf001',
    'facility_name': 'Schools',
    'fields': school_schema,
    'description': 'Schools infrastructure in Tanzania',
    'keywords': ['location', 'education', 'infrastructure'],
    'group': "education",
    'endpoint': "schools"
}

# Service schema
service_schema = {
    "service_name": "Public Schools Service",
    "attributes": [],
    "description": "Location and perfomance of schools",
    "keywords": ["location", "infrastructure", "education"],
    "group": "education",
    "service_code": "scs001"
}
