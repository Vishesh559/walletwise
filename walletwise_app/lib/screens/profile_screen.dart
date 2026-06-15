import 'package:flutter/material.dart';
import 'package:walletwise_app/services/api_service.dart';
import 'package:walletwise_app/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _summary = {};
  int _transactionCount = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final summary = await ApiService.getSummary();
    final transactions = await ApiService.getTransactions();
    setState(() {
      _summary = summary;
      _transactionCount = transactions.length;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await ApiService.deleteToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_summary['balance'] ?? 0).toDouble();
    final income = (_summary['total_income'] ?? 0).toDouble();
    final expenses = (_summary['total_expenses'] ?? 0).toDouble();
    final savingsRate = income > 0 ? ((income - expenses) / income * 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9B95FF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  const CircleAvatar(radius: 36, backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Color(0xFF6C63FF))),
                  const SizedBox(height: 12),
                  const Text('My Account',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_transactionCount transactions recorded',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _statCard('Balance', '\$${balance.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.purple),
                  _statCard('Income', '\$${income.toStringAsFixed(2)}', Icons.arrow_downward, Colors.green),
                  _statCard('Expenses', '\$${expenses.toStringAsFixed(2)}', Icons.arrow_upward, Colors.red),
                  _statCard('Savings', '${savingsRate.toStringAsFixed(1)}%', Icons.savings, Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Savings Progress',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (savingsRate / 100).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    savingsRate >= 20 ? 'Great job! You are saving well.' : savingsRate >= 10 ? 'Good start. Try to save more!' : 'Try to reduce expenses.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Log Out', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ],
      ),
    );
  }
}
