from flask import Blueprint, request, jsonify
from app import db
from app.models import Budget, Transaction
from flask_jwt_extended import jwt_required, get_jwt_identity
import requests as req
import os
from dotenv import load_dotenv

load_dotenv()

transactions_bp = Blueprint("transactions", __name__)

@transactions_bp.route("/", methods=["GET"])
@jwt_required()
def get_transactions():
    user_id = get_jwt_identity()
    transactions = Transaction.query.filter_by(user_id=user_id).order_by(Transaction.date.desc()).all()
    return jsonify([{
        "id": t.id,
        "title": t.title,
        "amount": t.amount,
        "type": t.type,
        "category": t.category,
        "date": t.date.strftime("%Y-%m-%d %H:%M:%S"),
        "note": t.note
    } for t in transactions]), 200


@transactions_bp.route("/", methods=["POST"])
@jwt_required()
def add_transaction():
    user_id = get_jwt_identity()
    data = request.get_json()

    if not data or not data.get("title") or not data.get("amount") or not data.get("type"):
        return jsonify({"error": "Title, amount and type are required"}), 400

    if data["type"] not in ["income", "expense"]:
        return jsonify({"error": "Type must be income or expense"}), 400

    transaction = Transaction(
        user_id=user_id,
        title=data["title"],
        amount=data["amount"],
        type=data["type"],
        category=data.get("category", "General"),
        note=data.get("note", "")
    )
    db.session.add(transaction)
    db.session.commit()
    return jsonify({"message": "Transaction added", "id": transaction.id}), 201


@transactions_bp.route("/<int:transaction_id>", methods=["DELETE"])
@jwt_required()
def delete_transaction(transaction_id):
    user_id = get_jwt_identity()
    transaction = Transaction.query.filter_by(id=transaction_id, user_id=user_id).first()

    if not transaction:
        return jsonify({"error": "Transaction not found"}), 404

    db.session.delete(transaction)
    db.session.commit()
    return jsonify({"message": "Transaction deleted"}), 200


@transactions_bp.route("/summary", methods=["GET"])
@jwt_required()
def get_summary():
    user_id = get_jwt_identity()
    transactions = Transaction.query.filter_by(user_id=user_id).all()

    income = sum(t.amount for t in transactions if t.type == "income")
    expenses = sum(t.amount for t in transactions if t.type == "expense")

    return jsonify({
        "total_income": income,
        "total_expenses": expenses,
        "balance": income - expenses
    }), 200


@transactions_bp.route("/chat", methods=["POST"])
@jwt_required()
def chat():
    data = request.get_json()
    messages = data.get("messages", [])
    system_prompt = data.get("system", "You are a helpful finance assistant.")

    try:
        response = req.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {os.environ.get('GROQ_API_KEY', '')}",
            },
            json={
                "model": "llama-3.3-70b-versatile",
                "max_tokens": 500,
                "messages": [{"role": "system", "content": system_prompt}] + messages,
            }
        )
        result = response.json()
        if "choices" in result:
            reply = result["choices"][0]["message"]["content"]
            return jsonify({"reply": reply}), 200
        else:
            error_msg = result.get("error", {}).get("message", str(result))
            return jsonify({"error": error_msg}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@transactions_bp.route("/monthly-report", methods=["GET"])
@jwt_required()
def monthly_report():
    user_id = get_jwt_identity()
    from datetime import datetime
    now = datetime.utcnow()
    transactions = Transaction.query.filter_by(user_id=user_id).all()
    this_month = [t for t in transactions if t.date.month == now.month and t.date.year == now.year]
    last_month = [t for t in transactions if t.date.month == (now.month - 1 or 12) and t.date.year == now.year]

    income = sum(t.amount for t in this_month if t.type == "income")
    expenses = sum(t.amount for t in this_month if t.type == "expense")

    by_category = {}
    for t in this_month:
        if t.type == "expense":
            by_category[t.category] = by_category.get(t.category, 0) + t.amount

    last_expenses = sum(t.amount for t in last_month if t.type == "expense")
    trend = round(((expenses - last_expenses) / last_expenses * 100) if last_expenses > 0 else 0, 1)

    return jsonify({
        "month": now.strftime("%B %Y"),
        "total_income": income,
        "total_expenses": expenses,
        "balance": income - expenses,
        "by_category": by_category,
        "vs_last_month": trend,
        "transaction_count": len(this_month),
        "top_category": max(by_category, key=by_category.get) if by_category else "None"
    }), 200


@transactions_bp.route("/convert", methods=["GET"])
@jwt_required()
def convert_currency():
    amount = float(request.args.get("amount", 1))
    from_currency = request.args.get("from", "USD").upper()
    to_currency = request.args.get("to", "USD").upper()
    api_key = os.environ.get("EXCHANGE_RATE_API_KEY", "")

    try:
        response = req.get(
            f"https://v6.exchangerate-api.com/v6/{api_key}/pair/{from_currency}/{to_currency}/{amount}"
        )
        data = response.json()
        if data.get("result") == "success":
            return jsonify({
                "from": from_currency,
                "to": to_currency,
                "amount": amount,
                "converted": round(data["conversion_result"], 2),
                "rate": round(data["conversion_rate"], 4),
                "last_updated": data.get("time_last_update_utc", "")
            }), 200
        else:
            return jsonify({"error": "Conversion failed"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@transactions_bp.route("/rates", methods=["GET"])
@jwt_required()
def get_rates():
    base = request.args.get("base", "USD").upper()
    api_key = os.environ.get("EXCHANGE_RATE_API_KEY", "")

    try:
        response = req.get(
            f"https://v6.exchangerate-api.com/v6/{api_key}/latest/{base}"
        )
        data = response.json()
        if data.get("result") == "success":
            rates = data["conversion_rates"]
            filtered = {k: v for k, v in rates.items()
                       if k in ["USD", "EUR", "GBP", "INR", "CAD", "AUD", "JPY", "CHF", "CNY"]}
            return jsonify({
                "base": base,
                "rates": filtered,
                "last_updated": data.get("time_last_update_utc", "")
            }), 200
        else:
            return jsonify({"error": "Failed to get rates"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500