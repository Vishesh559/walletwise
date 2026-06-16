import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  Map<String, dynamic> _result = {};
  Map<String, dynamic> _rates = {};
  bool _loading = false;
  bool _ratesLoading = true;
  String _lastUpdated = '';

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'flag': '🇬🇧'},
    {'code': 'INR', 'name': 'Indian Rupee', 'flag': '🇮🇳'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'flag': '🇨🇦'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'flag': '🇦🇺'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'flag': '🇯🇵'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'flag': '🇨🇭'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'flag': '🇨🇳'},
  ];

  final Map<String, String> _flags = {
    'USD': '🇺🇸', 'EUR': '🇪🇺', 'GBP': '🇬🇧',
    'INR': '🇮🇳', 'CAD': '🇨🇦', 'AUD': '🇦🇺',
    'JPY': '🇯🇵', 'CHF': '🇨🇭', 'CNY': '🇨🇳',
  };

  @override
  void initState() {
    super.initState();
    _convert();
    _loadRates();
  }

  Future<void> _convert() async {
    if (_amountController.text.isEmpty) return;
    setState(() => _loading = true);
    final result = await ApiService.convertCurrency(
      double.parse(_amountController.text),
      _fromCurrency,
      _toCurrency,
    );
    setState(() { _result = result; _loading = false; });
  }

  Future<void> _loadRates() async {
    setState(() => _ratesLoading = true);
    final result = await ApiService.getRates(_fromCurrency);
    setState(() {
      _rates = result['rates'] ?? {};
      _lastUpdated = result['last_updated'] ?? '';
      _ratesLoading = false;
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _convert();
    _loadRates();
  }

  Future<void> _selectCurrency(bool isFrom) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Select Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._currencies.map((c) => ListTile(
            leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(c['code']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(c['name']!),
            onTap: () => Navigator.pop(context, c['code']),
          )),
        ],
      ),
    );
    if (selected != null) {
      setState(() {
        if (isFrom) _fromCurrency = selected;
        else _toCurrency = selected;
      });
      _convert();
      _loadRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Currency Converter', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () { _convert(); _loadRates(); },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main converter card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9B95FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Enter Amount',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                  onChanged: (_) => _convert(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _currencyButton(_fromCurrency, true)),
                    GestureDetector(
                      onTap: _swapCurrencies,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                      ),
                    ),
                    Expanded(child: _currencyButton(_toCurrency, false)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Result
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _result.isEmpty
                    ? const Center(child: Text('Enter an amount to convert'))
                    : Column(
                        children: [
                          Text(
                            '${_flags[_fromCurrency]} ${_result['amount']} $_fromCurrency',
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const Icon(Icons.arrow_downward, color: Colors.grey),
                          Text(
                            '${_flags[_toCurrency]} ${_result['converted']} $_toCurrency',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C63FF)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '1 $_fromCurrency = ${_result['rate']} $_toCurrency',
                              style: const TextStyle(
                                  color: Color(0xFF6C63FF), fontSize: 13),
                            ),
                          ),
                          if (_lastUpdated.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Live rates · Updated today',
                              style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            ),
                          ],
                        ],
                      ),
          ),
          const SizedBox(height: 16),

          // Live rates table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Live Rates vs $_fromCurrency',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('LIVE',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ratesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: _rates.entries
                            .where((e) => e.key != _fromCurrency)
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Text(_flags[e.key] ?? '💱',
                                          style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(e.key,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        e.value is double
                                            ? e.value.toStringAsFixed(4)
                                            : e.value.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6C63FF)),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyButton(String currency, bool isFrom) {
    return GestureDetector(
      onTap: () => _selectCurrency(isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_flags[currency] ?? '💱',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(currency,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}