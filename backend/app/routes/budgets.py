from flask import Blueprint, request, jsonify
from app import db
from app.models import Budget, Transaction
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

budgets_bp = Blueprint("budgets", __name__)

@budgets_bp.route("/", methods=["GET"])
@jwt_required()
def get_budgets():
    user_id = get_jwt_identity()
    now = datetime.utcnow()
    budgets = Budget.query.filter_by(user_id=user_id, month=now.month, year=now.year).all()
    result = []
    for b in budgets:
        spent = sum(t.amount for t in Transaction.query.filter_by(
            user_id=user_id, category=b.category, type="expense").all()
            if t.date.month == now.month and t.date.year == now.year)
        result.append({
            "id": b.id,
            "category": b.category,
            "limit_amount": b.limit_amount,
            "spent": spent,
            "remaining": max(0, b.limit_amount - spent),
            "percentage": min(100, round((spent / b.limit_amount) * 100)) if b.limit_amount > 0 else 0
        })
    return jsonify(result), 200

@budgets_bp.route("/", methods=["POST"])
@jwt_required()
def set_budget():
    user_id = get_jwt_identity()
    data = request.get_json()
    now = datetime.utcnow()
    existing = Budget.query.filter_by(
        user_id=user_id, category=data["category"],
        month=now.month, year=now.year).first()
    if existing:
        existing.limit_amount = data["limit_amount"]
        db.session.commit()
        return jsonify({"message": "Budget updated"}), 200
    budget = Budget(
        user_id=user_id,
        category=data["category"],
        limit_amount=data["limit_amount"],
        month=now.month,
        year=now.year
    )
    db.session.add(budget)
    db.session.commit()
    return jsonify({"message": "Budget set"}), 201

@budgets_bp.route("/<int:budget_id>", methods=["DELETE"])
@jwt_required()
def delete_budget(budget_id):
    user_id = get_jwt_identity()
    budget = Budget.query.filter_by(id=budget_id, user_id=user_id).first()
    if not budget:
        return jsonify({"error": "Budget not found"}), 404
    db.session.delete(budget)
    db.session.commit()
    return jsonify({"message": "Budget deleted"}), 200