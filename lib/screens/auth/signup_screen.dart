import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _selectedBarangay;
  XFile? _idImage;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMsg;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickId(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _idImage = picked);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload Valid ID',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.camera_alt_outlined,
                    color: gradientStart),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickId(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.photo_library_outlined,
                    color: gradientStart),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickId(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadIdImage(String uid) async {
    if (_idImage == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_ids')
        .child('$uid.jpg');
    if (kIsWeb) {
      final bytes = await _idImage!.readAsBytes();
      await ref.putData(bytes,
          SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(File(_idImage!.path));
    }
    return await ref.getDownloadURL();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // 1. Create Firebase Auth account
      final credential = await _authService.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // 2. Upload ID image if provided
      final idUrl = await _uploadIdImage(credential.user!.uid);

      // 3. Save profile to Firestore
      final profile = UserModel(
        uid: credential.user!.uid,
        fullName: _nameController.text.trim(),
        barangay: _selectedBarangay!,
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: 'resident',
        createdAt: DateTime.now(),
        idImageUrl: idUrl,
      );
      await _authService.createUserProfile(profile);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = _authService.friendlyError(e);
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMsg = 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Orange header ────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 32, horizontal: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: const [
                      Text('🐝', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 10),
                      Text(
                        appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        municipality,
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // ── Form body ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fill in your details to create a resident account.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280)),
                        ),

                        // Error banner
                        if (_errorMsg != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 16),
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

                        const SizedBox(height: 24),

                        // Full Name
                        _label('Full Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Full name is required'
                              : null,
                          decoration: _inputDecoration(
                            hint: 'Juan Dela Cruz',
                            icon: Icons.person_outline,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Email
                        _label('Email Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Phone number
                        _label('Mobile Number'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Mobile number is required';
                            }
                            final digits =
                                v.replaceAll(RegExp(r'\D'), '');
                            if (digits.length == 11 &&
                                digits.startsWith('09')) return null;
                            if (digits.length == 10 &&
                                digits.startsWith('9')) return null;
                            return 'Enter a valid PH number (09XXXXXXXXX)';
                          },
                          decoration: _inputDecoration(
                            hint: '09XXXXXXXXX',
                            icon: Icons.phone_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Home Address
                        _label('Home Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          textCapitalization: TextCapitalization.words,
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Address is required'
                              : null,
                          decoration: _inputDecoration(
                            hint: 'House No., Street, Barangay',
                            icon: Icons.home_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Valid ID upload
                        _label('Valid ID'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: Container(
                            width: double.infinity,
                            height: _idImage != null ? 180 : 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _idImage != null
                                    ? gradientStart
                                    : Colors.grey[300]!,
                                width: _idImage != null ? 2 : 1,
                              ),
                            ),
                            child: _idImage != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(9),
                                        child: kIsWeb
                                            ? Image.network(
                                                _idImage!.path,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_idImage!.path),
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _idImage = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: _showImageSourceSheet,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: gradientStart,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Change',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFF3E0),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.upload_file_outlined,
                                          color: gradientStart,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Tap to upload your valid ID',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Camera or Gallery • JPG, PNG',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password
                        _label('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            hint: 'At least 6 characters',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm Password
                        _label('Confirm Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            hint: 'Re-enter your password',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Create Account button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gradientStart,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Back to login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280)),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pop(),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: gradientStart,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: gradientStart, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
