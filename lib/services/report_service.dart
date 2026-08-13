import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Generate a unique report reference: RPT-{timestamp}-{3-digit random}
  String generateReportReference() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (Random().nextInt(900) + 100).toString(); // 100-999
    return 'RPT-$ts-$rand';
  }

  /// Upload image to Firebase Storage and return download URL
  Future<String?> _uploadImage(File imageFile, String reportRef) async {
    try {
      final ref = _storage.ref().child('reports/$reportRef.jpg');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Submit a report — uploads image if present, then saves to Firestore
  Future<String> submitReport(ReportModel report, {File? imageFile}) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, report.reportReference);
    }

    final data = report.toMap();
    if (imageUrl != null) data['imageUrl'] = imageUrl;

    final docRef = await _db.collection('reports').add(data);
    return docRef.id;
  }

  /// Real-time stream of all reports for a given user
  Stream<List<ReportModel>> getUserReports(String uid) {
    return _db
        .collection('reports')
        .where('userId', isEqualTo: uid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ReportModel.fromDoc(doc)).toList());
  }

  /// Fetch the 3 most recent reports for home screen
  Stream<List<ReportModel>> getRecentReports(String uid) {
    return _db
        .collection('reports')
        .where('userId', isEqualTo: uid)
        .orderBy('submittedAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ReportModel.fromDoc(doc)).toList());
  }
}
