import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Generate a unique report reference: RPT-{timestamp}-{3-digit random}
  String generateReportReference() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (Random().nextInt(900) + 100).toString();
    return 'RPT-$ts-$rand';
  }

  /// Upload image to Firebase Storage using bytes (works on web + native)
  Future<String?> _uploadImage(XFile imageFile, String reportRef) async {
    try {
      final ref = _storage.ref().child('reports/$reportRef.jpg');
      final bytes = await imageFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Upload video to Firebase Storage using bytes (works on web + native)
  Future<String?> _uploadVideo(XFile videoFile, String reportRef) async {
    try {
      final ref =
          _storage.ref().child('reports/${reportRef}_video.mp4');
      final bytes = await videoFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'video/mp4'));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Submit a report — uploads image or video if present, then saves to Firestore
  Future<String> submitReport(
    ReportModel report, {
    XFile? imageFile,
    XFile? videoFile,
  }) async {
    String? imageUrl;
    String? videoUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, report.reportReference);
    }
    if (videoFile != null) {
      videoUrl = await _uploadVideo(videoFile, report.reportReference);
    }

    final data = report.toMap();
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (videoUrl != null) data['videoUrl'] = videoUrl;

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
