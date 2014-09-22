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
    'district': {
        'type': 'string',
        'label': 'District',
    },
    'ward': {
        'type': 'string',
        'label': 'Ward',
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
    'national_rank': {
        'type': 'integer',
        'label': 'National rank',
    },
    'national_rank_last': {
        'type': 'integer',
        'label': 'National rank last year',
    },
    'national_rank_before_last': {
        'type': 'integer',
        'label': 'National rank year before last year',
    },
    'candidates': {
        'type': 'integer',
        'label': 'Candidates number',
    },
    'candidates_before_last': {
        'type': 'integer',
        'label': 'Candidates last year',
    },
    'candidates_last': {
        'type': 'integer',
        'label': 'Candidatesyear before last year',
    },
    'number_pass': {
        'type': 'integer',
        'label': 'Passed candidates',
    },
    'number_pass_last': {
        'type': 'integer',
        'label': 'Passed candidates last year',
    },
    'number_pass_before_last': {
        'type': 'integer',
        'label': 'Passed candidates year before last year',
    },
    'percentage_pass': {
        'type': 'float',
        'label': 'Percentage pass',
    },
    'percentage_pass_last': {
        'type': 'float',
        'label': 'Percentage pass last year',
    },
    'percentage_pass_before_last': {
        'type': 'float',
        'label': 'Percentage pass before last year',
    },
    'percentage_pass_change': {
        'type': 'float',
        'label': 'Change in percentage pass',
    },
    'percentage_pass_change_last': {
        'type': 'float',
        'label': 'Change in percentage pass last year',
    },
    'percentage_pass_target': {
        'type': 'float',
        'label': 'Percentage pass target',
    },
    'percentage_pass_target_last': {
        'type': 'float',
        'label': 'Last year percentage pass target',
    },
    'percentage_pass_target_before_last': {
        'type': 'float',
        'label': 'Percentage pass target before last year',
    },
    'percentage_pass_target_next': {
        'type': 'float',
        'label': 'Next year percentage pass target',
    },
    'school_type': {
        'type': 'string',
        'label': 'School type',
    },
    'ownership': {
        'type': 'string',
        'label': 'Ownership',
    },
    'number_enrolled': {
        'type': 'integer',
        'label': 'Number of enrolled pupils',
    },
    'number_teaching_staff': {
        'type': 'integer',
        'label': 'Number of teaching staff',
    },
    'number_non_teaching_staff_by_school': {
        'type': 'integer',
        'label': 'Number of non teaching staff employed by school',
    },
    'number_non_teaching_staff_by_govt': {
        'type': 'integer',
        'label': 'Number of non teaching staff employed by govt',
    },
    'recording_date': {
        'type': 'datetime',
        'label': 'Date recorded',
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
