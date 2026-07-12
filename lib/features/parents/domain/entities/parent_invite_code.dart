class ParentInviteCode {
  const ParentInviteCode({
    required this.code,
    required this.expiresAtUtc,
    required this.createdAtUtc,
  });

  final String code;
  final DateTime expiresAtUtc;
  final DateTime createdAtUtc;

  factory ParentInviteCode.fromJson(Map<String, dynamic> json) {
    return ParentInviteCode(
      code: json['code'] as String,
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}
