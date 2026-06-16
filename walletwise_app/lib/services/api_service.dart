import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';
  static const _storage = FlutterSecureStorage();
  static String? _webToken;

  static Future<String?> getToken() async {
    if (kIsWeb) return _webToken;
    return await _storage.read(key: 'token');
  }

  static Future<void> saveToken(String token) async {
    if (kIsWeb) { _webToken = token; return; }
    await _storage.write(key: 'token', value: token);
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) { _webToken = null; return; }
    await _storage.delete(key: 'token');
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getTransactions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addTransaction(String title,
      double amount, String type, String category, String note) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'note': note
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getSummary() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/summary'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<void> deleteTransaction(int id) async {
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<String> sendChatMessage(
      String systemPrompt, List<Map<String, String>> messages) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'system': systemPrompt,
        'messages': messages,
      }),
    );
    final data = jsonDecode(response.body);
    return data['reply'] as String;
  }

  static Future<List<dynamic>> getBudgets() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/budgets/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> setBudget(
      String category, double limitAmount) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/budgets/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({'category': category, 'limit_amount': limitAmount}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> convertCurrency(
    double amount, String from, String to) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/convert?amount=$amount&from=$from&to=$to'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }
  static Future<Map<String, dynamic>> getRates(String base) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/rates?base=$base'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMonthlyReport() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/monthly-report'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }
}