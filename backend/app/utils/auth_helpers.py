from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from app.models.user import User
from app.models.activity_log import ActivityLog
from app import db

def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        verify_jwt_in_request()
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role.name != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        return f(*args, **kwargs)
    return decorated

def staff_or_admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        verify_jwt_in_request()
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        if not user or user.role.name not in ['admin', 'staff']:
            return jsonify({'error': 'Access denied'}), 403
        return f(*args, **kwargs)
    return decorated

def log_activity(user_id, action, module=None, record_id=None):
    try:
        log = ActivityLog(
            user_id=user_id,
            action=action,
            module=module,
            record_id=record_id
        )
        db.session.add(log)
        db.session.commit()
    except Exception as e:
        print(f"Log error: {e}")

def get_current_user():
    user_id = get_jwt_identity()
    return User.query.get(user_id)