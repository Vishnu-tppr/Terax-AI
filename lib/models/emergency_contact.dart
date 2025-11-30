enum ContactPriority { one, two, three, four, five }

extension ContactPriorityExtension on ContactPriority {
  int toInt() {
    switch (this) {
      case ContactPriority.one:
        return 1;
      case ContactPriority.two:
        return 2;
      case ContactPriority.three:
        return 3;
      case ContactPriority.four:
        return 4;
      case ContactPriority.five:
        return 5;
    }
  }

  int compareTo(ContactPriority other) {
    return toInt().compareTo(other.toInt());
  }
}

extension ContactPriorityOperators on ContactPriority {
  bool operator >(ContactPriority other) => compareTo(other) > 0;
  bool operator <(ContactPriority other) => compareTo(other) < 0;
  bool operator >=(ContactPriority other) => compareTo(other) >= 0;
  bool operator <=(ContactPriority other) => compareTo(other) <= 0;
}

enum ContactRelationship { emergency, family, friend }

enum NotificationMethod { sms, call, email, push }

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final ContactRelationship relationship;
  final ContactPriority priority;

  int get priorityNumber => priority.toInt();
  final List<NotificationMethod> notificationMethods;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    required this.priority,
    required this.notificationMethods,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      relationship: ContactRelationship.values.firstWhere(
        (e) => e.toString() == 'ContactRelationship.${json['relationship']}',
      ),
      priority: ContactPriority.values.firstWhere(
        (e) => e.toString() == 'ContactPriority.${json['priority']}',
      ),
      notificationMethods: (json['notificationMethods'] as List)
          .map((e) => NotificationMethod.values.firstWhere(
                (n) => n.toString() == 'NotificationMethod.$e',
              ))
          .toList(),
      isPrimary: json['isPrimary'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'notificationMethods':
          notificationMethods.map((e) => e.toString().split('.').last).toList(),
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    ContactRelationship? relationship,
    ContactPriority? priority,
    List<NotificationMethod>? notificationMethods,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      notificationMethods: notificationMethods ?? this.notificationMethods,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String get priorityText {
    switch (priority) {
      case ContactPriority.one:
        return '1';
      case ContactPriority.two:
        return '2';
      case ContactPriority.three:
        return '3';
      case ContactPriority.four:
        return '4';
      case ContactPriority.five:
        return '5';
    }
  }

  String get relationshipText {
    switch (relationship) {
      case ContactRelationship.emergency:
        return 'Emergency Contact';
      case ContactRelationship.family:
        return 'Family';
      case ContactRelationship.friend:
        return 'Friend';
    }
  }
}
