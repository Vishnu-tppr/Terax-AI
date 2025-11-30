class User {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? profileImageUrl;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.profileImageUrl,
    this.preferences = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
    } catch (e) {
      // Handle parsing error, e.g., log it or set a default value
      parsedCreatedAt = DateTime.now(); // Default to now if parsing fails
    }

    DateTime parsedUpdatedAt;
    try {
      parsedUpdatedAt = DateTime.parse(json['updatedAt'] as String);
    } catch (e) {
      // Handle parsing error, e.g., log it or set a default value
      parsedUpdatedAt = DateTime.now(); // Default to now if parsing fails
    }

    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      isActive: json['isActive'] as bool? ?? true,
      profileImageUrl: json['profileImageUrl'] as String?,
      preferences: (json['preferences'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
    );
  }
}
