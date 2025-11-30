import 'package:json_annotation/json_annotation.dart';

part 'emergency_template.g.dart';

enum TemplateCategory { medical, safety, stalking, harassment, travel, custom }

enum TemplateType { text, audio, combined }

@JsonSerializable()
class EmergencyTemplate {
  final String id;
  final String title;
  final String description;
  final TemplateCategory category;
  final TemplateType type;
  final String textContent;
  final String? audioUrl;
  final Map<String, dynamic>? placeholders;
  final bool isDefault;
  final bool isActive;
  final String? languageCode;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.textContent,
    this.audioUrl,
    this.placeholders,
    this.isDefault = false,
    this.isActive = true,
    this.languageCode = 'en',
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyTemplate.fromJson(Map<String, dynamic> json) =>
      _$EmergencyTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyTemplateToJson(this);

  EmergencyTemplate copyWith({
    String? id,
    String? title,
    String? description,
    TemplateCategory? category,
    TemplateType? type,
    String? textContent,
    String? audioUrl,
    Map<String, dynamic>? placeholders,
    bool? isDefault,
    bool? isActive,
    String? languageCode,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      textContent: textContent ?? this.textContent,
      audioUrl: audioUrl ?? this.audioUrl,
      placeholders: placeholders ?? this.placeholders,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      languageCode: languageCode ?? this.languageCode,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get categoryText {
    switch (category) {
      case TemplateCategory.medical:
        return 'Medical Emergency';
      case TemplateCategory.safety:
        return 'Safety Concern';
      case TemplateCategory.stalking:
        return 'Stalking';
      case TemplateCategory.harassment:
        return 'Harassment';
      case TemplateCategory.travel:
        return 'Travel Safety';
      case TemplateCategory.custom:
        return 'Custom Template';
    }
  }

  String get typeText {
    switch (type) {
      case TemplateType.text:
        return 'Text Message';
      case TemplateType.audio:
        return 'Voice Message';
      case TemplateType.combined:
        return 'Text & Voice';
    }
  }

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasPlaceholders => placeholders != null && placeholders!.isNotEmpty;
  bool get hasTags => tags != null && tags!.isNotEmpty;

  String fillPlaceholders(Map<String, String> values) {
    if (!hasPlaceholders) return textContent;

    String filledContent = textContent;
    values.forEach((key, value) {
      filledContent = filledContent.replaceAll('{$key}', value);
    });
    return filledContent;
  }
}
