class Inspector {
  final int id;
  final String name;
  final String email;
  final int availableTokens;
  final int usedTokens;

  Inspector({
    required this.id,
    required this.name,
    required this.email,
    required this.availableTokens,
    required this.usedTokens,
  });

  factory Inspector.fromJson(Map<String, dynamic> json) {
    return Inspector(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      availableTokens: json['available_tokens'] ?? 0,
      usedTokens: json['used_tokens'] ?? 0,
    );
  }
}
