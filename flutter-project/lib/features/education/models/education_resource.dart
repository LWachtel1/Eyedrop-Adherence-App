import 'package:flutter/material.dart';

enum ResourceType {
  text,
  video,
  pdf,
  website,
}

enum ResourceCategory {
  general,
  conditions,
  techniques,
}

class EducationResource {
  final String id;
  final String title;
  final String url;
  final String? description;
  final ResourceType type;
  final ResourceCategory category;
  final IconData icon;
  final Color color;
  bool isFavorite;
  bool isRead;
  DateTime? lastAccessed;

  EducationResource({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    required this.type,
    required this.category,
    required this.icon,
    required this.color,
    this.isFavorite = false,
    this.isRead = false,
    this.lastAccessed,
  });

  // Helper method to get icon based on resource type
  static IconData getIconForType(ResourceType type) {
    switch (type) {
      case ResourceType.text:
        return Icons.article;
      case ResourceType.video:
        return Icons.video_library;
      case ResourceType.pdf:
        return Icons.picture_as_pdf;
      case ResourceType.website:
        return Icons.language;
    }
  }

  // Helper method to get color based on category
  static Color getColorForCategory(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.general:
        return Colors.blue;
      case ResourceCategory.conditions:
        return Colors.red;
      case ResourceCategory.techniques:
        return Colors.orange;
    }
  }
} 