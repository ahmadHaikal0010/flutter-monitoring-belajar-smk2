class UserModel {
  final int id;
  final String name;
  final String email;
  final String? role;
  final StudentModel? student;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.student,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      student: json['student'] != null ? StudentModel.fromJson(json['student']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'student': student?.toJson(),
    };
  }
}

class StudentModel {
  final String id;
  final String nisn;
  final String address;
  final String? photo;
  final String? photoUrl;
  final String? className;

  StudentModel({
    required this.id,
    required this.nisn,
    required this.address,
    this.photo,
    this.photoUrl,
    this.className,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    String? className = json['class_name'];
    if (className == null && json['classroom'] != null) {
      if (json['classroom'] is Map) {
        className = json['classroom']['nama_kelas'] ?? json['classroom']['name'];
      }
    }

    return StudentModel(
      id: json['id'] ?? '',
      nisn: json['nisn'] ?? '',
      address: json['address'] ?? json['alamat'] ?? '',
      photo: json['photo'] ?? json['foto'],
      photoUrl: json['photo_url'],
      className: className,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nisn': nisn,
      'address': address,
      'photo': photo,
      'photo_url': photoUrl,
      'class_name': className,
    };
  }
}
