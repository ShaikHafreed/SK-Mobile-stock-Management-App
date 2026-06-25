from app import db
from datetime import datetime

class Product(db.Model):
    __tablename__ = 'products'

    id = db.Column(db.Integer, primary_key=True)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=False)

    # Common fields
    brand = db.Column(db.String(100), nullable=True)
    product_name = db.Column(db.String(200), nullable=True)  # model name
    image_url = db.Column(db.String(500), nullable=True)     # Cloudinary URL
    quantity = db.Column(db.Integer, default=0, nullable=False)
    notes = db.Column(db.Text, nullable=True)

    # Mobile Covers specific
    mobile_model = db.Column(db.String(100), nullable=True)

    # Chargers specific
    watts = db.Column(db.String(20), nullable=True)  # 18W, 20W, 33W etc

    # Cables specific
    cable_type = db.Column(db.String(50), nullable=True)  # Type-C, Lightning, Micro USB

    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    @property
    def is_low_stock(self):
        return self.quantity < 3

    def to_dict(self):
        return {
            'id': self.id,
            'category_id': self.category_id,
            'category_name': self.category.name if self.category else None,
            'brand': self.brand,
            'product_name': self.product_name,
            'mobile_model': self.mobile_model,
            'watts': self.watts,
            'cable_type': self.cable_type,
            'image_url': self.image_url,
            'quantity': self.quantity,
            'notes': self.notes,
            'is_low_stock': self.is_low_stock,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }