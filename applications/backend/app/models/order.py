from app import db
from datetime import datetime

class Order(db.Model):
    __tablename__ = "orders"

    id         = db.Column(db.Integer, primary_key=True)
    customer   = db.Column(db.String(200), nullable=False)
    email      = db.Column(db.String(200), nullable=False)
    total      = db.Column(db.Numeric(10, 2), nullable=False)
    status     = db.Column(db.String(50), default="pending")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    items = db.relationship("OrderItem", backref="order", lazy=True)

    def to_dict(self):
        return {
            "id":         self.id,
            "customer":   self.customer,
            "email":      self.email,
            "total":      float(self.total),
            "status":     self.status,
            "created_at": self.created_at.isoformat(),
            "items":      [i.to_dict() for i in self.items],
        }

class OrderItem(db.Model):
    __tablename__ = "order_items"

    id         = db.Column(db.Integer, primary_key=True)
    order_id   = db.Column(db.Integer, db.ForeignKey("orders.id"), nullable=False)
    product_id = db.Column(db.Integer, nullable=False)
    name       = db.Column(db.String(200), nullable=False)
    price      = db.Column(db.Numeric(10, 2), nullable=False)
    quantity   = db.Column(db.Integer, nullable=False)

    def to_dict(self):
        return {
            "product_id": self.product_id,
            "name":       self.name,
            "price":      float(self.price),
            "quantity":   self.quantity,
        }
