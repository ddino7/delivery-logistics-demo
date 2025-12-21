#!/usr/bin/env python3
"""
Quick integration checker for local dev stack.

Runs:
 - Calls web `/health` endpoint
 - Calls OpenSearch `_cat/indices` to check for `shipments` and `logs-delivery`
 - Optionally triggers the CLI reindex script (not HTTP)

Usage:
  python3 integration_check.py --web http://localhost:5000 --opensearch http://localhost:9200
"""
import argparse
import requests
import subprocess
import sys


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--web', default='http://localhost:5000')
    p.add_argument('--opensearch', default='http://localhost:9200')
    p.add_argument('--run-reindex', action='store_true', help='Run local CLI reindex (calls phase1/web/scripts/reindex_shipments.py)')
    args = p.parse_args()

    try:
        h = requests.get(args.web + '/health', timeout=5).json()
        print('WEB /health:', h)
    except Exception as e:
        print('WEB /health error:', e)

    try:
        r = requests.get(args.opensearch + '/_cat/indices?format=json', timeout=5)
        indices = r.json()
        names = [i.get('index') for i in indices]
        print('OpenSearch indices:', names)
        print('shipments present:', 'shipments' in names)
        print('logs-delivery present:', 'logs-delivery' in names)
    except Exception as e:
        print('OpenSearch check error:', e)

    if args.run_reindex:
        print('Running CLI reindex...')
        try:
            subprocess.check_call(['python3', 'phase1/web/scripts/reindex_shipments.py', '--yes'])
        except subprocess.CalledProcessError as e:
            print('Reindex failed:', e)


if __name__ == '__main__':
    main()
