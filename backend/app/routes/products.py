import os
import uuid
from flask import Blueprint, request, jsonify, send_file
from flask_jwt_extended import jwt_required
from app import db
from app.models.product import Product
from app.models.category import Category
from app.utils.auth_helpers import (
    admin_required, staff_or_admin_required,
    log_activity, get_current_user
)

products_bp = Blueprint('products', __name__)


@products_bp.route('/', methods=['GET'])
@jwt_required()
def get_products():
    category_id = request.args.get('category_id')
    low_stock = request.args.get('low_stock')
    query = Product.query.filter_by(is_active=True)
    if category_id:
        query = query.filter_by(category_id=category_id)
    if low_stock == 'true':
        query = query.filter(Product.quantity < 3)
    products = query.order_by(Product.created_at.desc()).all()
    return jsonify({
        'products': [p.to_dict() for p in products],
        'total': len(products)
    }), 200


@products_bp.route('/<int:product_id>', methods=['GET'])
@jwt_required()
def get_product(product_id):
    product = Product.query.get_or_404(product_id)
    return jsonify({'product': product.to_dict()}), 200


@products_bp.route('/', methods=['POST'])
@staff_or_admin_required
def add_product():
    current_user = get_current_user()
    data = request.get_json()
    if not data.get('category_id'):
        return jsonify({'error': 'category_id is required'}), 400
    category = Category.query.get(data['category_id'])
    if not category:
        return jsonify({'error': 'Category not found'}), 404
    product = Product(
        category_id=data['category_id'],
        brand=data.get('brand', ''),
        product_name=data.get('product_name', ''),
        mobile_model=data.get('mobile_model', ''),
        watts=data.get('watts', ''),
        cable_type=data.get('cable_type', ''),
        quantity=data.get('quantity', 0),
        notes=data.get('notes', ''),
        image_url=data.get('image_url', '')
    )
    db.session.add(product)
    db.session.commit()
    log_activity(
        current_user.id,
        f"{current_user.username} added {product.brand} {product.product_name} in {category.name}",
        module='products',
        record_id=product.id
    )
    return jsonify({
        'message': 'Product added successfully',
        'product': product.to_dict()
    }), 201


@products_bp.route('/<int:product_id>', methods=['PUT'])
@staff_or_admin_required
def update_product(product_id):
    current_user = get_current_user()
    product = Product.query.get_or_404(product_id)
    data = request.get_json()
    if 'brand' in data:
        product.brand = data['brand']
    if 'product_name' in data:
        product.product_name = data['product_name']
    if 'mobile_model' in data:
        product.mobile_model = data['mobile_model']
    if 'watts' in data:
        product.watts = data['watts']
    if 'cable_type' in data:
        product.cable_type = data['cable_type']
    if 'quantity' in data:
        product.quantity = data['quantity']
    if 'notes' in data:
        product.notes = data['notes']
    if 'image_url' in data:
        product.image_url = data['image_url']
    db.session.commit()
    log_activity(
        current_user.id,
        f"{current_user.username} updated {product.brand} {product.product_name}",
        module='products',
        record_id=product.id
    )
    return jsonify({
        'message': 'Product updated successfully',
        'product': product.to_dict()
    }), 200


@products_bp.route('/<int:product_id>/quantity', methods=['PATCH'])
@staff_or_admin_required
def update_quantity(product_id):
    current_user = get_current_user()
    product = Product.query.get_or_404(product_id)
    data = request.get_json()
    if 'quantity' not in data:
        return jsonify({'error': 'quantity is required'}), 400
    old_qty = product.quantity
    product.quantity = data['quantity']
    db.session.commit()
    log_activity(
        current_user.id,
        f"{current_user.username} updated quantity of {product.brand} from {old_qty} to {product.quantity}",
        module='products',
        record_id=product.id
    )
    return jsonify({
        'message': 'Quantity updated',
        'product': product.to_dict()
    }), 200


@products_bp.route('/<int:product_id>', methods=['DELETE'])
@admin_required
def delete_product(product_id):
    current_user = get_current_user()
    product = Product.query.get_or_404(product_id)
    product.is_active = False
    db.session.commit()
    log_activity(
        current_user.id,
        f"{current_user.username} deleted {product.brand} {product.product_name}",
        module='products',
        record_id=product.id
    )
    return jsonify({'message': 'Product deleted successfully'}), 200


@products_bp.route('/dashboard/stats', methods=['GET'])
@jwt_required()
def dashboard_stats():
    categories = Category.query.filter_by(is_active=True).all()
    total_products = Product.query.filter_by(is_active=True).count()
    total_low_stock = Product.query.filter(
        Product.is_active == True,
        Product.quantity < 3
    ).count()
    total_stock = db.session.query(
        db.func.sum(Product.quantity)
    ).filter_by(is_active=True).scalar() or 0
    return jsonify({
        'total_products': total_products,
        'total_stock': total_stock,
        'total_low_stock': total_low_stock,
        'categories': [c.to_dict() for c in categories]
    }), 200


# ─── UPLOAD IMAGE TO SUPABASE ─────────────────────────────────
@products_bp.route('/<int:product_id>/upload-image', methods=['POST'])
@staff_or_admin_required
def upload_product_image(product_id):
    current_user = get_current_user()
    product = Product.query.get_or_404(product_id)

    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    allowed = {'png', 'jpg', 'jpeg', 'webp'}
    ext = file.filename.rsplit('.', 1)[-1].lower()
    if ext not in allowed:
        return jsonify({'error': 'Only PNG, JPG, JPEG, WEBP allowed'}), 400

    try:
        from supabase import create_client
        import os

        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_SECRET_KEY')
        supabase = create_client(supabase_url, supabase_key)

        # Generate unique filename
        filename = f"products/product_{product_id}_{uuid.uuid4().hex[:8]}.{ext}"

        # Read file bytes
        file_bytes = file.read()

        # Upload to Supabase Storage
        result = supabase.storage.from_('sk-mobiles-images').upload(
            path=filename,
            file=file_bytes,
            file_options={
                "content-type": f"image/{ext}",
                "upsert": "true"
            }
        )

        # Get public URL
        public_url = supabase.storage.from_('sk-mobiles-images').get_public_url(filename)

        # Update product
        product.image_url = public_url
        db.session.commit()

        log_activity(
            current_user.id,
            f"{current_user.username} uploaded image for {product.brand} {product.product_name}",
            module='products',
            record_id=product.id
        )

        return jsonify({
            'message': 'Image uploaded successfully',
            'image_url': public_url
        }), 200

    except Exception as e:
        return jsonify({'error': f'Upload failed: {str(e)}'}), 500