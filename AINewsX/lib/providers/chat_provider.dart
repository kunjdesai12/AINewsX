// lib/providers/chat_provider.dart
/// Provider for managing chat state: messages, loading, and API interactions.
/// Uses ChangeNotifier for reactive UI updates.
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  final TextEditingController _messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  TextEditingController get messageController => _messageController;
  bool get isLoading => _isLoading;

  /// Clears the entire chat history.
  void clearHistory() {
    _messages.clear();
    _messageController.clear();
    notifyListeners();
  }

  /// Sends a message to the backend and adds response to history.
  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message immediately
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, userMessage);  // Insert at top (reverse list)
    _messageController.clear();
    _isLoading = true;
    notifyListeners();

    try {
      // Prepare history for API (reverse to chronological)
      final history = _messages.reversed.toList();

      final response = await _service.sendMessage(text, history);

      // Add AI response
      final aiMessage = ChatMessage(
        text: response['response'] as String? ?? 'No response received.',
        isUser: false,
        timestamp: DateTime.now(),
        extraData: <String, dynamic>{
          if (response['articles'] != null) 'articles': response['articles'],
          if (response['summaries'] != null) 'summaries': response['summaries'],
          if (response['fact_check'] != null) 'fact_check': response['fact_check'],
        },
      );
      _messages.insert(0, aiMessage);
    } catch (error) {
      // Add error as AI message for UX
      final errorMessage = ChatMessage(
        text: 'Sorry, an error occurred: ${error.toString()}. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.insert(0, errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}