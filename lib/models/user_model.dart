class User {
  final String id;
  final String name;
  final String email;
  final int credits;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.credits,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? 'Guest',
      email: json['email'] ?? '',
      credits: json['credits'] ?? 0,
      token: token ?? json['token'],
    );
  }

  // --- ADD THIS METHOD ---
  User copyWith({
    String? id,
    String? name,
    String? email,
    int? credits,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      credits: credits ?? this.credits,
      token: token ?? this.token,
    );
  }
}