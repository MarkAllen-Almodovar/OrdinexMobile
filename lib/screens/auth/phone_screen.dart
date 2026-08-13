import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    await _authService.sendOTP(
      phoneNumber: _phoneController.text.trim(),
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.of(context).pushNamed(
          '/otp',
          arguments: {
            'verificationId': verificationId,
            'resendToken': resendToken,
            'phoneNumber': _authService
                .normalisePhone(_phoneController.text.trim()),
          },
        );
      },
      onVerificationFailed: (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _errorMsg = e.message ?? 'Verification failed. Try again.';
        });
      },
      onAutoVerified: (credential) async {
        // Auto-verify on Android — sign in immediately
        try {
          final result = await _authService.signInWithCredential(credential);
          if (!mounted) return;
          final hasProfile =
              await _authService.profileExists(result.user!.uid);
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            hasProfile ? '/home' : '/register',
            arguments: {'phoneNumber': result.user!.phoneNumber},
          );
        } catch (_) {
          setState(() {
            _loading = false;
            _errorMsg = 'Auto-verification failed. Enter OTP manually.';
          });
        }
      },
    );
  }

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your phone number';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('09')) return null;
    if (digits.length == 10 && digits.startsWith('9')) return null;
    return 'Enter a valid PH number (09XXXXXXXXX)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Orange gradient hero
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐝',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      municipality,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign in or Register',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter your Philippine mobile number to continue.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 28),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '09XXXXXXXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),

                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Send OTP button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOTP,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: gradientStart,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send OTP',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'A 6-digit verification code will be sent to your mobile number.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
