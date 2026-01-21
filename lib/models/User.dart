class User {
  final int id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final int credits; // <--- Make sure this is added
  final bool isGuest;
  final String? token; // We store the token here for easy access

  User({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.credits = 0,
    this.isGuest = false,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    // Handle the nested structure if your login returns { "user": {...}, "token": ... }
    // But sometimes 'user' itself is passed here.
    // Based on your JSON: { "id": 1, "credits": 10, ... }

    return User(
      id: json['id'],
      name: json['name'] ?? 'Guest',
      email: json['email'],
      avatarUrl: json['avatar_url'],
      // Parse credits safely, defaulting to 0
      credits: json['credits'] is int ? json['credits'] : int.tryParse(json['credits'].toString()) ?? 0,
      isGuest: json['is_guest'] == 1 || json['is_guest'] == true,
      token: token,
    );
  }

  // Helper to update the user with new data (immutability)
  User copyWith({
    int? credits,
    String? name,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      credits: credits ?? this.credits,
      isGuest: isGuest,
      token: token,
    );
  }
}