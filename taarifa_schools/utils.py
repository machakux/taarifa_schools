import io
import csv

def csv_dictwritter(data, fields=None):
    """Return a csv string from a list of dictionaries"""
    if not fields:
        fields = data[0].keys()
    if isinstance(fields, dict):
        header_row = fields
        fields = fields.keys()
    else:
        header_row = dict([f, f] for f in fields)
    output = io.BytesIO()
    writer = csv.DictWriter(output, fields, extrasaction='ignore')
    writer.writerow(header_row)
    writer.writerows(data)
    return output.getvalue()
    
