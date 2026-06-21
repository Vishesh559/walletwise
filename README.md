# WalletWise — AI-Powered Personal Finance App

A mobile app for tracking expenses and getting AI-driven insights into spending habits.

## 🎯 Problem

Most budgeting apps show raw numbers but don't help people understand *why* their spending changes or what to do about it. WalletWise combines transaction tracking with an AI assistant that analyzes spending patterns and gives plain-language financial insights.

## 🏗️ Architecture

```
[Flutter Mobile App] --> [Flask REST API] --> [PostgreSQL Database]
                               |
                       [Groq AI Service]
```

- **Frontend:** Flutter app handles UI, local state, and chart rendering
- **Backend:** Flask API exposes REST endpoints for auth, transactions, and AI insights
- **Database:** PostgreSQL stores users, transactions, and categorized spending data
- **AI Layer:** Groq AI processes transaction history to generate spending insights and answer natural-language financial questions

## ✨ Key Features

- Expense tracking with categorization
- JWT-based authentication with refresh-token rotation for persistent secure sessions
- Real-time spending visualizations (charts/graphs of category breakdowns over time)
- AI assistant that analyzes actual transaction data to answer questions like "where did I overspend this month?"

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Python, Flask |
| Database | PostgreSQL |
| AI | Groq AI |
| Auth | JWT with refresh-token rotation |

## 📐 Technical Decisions

- **PostgreSQL over NoSQL:** transaction and category data is inherently relational, and PostgreSQL's ACID guarantees matter for financial data integrity.
- **JWT refresh-token rotation:** access tokens are short-lived, refresh tokens rotate on use, reducing the window for token replay attacks.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Python 3.10+
- PostgreSQL instance

### Installation
```bash
git clone https://github.com/Vishesh559/walletwise
cd walletwise
flutter pub get          # frontend dependencies
pip install -r requirements.txt   # backend dependencies (adjust path as needed)
```

### Running locally
```bash
flutter run               # mobile app
python app.py             # backend server (adjust entry-point filename as needed)
```

## 📸 Demo

*(Add a screenshot or screen recording of the app here — this significantly boosts engagement on GitHub.)*

## 📈 Future Improvements

- Add budget goal-setting with progress tracking
- Support multi-currency transactions
- Add export-to-CSV for transaction history

## 📄 License

MIT
