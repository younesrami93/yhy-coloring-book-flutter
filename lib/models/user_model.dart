class User {
  final String id;
  final String name;
  final String email;
  final int credits;
  final String? token; // The Sanctum API Token

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
      credits: json['credits'] ?? 0, // Default to 0 if null
      token: token ?? json['token'],
    );
  }
}