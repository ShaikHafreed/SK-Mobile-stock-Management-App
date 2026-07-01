from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from app import db
from app.models.category import Category
from app.models.product import Product
from app.utils.auth_helpers import (
    admin_required, get_current_user, log_activity
)

categories_bp = Blueprint('categories', __name__)


@categories_bp.route('/', methods=['GET'])
@jwt_required()
def get_categories():
    categories = Category.query.filter_by(
        is_active=True).all()
    result = []
    for cat in categories:
        cat_dict = cat.to_dict()
        # Add product counts
        products = Product.query.filter_by(
            category_id=cat.id,
            is_active=True).all()
        cat_dict['product_count'] = len(products)
        cat_dict['total_stock'] = sum(
            p.quantity for p in products)
        cat_dict['low_stock_count'] = sum(
            1 for p in products
            if p.quantity < 3)
        result.append(cat_dict)
    return jsonify({
        'categories': result,
        'total': len(result)
    }), 200


@categories_bp.route('/<int:cat_id>',
                     methods=['GET'])
@jwt_required()
def get_category(cat_id):
    cat = Category.query.get_or_404(cat_id)
    return jsonify(
        {'category': cat.to_dict()}), 200


@categories_bp.route('/', methods=['POST'])
@admin_required
def create_category():
    current_user = get_current_user()
    data = request.get_json()
    if not data.get('name'):
        return jsonify(
            {'error': 'Name required'}), 400
    cat = Category(
        name=data['name'],
        description=data.get('description', ''),
    )
    db.session.add(cat)
    db.session.commit()
    log_activity(
        current_user.id,
        f"{current_user.username} created "
        f"category {cat.name}",
        module='categories',
        record_id=cat.id
    )
    return jsonify({
        'message': 'Category created',
        'category': cat.to_dict()
    }), 201


@categories_bp.route('/<int:cat_id>',
                     methods=['PUT'])
@admin_required
def update_category(cat_id):
    current_user = get_current_user()
    cat = Category.query.get_or_404(cat_id)
    data = request.get_json()
    if 'name' in data:
        cat.name = data['name']
    if 'description' in data:
        cat.description = data['description']
    db.session.commit()
    log_activity(
        current_user.id,
        f"{current_user.username} updated "
        f"category {cat.name}",
        module='categories',
        record_id=cat.id
    )
    return jsonify({
        'message': 'Category updated',
        'category': cat.to_dict()
    }), 200


@categories_bp.route('/<int:cat_id>',
                     methods=['DELETE'])
@admin_required
def delete_category(cat_id):
    current_user = get_current_user()
    cat = Category.query.get_or_404(cat_id)
    cat.is_active = False
    db.session.commit()
    log_activity(
        current_user.id,
        f"{current_user.username} deleted "
        f"category {cat.name}",
        module='categories',
        record_id=cat.id
    )
    return jsonify(
        {'message': 'Category deleted'}), 200