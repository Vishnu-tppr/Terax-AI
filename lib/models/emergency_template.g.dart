// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyTemplate _$EmergencyTemplateFromJson(Map<String, dynamic> json) =>
    EmergencyTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$TemplateCategoryEnumMap, json['category']),
      type: $enumDecode(_$TemplateTypeEnumMap, json['type']),
      textContent: json['textContent'] as String,
      audioUrl: json['audioUrl'] as String?,
      placeholders: json['placeholders'] as Map<String, dynamic>?,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      languageCode: json['languageCode'] as String? ?? 'en',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$EmergencyTemplateToJson(EmergencyTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': _$TemplateCategoryEnumMap[instance.category]!,
      'type': _$TemplateTypeEnumMap[instance.type]!,
      'textContent': instance.textContent,
      'audioUrl': instance.audioUrl,
      'placeholders': instance.placeholders,
      'isDefault': instance.isDefault,
      'isActive': instance.isActive,
      'languageCode': instance.languageCode,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$TemplateCategoryEnumMap = {
  TemplateCategory.medical: 'medical',
  TemplateCategory.safety: 'safety',
  TemplateCategory.stalking: 'stalking',
  TemplateCategory.harassment: 'harassment',
  TemplateCategory.travel: 'travel',
  TemplateCategory.custom: 'custom',
};

const _$TemplateTypeEnumMap = {
  TemplateType.text: 'text',
  TemplateType.audio: 'audio',
  TemplateType.combined: 'combined',
};
