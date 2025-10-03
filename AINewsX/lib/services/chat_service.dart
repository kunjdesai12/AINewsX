// lib/services/chat_service.dart
/// Service for handling API communications with the news chatbot backend.
/// Manages HTTP requests to the /chat endpoint with proper error handling and timeouts.
import 'dart:convert';
import 'dart:io';  // For SocketException
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatService {
  static const String _baseUrl = 'http://192.168.29.215:5000';  // Updated: Your local IP (change if IP changes)
  static const Duration _timeout = Duration(seconds: 15);  // Generous for AI responses

  Future<Map<String, dynamic>> sendMessage(
      String message,
      List<ChatMessage> history,
      ) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    try {
      final requestBody = <String, dynamic>{
        'message': message.trim(),
        'history': history
            .map((msg) => <String, dynamic>{
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        })
            .toList(),
      };

      final response = await http
          .post(
        Uri.parse('$_baseUrl/chat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw HttpException(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException catch (e) {
      throw Exception('HTTP error: $e');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}

/// Custom exception for HTTP-related errors.
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);

  @override
  String toString() => message;
}