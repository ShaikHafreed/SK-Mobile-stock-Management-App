from flask import Blueprint, request, jsonify
from app.models.activity_log import ActivityLog
from app.utils.auth_helpers import admin_required

logs_bp = Blueprint('logs', __name__)


@logs_bp.route('/', methods=['GET'])
@admin_required
def get_logs():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)
    module = request.args.get('module')

    query = ActivityLog.query.order_by(ActivityLog.created_at.desc())
    if module:
        query = query.filter_by(module=module)

    logs = query.paginate(page=page, per_page=per_page, error_out=False)

    return jsonify({
        'logs': [l.to_dict() for l in logs.items],
        'total': logs.total,
        'pages': logs.pages,
        'current_page': page
    }), 200