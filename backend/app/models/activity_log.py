from app import db
from datetime import datetime

class ActivityLog(db.Model):
    __tablename__ = 'activity_logs'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    action = db.Column(db.String(500), nullable=False)  # "Admin added Samsung S24 Cover"
    module = db.Column(db.String(50), nullable=True)    # products, temper_glass, users etc
    record_id = db.Column(db.Integer, nullable=True)    # ID of the affected record
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user': self.user.username if self.user else 'System',
            'action': self.action,
            'module': self.module,
            'record_id': self.record_id,
            'date': self.created_at.strftime('%d-%m-%Y') if self.created_at else None,
            'time': self.created_at.strftime('%I:%M %p') if self.created_at else None
        }