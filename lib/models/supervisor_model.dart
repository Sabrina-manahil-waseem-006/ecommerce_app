import 'package:cloud_firestore/cloud_firestore.dart';

class SupervisorModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? cnic;
  final String? canteenId;
  final String? canteenName;

  SupervisorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.cnic,
    this.canteenId,
    this.canteenName,
  });

  factory SupervisorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SupervisorModel(
      id: doc.id,
      name: data['personalInfo']?['name'] ?? '',
      email: data['personalInfo']?['email'] ?? '',
      phone: data['personalInfo']?['phone'],
      cnic: data['personalInfo']?['cnic'],
      canteenId: data['canteenId'],
      canteenName: data['canteenName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personalInfo': {
        'name': name,
        'email': email,
        'phone': phone,
        'cnic': cnic,
      },
      'canteenId': canteenId,
      'canteenName': canteenName,
    };
  }
}
