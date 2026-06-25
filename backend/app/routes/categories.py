from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app import db
from app.models.category import Category
from app.utils.auth_helpers import admin_required, log_activity, get_current_user

categories_bp = Blueprint('categories', __name__)


# ─── GET ALL CATEGORIES ───────────────────────────────────────────────────────
@categories_bp.route('/', methods=['GET'])
@jwt_required()
def get_categories():
    categories = Category.query.filter_by(is_active=True).all()
    return jsonify({
        'categories': [c.to_dict() for c in categories]
    }), 200


# ─── ADD CUSTOM CATEGORY ──────────────────────────────────────────────────────
@categories_bp.route('/', methods=['POST'])
@admin_required
def add_category():
    current_user = get_current_user()
    data = request.get_json()

    if not data.get('name'):
        return jsonify({'error': 'Category name is required'}), 400

    slug = data['name'].lower().replace(' ', '-')

    if Category.query.filter_by(slug=slug).first():
        return jsonify({'error': 'Category already exists'}), 409

    category = Category(
        name=data['name'],
        slug=slug,
        icon=data.get('icon', 'category'),
        image_url=data.get('image_url', ''),
        is_default=False
    )

    db.session.add(category)
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} created category {category.name}",
        module='categories',
        record_id=category.id
    )

    return jsonify({
        'message': 'Category created successfully',
        'category': category.to_dict()
    }), 201


# ─── UPDATE CATEGORY ──────────────────────────────────────────────────────────
@categories_bp.route('/<int:category_id>', methods=['PUT'])
@admin_required
def update_category(category_id):
    current_user = get_current_user()
    category = Category.query.get_or_404(category_id)
    data = request.get_json()

    if 'name' in data:
        category.name = data['name']
    if 'icon' in data:
        category.icon = data['icon']
    if 'image_url' in data:
        category.image_url = data['image_url']

    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} updated category {category.name}",
        module='categories',
        record_id=category.id
    )

    return jsonify({
        'message': 'Category updated',
        'category': category.to_dict()
    }), 200


# ─── DELETE CATEGORY (Admin only, non-default) ────────────────────────────────
@categories_bp.route('/<int:category_id>', methods=['DELETE'])
@admin_required
def delete_category(category_id):
    current_user = get_current_user()
    category = Category.query.get_or_404(category_id)

    if category.is_default:
        return jsonify({'error': 'Cannot delete default categories'}), 400

    category.is_active = False
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} deleted category {category.name}",
        module='categories'
    )

    return jsonify({'message': 'Category deleted successfully'}), 200