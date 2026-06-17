from flask import Blueprint, jsonify, request
from app import db
from app.models.order import Order, OrderItem

orders_bp = Blueprint("orders", __name__)

@orders_bp.route("/", methods=["POST"])
def create_order():
    data  = request.get_json()
    order = Order(
        customer=data["customer"],
        email=data["email"],
        total=sum(i["price"] * i["quantity"] for i in data["items"]),
        status="pending",
    )
    db.session.add(order)
    db.session.flush()  # Get order.id before committing

    for item in data["items"]:
        db.session.add(OrderItem(
            order_id=order.id,
            product_id=item["product_id"],
            name=item["name"],
            price=item["price"],
            quantity=item["quantity"],
        ))

    db.session.commit()
    return jsonify(order.to_dict()), 201

@orders_bp.route("/<int:order_id>")
def get_order(order_id):
    order = Order.query.get_or_404(order_id)
    return jsonify(order.to_dict())
