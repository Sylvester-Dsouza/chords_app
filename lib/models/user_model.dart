/// Represents a user in the Worship Paradise application.
///
/// This model contains all user-related information including authentication,
/// profile details, subscription status, and account settings.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? firebaseUid;
  final String? profilePicture;
  final String? phoneNumber;
  final String subscriptionType;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? lastLoginAt;
  final String authProvider;
  final bool rememberMe;
  final bool termsAccepted;
  final DateTime? termsAcceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates a new [UserModel] instance.
  ///
  /// All required fields must be provided. Optional fields can be null.
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.firebaseUid,
    this.profilePicture,
    this.phoneNumber,
    required this.subscriptionType,
    required this.isActive,
    required this.isEmailVerified,
    this.lastLoginAt,
    required this.authProvider,
    required this.rememberMe,
    required this.termsAccepted,
    this.termsAcceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [UserModel] instance from a JSON map.
  ///
  /// Validates all required fields and throws [ArgumentError] if any required
  /// field is missing or has an invalid type. Throws [FormatException] if
  /// date strings cannot be parsed.
  ///
  /// Required fields: id, name, email, subscriptionType, authProvider,
  /// createdAt, updatedAt
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null ||
        json['id'] is! String ||
        (json['id'] as String).isEmpty) {
      throw ArgumentError(
        'UserModel.fromJson: id is required and must be a non-empty string',
      );
    }
    if (json['name'] == null ||
        json['name'] is! String ||
        (json['name'] as String).isEmpty) {
      throw ArgumentError(
        'UserModel.fromJson: name is required and must be a non-empty string',
      );
    }
    if (json['email'] == null ||
        json['email'] is! String ||
        (json['email'] as String).isEmpty) {
      throw ArgumentError(
        'UserModel.fromJson: email is required and must be a non-empty string',
      );
    }
    if (json['subscriptionType'] == null ||
        json['subscriptionType'] is! String) {
      throw ArgumentError(
        'UserModel.fromJson: subscriptionType is required and must be a string',
      );
    }
    if (json['authProvider'] == null || json['authProvider'] is! String) {
      throw ArgumentError(
        'UserModel.fromJson: authProvider is required and must be a string',
      );
    }
    if (json['createdAt'] == null || json['createdAt'] is! String) {
      throw ArgumentError(
        'UserModel.fromJson: createdAt is required and must be a string',
      );
    }
    if (json['updatedAt'] == null || json['updatedAt'] is! String) {
      throw ArgumentError(
        'UserModel.fromJson: updatedAt is required and must be a string',
      );
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      firebaseUid: json['firebaseUid'] as String?,
      profilePicture: json['profilePicture'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      subscriptionType: json['subscriptionType'] as String,
      isActive: json['isActive'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      lastLoginAt:
          json['lastLoginAt'] != null && json['lastLoginAt'] is String
              ? _parseDateTime(json['lastLoginAt'] as String)
              : null,
      authProvider: json['authProvider'] as String,
      rememberMe: json['rememberMe'] as bool? ?? false,
      termsAccepted: json['termsAccepted'] as bool? ?? false,
      termsAcceptedAt:
          json['termsAcceptedAt'] != null && json['termsAcceptedAt'] is String
              ? _parseDateTime(json['termsAcceptedAt'] as String)
              : null,
      createdAt: _parseDateTime(json['createdAt'] as String),
      updatedAt: _parseDateTime(json['updatedAt'] as String),
    );
  }

  // Helper method to safely parse DateTime strings
  static DateTime _parseDateTime(String dateTimeString) {
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      throw FormatException(
        'UserModel._parseDateTime: Invalid date format: $dateTimeString',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'firebaseUid': firebaseUid,
      'profilePicture': profilePicture,
      'phoneNumber': phoneNumber,
      'subscriptionType': subscriptionType,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'authProvider': authProvider,
      'rememberMe': rememberMe,
      'termsAccepted': termsAccepted,
      'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? firebaseUid,
    String? profilePicture,
    String? phoneNumber,
    String? subscriptionType,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? lastLoginAt,
    String? authProvider,
    bool? rememberMe,
    bool? termsAccepted,
    DateTime? termsAcceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      profilePicture: profilePicture ?? this.profilePicture,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      authProvider: authProvider ?? this.authProvider,
      rememberMe: rememberMe ?? this.rememberMe,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserModel) return false;

    return other.id == id &&
        other.name == name &&
        other.email == email &&
        other.firebaseUid == firebaseUid &&
        other.profilePicture == profilePicture &&
        other.phoneNumber == phoneNumber &&
        other.subscriptionType == subscriptionType &&
        other.isActive == isActive &&
        other.isEmailVerified == isEmailVerified &&
        other.lastLoginAt == lastLoginAt &&
        other.authProvider == authProvider &&
        other.rememberMe == rememberMe &&
        other.termsAccepted == termsAccepted &&
        other.termsAcceptedAt == termsAcceptedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      firebaseUid,
      profilePicture,
      phoneNumber,
      subscriptionType,
      isActive,
      isEmailVerified,
      lastLoginAt,
      authProvider,
      rememberMe,
      termsAccepted,
      termsAcceptedAt,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, firebaseUid: $firebaseUid, '
        'profilePicture: $profilePicture, phoneNumber: $phoneNumber, '
        'subscriptionType: $subscriptionType, isActive: $isActive, '
        'isEmailVerified: $isEmailVerified, lastLoginAt: $lastLoginAt, '
        'authProvider: $authProvider, rememberMe: $rememberMe, '
        'termsAccepted: $termsAccepted, termsAcceptedAt: $termsAcceptedAt, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
