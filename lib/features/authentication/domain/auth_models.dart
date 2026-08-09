class PhoneOtpLoginRequest {
  const PhoneOtpLoginRequest({
    required this.phoneNumber,
    required this.otp,
    this.firstName,
    this.lastName,
  });

  final String phoneNumber;
  final String otp;
  final String? firstName;
  final String? lastName;

  Map<String, dynamic> toJson() => {
    'phoneNumber': phoneNumber,
    'otp': otp,
    if (firstName?.trim().isNotEmpty ?? false) 'firstName': firstName!.trim(),
    if (lastName?.trim().isNotEmpty ?? false) 'lastName': lastName!.trim(),
  };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: _requiredString(json, 'accessToken'),
      accessTokenExpiresAt: _requiredDate(json, 'accessTokenExpiresAt'),
      refreshToken: _requiredString(json, 'refreshToken'),
      refreshTokenExpiresAt: _requiredDate(json, 'refreshTokenExpiresAt'),
      user: AuthUser.fromJson(_requiredMap(json, 'user')),
    );
  }

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final AuthUser user;
}

class RefreshedAuthTokens {
  const RefreshedAuthTokens({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  factory RefreshedAuthTokens.fromJson(
    Map<String, dynamic> json, {
    required String currentRefreshToken,
    required DateTime currentRefreshTokenExpiresAt,
  }) {
    final replacementRefreshToken = json['refreshToken']?.toString().trim();
    final replacementRefreshExpiry = DateTime.tryParse(
      json['refreshTokenExpiresAt']?.toString() ?? '',
    );
    return RefreshedAuthTokens(
      accessToken: _requiredString(json, 'accessToken'),
      accessTokenExpiresAt: _requiredDate(json, 'accessTokenExpiresAt'),
      refreshToken: replacementRefreshToken?.isNotEmpty == true
          ? replacementRefreshToken!
          : currentRefreshToken,
      refreshTokenExpiresAt:
          replacementRefreshExpiry ?? currentRefreshTokenExpiresAt,
    );
  }

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
    required this.phoneNumber,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    if (roles is! List) throw const FormatException('Invalid user roles.');
    return AuthUser(
      id: _requiredString(json, 'id'),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      roles: List.unmodifiable(roles.map((role) => role.toString())),
      phoneNumber: _requiredString(json, 'phoneNumber'),
    );
  }

  final String id;
  final String email;
  final String name;
  final List<String> roles;
  final String phoneNumber;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid $key.');
  return parsed;
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}
