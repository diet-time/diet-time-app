class GuestSession {
  const GuestSession({required this.token, required this.expiresAt});

  factory GuestSession.fromJson(Map<String, dynamic> json) {
    final token =
        json['guestToken']?.toString().trim() ??
        json['token']?.toString().trim() ??
        '';
    final expiryValue = json['expiresAt']?.toString();
    final expiresIn = json['expiresInSeconds'];
    final expiresAt =
        DateTime.tryParse(expiryValue ?? '') ??
        DateTime.now().add(
          Duration(seconds: expiresIn is num ? expiresIn.toInt() : 86400),
        );
    if (token.isEmpty) throw const FormatException('Missing guest token');
    return GuestSession(token: token, expiresAt: expiresAt);
  }

  final String token;
  final DateTime expiresAt;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}
