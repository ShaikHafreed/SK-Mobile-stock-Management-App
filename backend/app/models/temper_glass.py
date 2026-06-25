from app import db
from datetime import datetime

class TemperBox(db.Model):
    __tablename__ = 'temper_boxes'

    id = db.Column(db.Integer, primary_key=True)
    box_name = db.Column(db.String(100), nullable=False)   # Box 1, Box 2 etc
    description = db.Column(db.Text, nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    items = db.relationship('TemperBoxItem', backref='box', lazy=True,
                            cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'box_name': self.box_name,
            'description': self.description,
            'total_items': len(self.items),
            'total_stock': sum(i.quantity for i in self.items),
            'low_stock_count': sum(1 for i in self.items if i.quantity < 3),
            'items': [item.to_dict() for item in self.items],
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class TemperBoxItem(db.Model):
    __tablename__ = 'temper_box_items'

    id = db.Column(db.Integer, primary_key=True)
    box_id = db.Column(db.Integer, db.ForeignKey('temper_boxes.id'), nullable=False)
    mobile_model = db.Column(db.String(100), nullable=False)  # Samsung A15 etc
    quantity = db.Column(db.Integer, default=0, nullable=False)
    notes = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    @property
    def is_low_stock(self):
        return self.quantity < 3

    def to_dict(self):
        return {
            'id': self.id,
            'box_id': self.box_id,
            'box_name': self.box.box_name if self.box else None,
            'mobile_model': self.mobile_model,
            'quantity': self.quantity,
            'notes': self.notes,
            'is_low_stock': self.is_low_stock,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }