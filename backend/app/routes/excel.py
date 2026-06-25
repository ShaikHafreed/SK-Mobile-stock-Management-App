from flask import Blueprint, request, jsonify, send_file
from flask_jwt_extended import jwt_required
from app.models.category import Category
from app.utils.auth_helpers import staff_or_admin_required, log_activity, get_current_user
from app.utils.excel_generator import (
    generate_mobile_covers_excel,
    generate_earphones_excel,
    generate_chargers_excel,
    generate_cables_excel,
    generate_temper_glass_excel,
    generate_others_excel,
    generate_full_inventory_excel
)
import pandas as pd
import io
from app import db
from app.models.product import Product

excel_bp = Blueprint('excel', __name__)

CATEGORY_SLUGS = {
    'mobile-covers': generate_mobile_covers_excel,
    'earphones': generate_earphones_excel,
    'earbuds': generate_others_excel,
    'chargers': generate_chargers_excel,
    'charger-cables': generate_cables_excel,
    'others': generate_others_excel,
}


# ─── EXPORT SINGLE CATEGORY ───────────────────────────────────────────────────
@excel_bp.route('/export/<slug>', methods=['GET'])
@staff_or_admin_required
def export_category(slug):
    current_user = get_current_user()

    if slug == 'temper-glass':
        buffer = generate_temper_glass_excel()
        filename = 'Temper_Glass.xlsx'
    elif slug == 'full-inventory':
        buffer = generate_full_inventory_excel()
        filename = 'SK_Mobiles_Full_Inventory.xlsx'
    else:
        category = Category.query.filter_by(slug=slug, is_active=True).first()
        if not category:
            return jsonify({'error': 'Category not found'}), 404

        generator = CATEGORY_SLUGS.get(slug, generate_others_excel)
        buffer = generator(category.id)
        filename = f"{category.name.replace(' ', '_')}.xlsx"

    log_activity(
        current_user.id,
        f"{current_user.username} exported Excel: {filename}",
        module='excel'
    )

    return send_file(
        buffer,
        as_attachment=True,
        download_name=filename,
        mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )


# ─── EXPORT ALL CATEGORIES ────────────────────────────────────────────────────
@excel_bp.route('/export-all', methods=['GET'])
@staff_or_admin_required
def export_all():
    current_user = get_current_user()
    buffer = generate_full_inventory_excel()

    log_activity(
        current_user.id,
        f"{current_user.username} exported full inventory Excel",
        module='excel'
    )

    return send_file(
        buffer,
        as_attachment=True,
        download_name='SK_Mobiles_Full_Inventory.xlsx',
        mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )


# ─── IMPORT EXCEL ─────────────────────────────────────────────────────────────
@excel_bp.route('/import/<int:category_id>', methods=['POST'])
@staff_or_admin_required
def import_excel(category_id):
    current_user = get_current_user()

    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']
    if not file.filename.endswith(('.xlsx', '.csv')):
        return jsonify({'error': 'Only .xlsx and .csv files allowed'}), 400

    category = Category.query.get_or_404(category_id)

    try:
        if file.filename.endswith('.csv'):
            df = pd.read_csv(io.BytesIO(file.read()))
        else:
            df = pd.read_excel(io.BytesIO(file.read()))

        imported = 0
        skipped = 0

        for _, row in df.iterrows():
            brand = str(row.get('Brand', '')).strip()
            quantity = int(row.get('Quantity', 0))

            if not brand or brand == 'nan':
                skipped += 1
                continue

            product = Product(
                category_id=category_id,
                brand=brand,
                product_name=str(row.get('Product Name', row.get('Model', ''))).strip(),
                mobile_model=str(row.get('Mobile Model', '')).strip(),
                watts=str(row.get('Watts', '')).strip(),
                cable_type=str(row.get('Cable Type', '')).strip(),
                quantity=quantity,
                notes=str(row.get('Notes', '')).strip()
            )
            db.session.add(product)
            imported += 1

        db.session.commit()

        log_activity(
            current_user.id,
            f"{current_user.username} imported {imported} products to {category.name}",
            module='excel'
        )

        return jsonify({
            'message': f'Import successful',
            'imported': imported,
            'skipped': skipped
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Import failed: {str(e)}'}), 500