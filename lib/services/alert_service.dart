import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

class AlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Real-time stream of all alerts, newest first
  Stream<List<AlertModel>> getAlerts() {
    return _db
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AlertModel.fromDoc(doc)).toList());
  }

  /// Emergency alerts only
  Stream<List<AlertModel>> getEmergencyAlerts() {
    return _db
        .collection('alerts')
        .where('type', isEqualTo: 'emergency')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AlertModel.fromDoc(doc)).toList());
  }

  /// Unread alert count for badge
  Stream<int> getUnreadCount() {
    return _db
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
