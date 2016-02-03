#!/usr/bin/env python
import argparse
from bioblend import galaxy
import json
import os

def main():
    """
        This script uses bioblend to import .ga workflow files into a running instance of Galaxy
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('workflow_path', help='The path to the workflow file')
    args = parser.parse_args()
    
    import_uuid = json.load(open(args.workflow_path, 'r'))['uuid']
    gi = galaxy.GalaxyInstance(url='http://127.0.0.1:8080', email='admin@galaxy.org', password='admin')
    existing_uuids = [d['latest_workflow_uuid'] for d in gi.workflows.get_workflows()]
    if import_uuid not in existing_uuids:
        gi.workflows.import_workflow_from_local_path(args.workflow_path)

if __name__ == '__main__':
    main()
