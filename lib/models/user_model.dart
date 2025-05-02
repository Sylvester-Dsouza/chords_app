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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      firebaseUid: json['firebaseUid'],
      profilePicture: json['profilePicture'],
      phoneNumber: json['phoneNumber'],
      subscriptionType: json['subscriptionType'],
      isActive: json['isActive'],
      isEmailVerified: json['isEmailVerified'],
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      authProvider: json['authProvider'],
      rememberMe: json['rememberMe'],
      termsAccepted: json['termsAccepted'],
      termsAcceptedAt: json['termsAcceptedAt'] != null
          ? DateTime.parse(json['termsAcceptedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
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
}
