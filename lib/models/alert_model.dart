import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String type; // 'emergency', 'announcement'
  final String priority; // 'high', 'medium', 'low'
  final String title;
  final String description;
  final DateTime createdAt;
  final String? actionLink;

  const AlertModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.createdAt,
    this.actionLink,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) => AlertModel(
        id: id,
        type: map['type'] as String? ?? 'announcement',
        priority: map['priority'] as String? ?? 'low',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        actionLink: map['actionLink'] as String?,
      );

  factory AlertModel.fromDoc(DocumentSnapshot doc) =>
      AlertModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
}
