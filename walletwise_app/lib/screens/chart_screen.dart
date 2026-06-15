import 'package:flutter/material.dart';
import 'dart:math';
import 'package:walletwise_app/services/api_service.dart';

class ChartScreen extends StatefulWidget {
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  Map<String, double> _categoryTotals = {};
  bool _loading = true;
  String _filter = 'expense';

  final List<Color> _colors = [
    const Color(0xFF6C63FF), const Color(0xFFFF6584),
    const Color(0xFF43C6AC), const Color(0xFFFFBE0B),
    const Color(0xFFFF6B6B), const Color(0xFF4ECDC4),
  ];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final transactions = await ApiService.getTransactions();
    final Map<String, double> totals = {};
    for (final t in transactions) {
      if (t['type'] == _filter) {
        final cat = t['category'] as String;
        totals[cat] = (totals[cat] ?? 0) + (t['amount'] as num).toDouble();
      }
    }
    setState(() { _categoryTotals = totals; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final total = _categoryTotals.values.fold(0.0, (a, b) => a + b);
    final entries = _categoryTotals.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Charts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () { setState(() => _filter = 'expense'); _loadData(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _filter == 'expense' ? const Color(0xFF6C63FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('Expenses', style: TextStyle(
                        color: _filter == 'expense' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold))),
                    ),
                  )),
                  Expanded(child: GestureDetector(
                    onTap: () { setState(() => _filter = 'income'); _loadData(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _filter == 'income' ? const Color(0xFF6C63FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('Income', style: TextStyle(
                        color: _filter == 'income' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold))),
                    ),
                  )),
                ]),
              ),
              const SizedBox(height: 24),
              if (entries.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No data yet. Add some transactions!',
                      style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)))
              else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    Text(_filter == 'expense' ? 'Expense Breakdown' : 'Income Breakdown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: CustomPaint(
                        painter: PieChartPainter(entries, _colors),
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          Text('\$${total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ])),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('By Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...entries.asMap().entries.map((e) {
                      final color = _colors[e.key % _colors.length];
                      final pct = total > 0 ? (e.value.value / total * 100) : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Container(width: 12, height: 12,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.value.key, style: const TextStyle(fontSize: 14))),
                          Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(width: 8),
                          Text('\$${e.value.value.toStringAsFixed(2)}',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ]),
                      );
                    }),
                  ]),
                ),
              ],
            ]),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final List<Color> colors;
  PieChartPainter(this.entries, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold(0.0, (a, b) => a + b.value);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    double startAngle = -pi / 2;
    for (int i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep - 0.03, false,
        Paint()..color = colors[i % colors.length]..style = PaintingStyle.stroke..strokeWidth = 28,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
