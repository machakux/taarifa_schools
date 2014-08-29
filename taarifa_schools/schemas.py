# Resource schema
resource_schema = {
    'object_id': {
        'type': 'integer',
        'label': 'Object ID',
    },
    'name': {
        'type': 'string',
        'label': 'School Name',
    },
    'code': {
        'type': 'string',
        'label': 'School code',
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
    'village': {
        'type': 'string',
        'label': 'Village',
    },
    'subvillage': {
        'type': 'string',
        'label': 'Subvillage',
    },
    'latitude': {
        'type': 'float',
        'label': 'Latitude',
    },
    'longitude': {
        'type': 'float',
        'label': 'Longitude',
    },
    'location': {
        'type': 'point',
        'label': 'Location',
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
        'type': 'float',
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
    'students_number': {
        'type': 'integer',
        'label': 'Number of students',
    },
    'teachers_number': {
        'type': 'integer',
        'label': 'Number of teachers',
    },
    'school_type': {
        'type': 'string',
        'label': 'School type',
    },
    'tution_fee': {
        'type': 'integer',
        'label': 'Tution fee',
    },
    'recording_date': {
        'type': 'datetime',
        'label': 'Date recorded',
    },
    'photo': {
        'type': 'string',
        'label': 'Photo',
    },
    'construction_year': {
        'type': 'integer',
        'label': 'Contruction year',
    },
    'midterm_parents_meeting': {
        'type': 'boolean',
        'label': 'Midterm parents meeting',
    },
}

# Facility schema
facility_schema = {
    'facility_code': 'scf001',
    'facility_name': 'Schools',
    'fields': resource_schema,
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
