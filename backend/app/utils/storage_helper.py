import os
import uuid
from supabase import create_client
from flask import current_app


def get_supabase():
    url = current_app.config['SUPABASE_URL']
    key = current_app.config['SUPABASE_SECRET_KEY']
    return create_client(url, key)


def upload_image(file_bytes, filename, folder='products'):
    """Upload image to Supabase Storage"""
    try:
        supabase = get_supabase()
        bucket = current_app.config['SUPABASE_BUCKET']

        # Generate unique filename
        ext = filename.rsplit('.', 1)[-1].lower()
        unique_name = f"{folder}/{uuid.uuid4().hex}.{ext}"

        # Upload to Supabase Storage
        supabase.storage.from_(bucket).upload(
            path=unique_name,
            file=file_bytes,
            file_options={"content-type": f"image/{ext}"}
        )

        # Get public URL
        public_url = supabase.storage.from_(bucket).get_public_url(unique_name)

        return {
            'success': True,
            'url': public_url,
            'path': unique_name
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


def delete_image(path):
    """Delete image from Supabase Storage"""
    try:
        supabase = get_supabase()
        bucket = current_app.config['SUPABASE_BUCKET']
        supabase.storage.from_(bucket).remove([path])
        return {'success': True}
    except Exception as e:
        return {'success': False, 'error': str(e)}


def upload_product_image(file, filename):
    file_bytes = file.read()
    return upload_image(file_bytes, filename, folder='products')


def upload_category_image(file, filename):
    file_bytes = file.read()
    return upload_image(file_bytes, filename, folder='categories')


def upload_profile_image(file, filename):
    file_bytes = file.read()
    return upload_image(file_bytes, filename, folder='profiles')