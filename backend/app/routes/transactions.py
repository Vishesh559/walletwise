from flask import Blueprint, request, jsonify
from app import db
from app.models import Transaction
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
        print("GROQ RESPONSE:", result)

        if "choices" in result:
            reply = result["choices"][0]["message"]["content"]
            return jsonify({"reply": reply}), 200
        else:
            error_msg = result.get("error", {}).get("message", str(result))
            print("GROQ ERROR:", error_msg)
            return jsonify({"error": error_msg}), 500

    except Exception as e:
        print("EXCEPTION:", str(e))
        return jsonify({"error": str(e)}), 500