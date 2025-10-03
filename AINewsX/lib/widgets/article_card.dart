// lib/widgets/article_card.dart
import 'package:flutter/material.dart';
import '../models/article.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Reusable card widget for displaying an article preview.
/// Supports save toggle integration for reactive UI.
class ArticleCard extends StatelessWidget {
  final Article article;
  final bool isSaved;
  final VoidCallback? onToggleSave;
  final Widget? trailing;

  const ArticleCard({
    super.key,
    required this.article,
    this.isSaved = false,
    this.onToggleSave,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final publishedDate = DateTime.tryParse(article.publishedAt) ?? DateTime.now();
    final timeAgo = timeago.format(publishedDate); // Default locale; add flutter_localizations if needed for custom.

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          // Navigate to detail screen; adjust route as needed.
          Navigator.pushNamed(
            context,
            '/article',
            arguments: article,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onToggleSave != null)
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.amber : null,
                  ),
                  onPressed: onToggleSave,
                  tooltip: isSaved ? 'Remove from Saved' : 'Save Article',
                ),
            ],
          ),
        ),
      ),
    );
  }
}