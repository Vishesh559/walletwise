import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<String> _getFinancialContext() async {
    final summary = await ApiService.getSummary();
    final transactions = await ApiService.getTransactions();
    final recent = transactions.take(10).map((t) =>
        '${t["type"]}: ${t["title"]} - \$${t["amount"]} (${t["category"]})').join('\n');
    return 'Balance: \$${summary["balance"]}, Income: \$${summary["total_income"]}, Expenses: \$${summary["total_expenses"]}\nRecent:\n$recent';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final financialContext = await _getFinancialContext();
    final systemPrompt = 'You are WalletWise AI, a friendly personal finance assistant. User financial data: $financialContext. Give concise practical advice under 150 words.';

    try {
      final reply = await ApiService.sendChatMessage(
        systemPrompt,
        _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList(),
      );
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Sorry, I had trouble connecting. Please try again.'});
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6C63FF)),
            ),
            SizedBox(width: 8),
            Text('WalletWise AI', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 48, color: Color(0xFF6C63FF)),
                      const SizedBox(height: 16),
                      const Text('WalletWise AI',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Ask me anything about your finances',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      ...['How am I doing with my spending?',
                        'Where can I save more money?',
                        'Give me a spending summary',
                      ].map((q) => GestureDetector(
                        onTap: () => _sendMessage(q),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                          ),
                          child: Text(q, style: const TextStyle(color: Color(0xFF6C63FF))),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, index) {
                  if (index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(children: [
                        SizedBox(width: 8),
                        SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Thinking...', style: TextStyle(color: Colors.grey)),
                      ]),
                    );
                  }
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF6C63FF) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                      ),
                      child: Text(msg['content']!,
                          style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 14, height: 1.5)),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about your finances...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
