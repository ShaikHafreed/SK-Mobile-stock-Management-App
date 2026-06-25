from app import db
from datetime import datetime

class Category(db.Model):
    __tablename__ = 'categories'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    slug = db.Column(db.String(100), unique=True, nullable=False)
    icon = db.Column(db.String(100), nullable=True)       # icon name for custom categories
    image_url = db.Column(db.String(500), nullable=True)  # Cloudinary URL
    is_default = db.Column(db.Boolean, default=False)     # True for the 7 built-in categories
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    products = db.relationship('Product', backref='category', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'slug': self.slug,
            'icon': self.icon,
            'image_url': self.image_url,
            'is_default': self.is_default,
            'total_products': len(self.products),
            'total_stock': sum(p.quantity for p in self.products),
            'low_stock_count': sum(1 for p in self.products if p.quantity < 3)
        }