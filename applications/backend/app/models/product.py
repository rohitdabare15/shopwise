from app import db
from datetime import datetime

class Product(db.Model):
    __tablename__ = "products"

    id          = db.Column(db.Integer, primary_key=True)
    name        = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    price       = db.Column(db.Numeric(10, 2), nullable=False)
    stock       = db.Column(db.Integer, default=0)
    category    = db.Column(db.String(100))
    image_url   = db.Column(db.String(500))
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at  = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id":          self.id,
            "name":        self.name,
            "description": self.description,
            "price":       float(self.price),
            "stock":       self.stock,
            "category":    self.category,
            "image_url":   self.image_url,
            "created_at":  self.created_at.isoformat(),
        }
