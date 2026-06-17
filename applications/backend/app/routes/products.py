from flask import Blueprint, jsonify, request
from app import db
from app.models.product import Product

products_bp = Blueprint("products", __name__)

@products_bp.route("/")
def list_products():
    category = request.args.get("category")
    query    = Product.query
    if category:
        query = query.filter_by(category=category)
    products = query.all()
    return jsonify([p.to_dict() for p in products])

@products_bp.route("/<int:product_id>")
def get_product(product_id):
    product = Product.query.get_or_404(product_id)
    return jsonify(product.to_dict())

@products_bp.route("/seed", methods=["POST"])
def seed_products():
    """Seed demo data — only available in dev/staging"""
    import os
    if os.getenv("ENVIRONMENT", "dev") == "prod":
        return jsonify({"error": "Not available in production"}), 403

    sample = [
        Product(name="Wireless Headphones", price=79.99,  stock=50,  category="electronics", description="Premium sound quality"),
        Product(name="Running Shoes",       price=129.99, stock=30,  category="footwear",    description="Lightweight and durable"),
        Product(name="Coffee Maker",        price=49.99,  stock=100, category="kitchen",     description="Brew perfect coffee"),
        Product(name="Yoga Mat",            price=34.99,  stock=75,  category="fitness",     description="Non-slip surface"),
        Product(name="Desk Lamp",           price=24.99,  stock=200, category="home",        description="LED with adjustable brightness"),
    ]
    db.session.add_all(sample)
    db.session.commit()
    return jsonify({"seeded": len(sample)}), 201
