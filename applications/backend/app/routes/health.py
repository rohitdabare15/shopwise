from flask import Blueprint, jsonify
from app import db
from sqlalchemy import text

health_bp = Blueprint("health", __name__)

@health_bp.route("/health")
def health():
    """
    ALB and Kubernetes liveness probe target.
    Returns 200 only when the app AND database are reachable.
    If this returns non-200, EKS restarts the pod automatically.
    """
    try:
        db.session.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    status = "healthy" if db_status == "healthy" else "degraded"
    code   = 200 if status == "healthy" else 503

    return jsonify({
        "status":   status,
        "database": db_status,
        "version":  "1.0.0",
    }), code

@health_bp.route("/ready")
def ready():
    """Kubernetes readiness probe — is this pod ready to receive traffic?"""
    return jsonify({"status": "ready"}), 200
