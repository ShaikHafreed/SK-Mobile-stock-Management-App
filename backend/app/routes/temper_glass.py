from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app import db
from app.models.temper_glass import TemperBox, TemperBoxItem
from app.utils.auth_helpers import (
    admin_required, staff_or_admin_required,
    log_activity, get_current_user
)

temper_bp = Blueprint('temper', __name__)


# ─── GET ALL BOXES ────────────────────────────────────────────────────────────
@temper_bp.route('/', methods=['GET'])
@jwt_required()
def get_boxes():
    boxes = TemperBox.query.filter_by(is_active=True).all()
    return jsonify({
        'boxes': [b.to_dict() for b in boxes],
        'total_boxes': len(boxes)
    }), 200


# ─── GET SINGLE BOX ───────────────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>', methods=['GET'])
@jwt_required()
def get_box(box_id):
    box = TemperBox.query.get_or_404(box_id)
    return jsonify({'box': box.to_dict()}), 200


# ─── CREATE BOX ───────────────────────────────────────────────────────────────
@temper_bp.route('/', methods=['POST'])
@staff_or_admin_required
def create_box():
    current_user = get_current_user()
    data = request.get_json()

    if not data.get('box_name'):
        return jsonify({'error': 'box_name is required'}), 400

    box = TemperBox(
        box_name=data['box_name'],
        description=data.get('description', '')
    )
    db.session.add(box)
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} created temper glass box: {box.box_name}",
        module='temper_glass',
        record_id=box.id
    )

    return jsonify({
        'message': 'Box created successfully',
        'box': box.to_dict()
    }), 201


# ─── UPDATE BOX ───────────────────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>', methods=['PUT'])
@staff_or_admin_required
def update_box(box_id):
    current_user = get_current_user()
    box = TemperBox.query.get_or_404(box_id)
    data = request.get_json()

    if 'box_name' in data:
        box.box_name = data['box_name']
    if 'description' in data:
        box.description = data['description']

    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} updated box: {box.box_name}",
        module='temper_glass',
        record_id=box.id
    )

    return jsonify({
        'message': 'Box updated successfully',
        'box': box.to_dict()
    }), 200


# ─── DELETE BOX (Admin only) ──────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>', methods=['DELETE'])
@admin_required
def delete_box(box_id):
    current_user = get_current_user()
    box = TemperBox.query.get_or_404(box_id)

    box.is_active = False
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} deleted box: {box.box_name}",
        module='temper_glass'
    )

    return jsonify({'message': 'Box deleted successfully'}), 200


# ─── ADD ITEM TO BOX ──────────────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>/items', methods=['POST'])
@staff_or_admin_required
def add_item(box_id):
    current_user = get_current_user()
    box = TemperBox.query.get_or_404(box_id)
    data = request.get_json()

    if not data.get('mobile_model'):
        return jsonify({'error': 'mobile_model is required'}), 400

    # Check if model already exists in this box
    existing = TemperBoxItem.query.filter_by(
        box_id=box_id,
        mobile_model=data['mobile_model']
    ).first()

    if existing:
        return jsonify({
            'error': f"{data['mobile_model']} already exists in {box.box_name}. Update quantity instead."
        }), 409

    item = TemperBoxItem(
        box_id=box_id,
        mobile_model=data['mobile_model'],
        quantity=data.get('quantity', 0),
        notes=data.get('notes', '')
    )
    db.session.add(item)
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} added {item.mobile_model} (qty: {item.quantity}) to {box.box_name}",
        module='temper_glass',
        record_id=item.id
    )

    return jsonify({
        'message': 'Item added to box successfully',
        'item': item.to_dict()
    }), 201


# ─── GET ALL ITEMS IN BOX ─────────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>/items', methods=['GET'])
@jwt_required()
def get_items(box_id):
    box = TemperBox.query.get_or_404(box_id)
    return jsonify({
        'box': box.box_name,
        'items': [i.to_dict() for i in box.items],
        'total_items': len(box.items)
    }), 200


# ─── UPDATE ITEM ──────────────────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>/items/<int:item_id>', methods=['PUT'])
@staff_or_admin_required
def update_item(box_id, item_id):
    current_user = get_current_user()
    item = TemperBoxItem.query.filter_by(
        id=item_id, box_id=box_id
    ).first_or_404()
    data = request.get_json()

    if 'mobile_model' in data:
        item.mobile_model = data['mobile_model']
    if 'quantity' in data:
        item.quantity = data['quantity']
    if 'notes' in data:
        item.notes = data['notes']

    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} updated {item.mobile_model} in {item.box.box_name}",
        module='temper_glass',
        record_id=item.id
    )

    return jsonify({
        'message': 'Item updated successfully',
        'item': item.to_dict()
    }), 200


# ─── UPDATE ITEM QUANTITY ONLY ────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>/items/<int:item_id>/quantity', methods=['PATCH'])
@staff_or_admin_required
def update_item_quantity(box_id, item_id):
    current_user = get_current_user()
    item = TemperBoxItem.query.filter_by(
        id=item_id, box_id=box_id
    ).first_or_404()
    data = request.get_json()

    if 'quantity' not in data:
        return jsonify({'error': 'quantity is required'}), 400

    old_qty = item.quantity
    item.quantity = data['quantity']
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} updated {item.mobile_model} quantity from {old_qty} to {item.quantity} in {item.box.box_name}",
        module='temper_glass',
        record_id=item.id
    )

    return jsonify({
        'message': 'Quantity updated',
        'item': item.to_dict()
    }), 200


# ─── MOVE ITEM TO ANOTHER BOX ─────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>/items/<int:item_id>/move', methods=['POST'])
@staff_or_admin_required
def move_item(box_id, item_id):
    current_user = get_current_user()
    item = TemperBoxItem.query.filter_by(
        id=item_id, box_id=box_id
    ).first_or_404()
    data = request.get_json()

    if not data.get('target_box_id'):
        return jsonify({'error': 'target_box_id is required'}), 400

    target_box = TemperBox.query.get_or_404(data['target_box_id'])
    old_box_name = item.box.box_name
    item.box_id = target_box.id
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} moved {item.mobile_model} from {old_box_name} to {target_box.box_name}",
        module='temper_glass',
        record_id=item.id
    )

    return jsonify({
        'message': f'Item moved to {target_box.box_name}',
        'item': item.to_dict()
    }), 200


# ─── DELETE ITEM (Admin only) ─────────────────────────────────────────────────
@temper_bp.route('/<int:box_id>/items/<int:item_id>', methods=['DELETE'])
@admin_required
def delete_item(box_id, item_id):
    current_user = get_current_user()
    item = TemperBoxItem.query.filter_by(
        id=item_id, box_id=box_id
    ).first_or_404()

    model_name = item.mobile_model
    box_name = item.box.box_name
    db.session.delete(item)
    db.session.commit()

    log_activity(
        current_user.id,
        f"{current_user.username} deleted {model_name} from {box_name}",
        module='temper_glass'
    )

    return jsonify({'message': 'Item deleted successfully'}), 200


# ─── SEARCH ITEMS ACROSS ALL BOXES ───────────────────────────────────────────
@temper_bp.route('/search', methods=['GET'])
@jwt_required()
def search_items():
    query = request.args.get('q', '')
    if not query:
        return jsonify({'error': 'Search query required'}), 400

    items = TemperBoxItem.query.filter(
        TemperBoxItem.mobile_model.ilike(f'%{query}%')
    ).all()

    return jsonify({
        'results': [i.to_dict() for i in items],
        'total': len(items)
    }), 200