from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.models.product import Product
from app.models.temper_glass import TemperBoxItem
from app import db

search_bp = Blueprint('search', __name__)


@search_bp.route('/', methods=['GET'])
@jwt_required()
def global_search():
    query = request.args.get('q', '').strip()

    if not query or len(query) < 1:
        return jsonify({'error': 'Search query required'}), 400

    # Search products
    products = Product.query.filter(
        Product.is_active == True,
        db.or_(
            Product.brand.ilike(f'%{query}%'),
            Product.product_name.ilike(f'%{query}%'),
            Product.mobile_model.ilike(f'%{query}%'),
            Product.watts.ilike(f'%{query}%'),
            Product.cable_type.ilike(f'%{query}%'),
            Product.notes.ilike(f'%{query}%')
        )
    ).all()

    # Search temper glass items
    temper_items = TemperBoxItem.query.filter(
        TemperBoxItem.mobile_model.ilike(f'%{query}%')
    ).all()

    return jsonify({
        'query': query,
        'products': [p.to_dict() for p in products],
        'temper_glass_items': [i.to_dict() for i in temper_items],
        'total': len(products) + len(temper_items)
    }), 200