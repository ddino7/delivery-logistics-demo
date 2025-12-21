from flask import Blueprint, jsonify, request, current_app

search_bp = Blueprint("search_bp", __name__)


@search_bp.route("/", methods=["GET"])
def search():
    q = (request.args.get("q") or "").strip()
    if not q:
        return jsonify({"ok": False, "error": "q is required"}), 400

    if not hasattr(current_app, "opensearch"):
        return jsonify({"ok": False, "error": "OpenSearch not configured"}), 503

    try:
        result = current_app.opensearch.search_shipments(q)
        hits = [h.get("_source", {}) for h in result.get("hits", {}).get("hits", [])]
        return jsonify({"ok": True, "count": len(hits), "data": hits}), 200
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500
