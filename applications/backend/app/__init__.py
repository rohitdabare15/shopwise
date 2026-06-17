from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
import os

db = SQLAlchemy()
migrate = Migrate()

def create_app():
    app = Flask(__name__)

    # CORS — allows the React frontend to call this API
    CORS(app, origins=os.getenv("ALLOWED_ORIGINS", "*"))

    # Database configuration
    app.config["SQLALCHEMY_DATABASE_URI"] = (
        f"postgresql://{os.getenv('DB_USER', 'shopwise_admin')}:"
        f"{os.getenv('DB_PASSWORD')}@"
        f"{os.getenv('DB_HOST')}:"
        f"{os.getenv('DB_PORT', '5432')}/"
        f"{os.getenv('DB_NAME', 'shopwise')}"
    )
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-secret-change-in-prod")

    db.init_app(app)
    migrate.init_app(app, db)

    # Register blueprints (route groups)
    from app.routes.products import products_bp
    from app.routes.orders import orders_bp
    from app.routes.health import health_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(products_bp, url_prefix="/api/products")
    app.register_blueprint(orders_bp, url_prefix="/api/orders")

    return app
