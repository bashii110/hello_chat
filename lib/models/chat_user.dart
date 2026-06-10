class ChatUser {
  ChatUser({
    required this.email,
    required this.id,
    required this.image,
    required this.lastActive,
    required this.name,
    required this.about,
  });

  late String email;
  late String id;
  late String image;
  late String lastActive;
  late String name;
  late String about;

  ChatUser.fromJson(Map<String, dynamic> json) {
    email = json['email']?.toString() ?? "";
    id = json['id']?.toString() ?? "";
    image = json['image']?.toString() ?? "";
    lastActive = json['last_active']?.toString() ?? "";
    name = json['name']?.toString() ?? "";
    about = json['about']?.toString() ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'id': id,
      'image': image,
      'last_active': lastActive,
      'name': name,
      'about': about
    };
  }

  // /// Handles int or string IDs from Firestore
  // int _parseId(dynamic value) {
  //   if (value is int) return value;
  //   if (value is String) return int.tryParse(value) ?? 0;
  //   return 0;
  // }
}
