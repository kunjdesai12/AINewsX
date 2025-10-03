// lib/screens/chat_screen.dart
/// Dedicated screen for chatting with the AI News Bot.
/// Features message bubbles, input field, loading states, and expandable details for articles/summaries.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';  // For opening article URLs
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI News Bot'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Chat History',
            onPressed: () => context.read<ChatProvider>().clearHistory(),
          ),
        ],
      ),
      body: const _ChatBody(),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody();

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Column(
      children: [
        // Messages List (reverse for bottom-latest)
        Expanded(
          child: chatProvider.isLoading
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Thinking...'),
              ],
            ),
          )
              : chatProvider.messages.isEmpty
              ? _EmptyState()
              : ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: chatProvider.messages.length,
            itemBuilder: (context, index) {
              final message = chatProvider.messages[index];
              return _MessageBubble(message: message);
            },
          ),
        ),
        // Input Composer
        _InputComposer(chatProvider: chatProvider),
      ],
    );
  }
}

/// Empty state widget for new chats.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Welcome to AI News Bot!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask about latest news, summaries, or fact-checks.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},  // Placeholder; input will handle
            icon: const Icon(Icons.mic),
            label: const Text('Start Chatting'),
          ),
        ],
      ),
    );
  }
}

/// Message bubble widget with optional extra data expansion.
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (message.extraData != null) ...[
              const SizedBox(height: 8),
              _ExtraDataExpansionTile(data: message.extraData!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Expandable tile for article/summary/fact-check details.
class _ExtraDataExpansionTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ExtraDataExpansionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
      title: Text(
        'Details',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      children: [
        if (data['articles'] != null) ...[
          ..._buildArticleList(data['articles'] as List<dynamic>),
        ],
        if (data['summaries'] != null && (data['summaries'] as List).isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Summary: ${(data['summaries'] as List)[0]['summary']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        if (data['fact_check'] != null) ...[
          const Divider(),
          ListTile(
            leading: Icon(
              data['fact_check']['final']['final_verdict'] == 'Real'
                  ? Icons.verified
                  : Icons.warning,
              color: data['fact_check']['final']['final_verdict'] == 'Real'
                  ? Colors.green
                  : Colors.red,
            ),
            title: const Text('Fact Check Verdict'),
            subtitle: Text(data['fact_check']['final']['final_verdict']),
            trailing: Text(data['fact_check']['final']['reason']),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildArticleList(List<dynamic> articles) {
    return articles.map<Widget>((article) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.article, color: Colors.blue),
        title: Text(article['title'] ?? 'No Title'),
        subtitle: Text(article['source'] ?? 'Unknown Source'),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () async {
            final url = Uri.parse(article['url'] ?? '');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      );
    }).toList();
  }
}

/// Input field and send button composer.
class _InputComposer extends StatelessWidget {
  final ChatProvider chatProvider;

  const _InputComposer({required this.chatProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: chatProvider.messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message... (e.g., "Latest AI news?")',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _handleSubmitted(chatProvider),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: () => _handleSubmitted(chatProvider),
              mini: true,
              heroTag: 'send_button',
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(ChatProvider provider) {
    if (provider.messageController.text.trim().isNotEmpty) {
      provider.sendMessage();
    }
  }
}