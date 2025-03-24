import 'package:flutter/material.dart';

/// Represents a suggested alternative to a potentially addictive app
class Alternative {
  /// The title or name of the alternative
  final String title;

  /// A brief description of the alternative
  final String description;

  /// The package name if it's an app, null if it's an offline activity
  final String? packageName;

  /// Whether this alternative is an offline activity
  final bool isOfflineActivity;

  /// Icon data for the alternative
  final IconData icon;

  /// An optional category for grouping alternatives
  final String? category;

  const Alternative({
    required this.title,
    required this.description,
    this.packageName,
    this.isOfflineActivity = false,
    required this.icon,
    this.category,
  });

  /// Create a copy of this alternative with some fields replaced
  Alternative copyWith({
    String? title,
    String? description,
    String? packageName,
    bool? isOfflineActivity,
    IconData? icon,
    String? category,
  }) {
    return Alternative(
      title: title ?? this.title,
      description: description ?? this.description,
      packageName: packageName ?? this.packageName,
      isOfflineActivity: isOfflineActivity ?? this.isOfflineActivity,
      icon: icon ?? this.icon,
      category: category ?? this.category,
    );
  }
}

/// Contains enhanced metadata about an app, including alternatives
class AppMetadata {
  /// The display name of the app
  final String displayName;

  /// The category the app belongs to (Social Media, Entertainment, etc.)
  final String category;

  /// A list of alternative activities or apps
  final List<Alternative> alternatives;

  const AppMetadata({
    required this.displayName,
    required this.category,
    required this.alternatives,
  });
}

/// Defines types of app categories for classification
class AppCategories {
  static const String socialMedia = 'Social Media';
  static const String entertainment = 'Entertainment';
  static const String messaging = 'Messaging';
  static const String productivity = 'Productivity';
  static const String gaming = 'Gaming';
  static const String news = 'News & Reading';
  static const String shopping = 'Shopping';
  static const String other = 'Other';
}