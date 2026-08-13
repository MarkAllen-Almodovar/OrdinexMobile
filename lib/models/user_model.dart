import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String barangay;
  final String address;
  final String phoneNumber;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.barangay,
    required this.address,
    required this.phoneNumber,
    this.role = 'resident',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'barangay': barangay,
        'address': address,
        'phoneNumber': phoneNumber,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
        uid: uid,
        fullName: map['fullName'] as String? ?? '',
        barangay: map['barangay'] as String? ?? '',
        address: map['address'] as String? ?? '',
        phoneNumber: map['phoneNumber'] as String? ?? '',
        role: map['role'] as String? ?? 'resident',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory UserModel.fromDoc(DocumentSnapshot doc) =>
      UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? barangay,
    String? address,
    String? phoneNumber,
    String? role,
    DateTime? createdAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        fullName: fullName ?? this.fullName,
        barangay: barangay ?? this.barangay,
        address: address ?? this.address,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );
}
