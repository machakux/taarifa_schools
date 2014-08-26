# Resource schema
school_schema = {
    'object_id': {
        'type': 'integer',
        'label': 'Object ID',
    },
    'code': {
        'type': 'string',
        'label': 'School code',
    },
    'name': {
        'type': 'string',
        'label': 'School Name',
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
        'label': 'District code',
    },
    'ward': {
        'type': 'string',
        'label': 'Ward',
    },
    'ward_code': {
        'type': 'string',
        'label': 'Ward code',
    },
    'village': {
        'type': 'string',
        'label': 'Village',
    },
    'subvillage': {
        'type': 'string',
        'label': 'Subvillage',
    },
    'location': {
        'type': 'point',
    },
    'district_rank': {
        'type': 'integer',
        'label': 'District rank',
    },
    'regional_rank': {
        'type': 'integer',
        'label': 'Regional rank',
    },
    'national_rank': {
        'type': 'integer',
        'label': 'National rank',
    },
    'percentage_pass': {
        'type': 'integer',
        'label': 'Percentage pass',
        'min': 0,
        'max': 100,
    },
    'candidates_number': {
        'type': 'integer',
        'label': 'Number of candidates',
    },
    'examination_year': {
        'type': 'integer',
        'label': 'Percentage pass year',
        'min': 1900,
        'max': 9999,
    },
    'school_type': {
        'type': 'string',
        'label': 'School type',
    },
    'students_number': {
        'type': 'integer',
        'label': 'Number of students',
    },
    'teachers_number': {
        'type': 'integer',
        'label': 'Number of teachers',
    },
    'date_recorded': {
        'type': 'datetime',
        'label': 'Date recorded',
    },
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

