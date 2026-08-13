import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current Firebase user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user (nullable)
  User? get currentUser => _auth.currentUser;

  /// Normalise Philippine mobile number to E.164 (+63XXXXXXXXX)
  String normalisePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('63') && cleaned.length == 12) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('09') && cleaned.length == 11) {
      return '+63${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('9') && cleaned.length == 10) {
      return '+63$cleaned';
    }
    return '+$cleaned';
  }

  /// Send OTP via Firebase Phone Auth
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    int? resendToken,
  }) async {
    final e164 = normalisePhone(phoneNumber);
    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: resendToken,
      verificationCompleted: onAutoVerified,
      verificationFailed: onVerificationFailed,
      codeSent: (verificationId, resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verify the 6-digit OTP and sign in
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Sign in directly with a PhoneAuthCredential (auto-verify path)
  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    return _auth.signInWithCredential(credential);
  }

  /// Check whether a Firestore profile exists for [uid]
  Future<bool> profileExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// Fetch user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Create a new Firestore profile
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
