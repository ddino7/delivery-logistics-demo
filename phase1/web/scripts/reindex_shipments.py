#!/usr/bin/env python3
"""
Safe CLI reindex script for shipments -> OpenSearch.

Usage:
  python3 reindex_shipments.py --yes --limit 1000

Runs inside the Flask app context and uses configured MongoDB and OpenSearch services.
"""
import argparse
import sys
from time import sleep

try:
    # import app object
    from app import app
except Exception as e:
    print("Error importing Flask app. Run this from phase1/web as working dir or adjust PYTHONPATH.")
    raise


def main():
    parser = argparse.ArgumentParser(description='Reindex shipments into OpenSearch')
    parser.add_argument('--limit', '-n', type=int, default=0, help='Max number of docs to reindex (0 = all)')
    parser.add_argument('--batch', '-b', type=int, default=100, help='Batch size')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be indexed, do not send')
    parser.add_argument('--yes', action='store_true', help='Skip confirmation')
    args = parser.parse_args()

    with app.app_context():
        if not hasattr(app, 'opensearch'):
            print('OpenSearch service not configured on app. Set OPENSEARCH_URL environment variable.')
            sys.exit(2)

        if not app.opensearch.is_available():
            print('OpenSearch appears unavailable. Please start the opensearch container and try again.')
            sys.exit(3)

        col = app.db_service.get_collection('shipments')
        cursor = col.find({}, {'_id': 0})
        total = cursor.count() if hasattr(cursor, 'count') else col.count_documents({})

        to_process = total if args.limit <= 0 else min(total, args.limit)

        print(f"Found {total} shipment documents. Reindexing {to_process} documents (dry-run={args.dry_run}).")
        if not args.yes and not args.dry_run:
            resp = input('Continue? [y/N]: ').strip().lower()
            if resp != 'y':
                print('Aborted.')
                sys.exit(0)

        processed = 0
        errors = []
        batch = []
        for doc in cursor:
            if args.limit and processed >= args.limit:
                break
            batch.append(doc)
            if len(batch) >= args.batch:
                for d in batch:
                    try:
                        if args.dry_run:
                            print('DRY:', d.get('tracking_number') or d.get('id'))
                        else:
                            app.opensearch.index_shipment(d)
                    except Exception as e:
                        errors.append({'id': d.get('tracking_number') or d.get('id'), 'error': str(e)})
                processed += len(batch)
                print(f"Processed {processed}/{to_process}")
                batch = []
                sleep(0.1)

        # final small batch
        for d in batch:
            try:
                if args.dry_run:
                    print('DRY:', d.get('tracking_number') or d.get('id'))
                else:
                    app.opensearch.index_shipment(d)
            except Exception as e:
                errors.append({'id': d.get('tracking_number') or d.get('id'), 'error': str(e)})
        processed += len(batch)

        print('Reindex complete. Processed:', processed)
        if errors:
            print('Errors:', len(errors))
            for e in errors[:10]:
                print(e)


if __name__ == '__main__':
    main()
