from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity
)
from app import db
from app.models.user import User, Role
from app.utils.auth_helpers import log_activity, admin_required, get_current_user

auth_bp = Blueprint('auth', __name__)


# ─── LOGIN ────────────────────────────────────────────────────────────────────
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Username and password required'}), 400

    user = User.query.filter_by(username=data['username']).first()

    if not user or not user.check_password(data['password']):
        return jsonify({'error': 'Invalid username or password'}), 401

    if not user.is_active:
        return jsonify({'error': 'Account is disabled'}), 403

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    log_activity(user.id, f"{user.username} logged in", module='auth')

    return jsonify({
        'message': 'Login successful',
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user.to_dict()
    }), 200


# ─── LOGOUT ───────────────────────────────────────────────────────────────────
@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    user = get_current_user()
    log_activity(user.id, f"{user.username} logged out", module='auth')
    return jsonify({'message': 'Logged out successfully'}), 200


# ─── REFRESH TOKEN ────────────────────────────────────────────────────────────
@auth_bp.route('/refresh-token', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    user_id = get_jwt_identity()
    new_token = create_access_token(identity=str(user_id))
    return jsonify({'access_token': new_token}), 200


# ─── GET CURRENT USER ─────────────────────────────────────────────────────────
@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_me():
    user = get_current_user()
    return jsonify({'user': user.to_dict()}), 200


# ─── CREATE USER (Admin only) ─────────────────────────────────────────────────
@auth_bp.route('/create-user', methods=['POST'])
@admin_required
def create_user():
    data = request.get_json()
    current_user = get_current_user()

    required = ['username', 'password', 'role']
    for field in required:
        if not data.get(field):
            return jsonify({'error': f'{field} is required'}), 400

    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Username already exists'}), 409

    role = Role.query.filter_by(name=data['role']).first()
    if not role:
        return jsonify({'error': 'Invalid role. Use admin or staff'}), 400

    user = User(
        username=data['username'],
        full_name=data.get('full_name', ''),
        role_id=role.id
    )
    user.set_password(data['password'])
    db.session.add(user)
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} created user {user.username} with role {role.name}",
        module='users',
        record_id=user.id
    )

    return jsonify({
        'message': 'User created successfully',
        'user': user.to_dict()
    }), 201


# ─── GET ALL USERS (Admin only) ───────────────────────────────────────────────
@auth_bp.route('/users', methods=['GET'])
@admin_required
def get_users():
    users = User.query.all()
    return jsonify({'users': [u.to_dict() for u in users]}), 200


# ─── UPDATE USER (Admin only) ─────────────────────────────────────────────────
@auth_bp.route('/users/<int:user_id>', methods=['PUT'])
@admin_required
def update_user(user_id):
    current_user = get_current_user()
    user = User.query.get_or_404(user_id)
    data = request.get_json()

    if 'full_name' in data:
        user.full_name = data['full_name']
    if 'password' in data:
        user.set_password(data['password'])
    if 'is_active' in data:
        user.is_active = data['is_active']
    if 'role' in data:
        role = Role.query.filter_by(name=data['role']).first()
        if role:
            user.role_id = role.id

    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} updated user {user.username}",
        module='users',
        record_id=user.id
    )

    return jsonify({
        'message': 'User updated successfully',
        'user': user.to_dict()
    }), 200


# ─── DELETE USER (Admin only) ─────────────────────────────────────────────────
@auth_bp.route('/users/<int:user_id>', methods=['DELETE'])
@admin_required
def delete_user(user_id):
    current_user = get_current_user()
    user = User.query.get_or_404(user_id)

    if user.id == current_user.id:
        return jsonify({'error': 'Cannot delete your own account'}), 400

    username = user.username
    db.session.delete(user)
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} deleted user {username}",
        module='users'
    )

    return jsonify({'message': f'User {username} deleted successfully'}), 200