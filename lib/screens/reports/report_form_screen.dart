import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  int _step = 1;
  String? _selectedCategory;
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  File? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _submitting = false;
  UserModel? _userProfile;

  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final p = await _authService.getUserProfile(uid);
      if (mounted) setState(() => _userProfile = p);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Step 1: category selection ──────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What type of concern are you reporting?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((cat) {
            final selected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategory = cat;
                _step = 2;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? gradientStart
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? gradientStart : Colors.grey.shade300,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_categoryIcon(cat),
                        color: selected ? Colors.white : gradientStart,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      cat,
                      style: TextStyle(
                        color:
                            selected ? Colors.white : const Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Health':
        return Icons.health_and_safety_outlined;
      case 'Transportation':
        return Icons.directions_car_outlined;
      case 'Environment':
        return Icons.eco_outlined;
      case 'Consumer Issue':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  // ── Step 2: Report details ───────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emergency notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'IMPORTANT NOTICE: This platform is NOT for emergency incidents or life-threatening situations. For emergencies, please call 911 or your local emergency hotline immediately.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Category (tappable to change)
        const Text('Concern Category',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _step = 1),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: gradientStart.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gradientStart.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(_categoryIcon(_selectedCategory ?? ''),
                    color: gradientStart, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_selectedCategory ?? '',
                      style: const TextStyle(
                          color: gradientStart,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.edit_outlined,
                    size: 16, color: gradientStart),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        const Text('Description',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _descController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Provide details about your concern...',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gradientStart, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Photo Evidence
        const Text('Photo Evidence (Optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showCameraPrivacyDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid),
            ),
            child: _imageFile == null
                ? const Column(
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 32, color: Colors.grey),
                      SizedBox(height: 6),
                      Text('Take Photo with Camera',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text('Auto-capture location & time',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_imageFile!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageFile = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Location
        const Text('Location',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Enter location or barangay',
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gradientStart, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _useGpsLocation,
          icon: const Text('📍', style: TextStyle(fontSize: 16)),
          label: const Text('Use my current GPS location',
              style: TextStyle(color: gradientStart)),
        ),
        if (_latitude != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your report will be reviewed by Bacnotan LGU officials. Barangay staff may recategorize your concern if needed for proper routing.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: gradientStart,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Submit Report',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _showCameraPrivacyDialog() async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📷 Camera Access Notice'),
        content: const Text(
          'BEE-Alert will use your camera to capture photo evidence. '
          'Photos will include timestamp and location data. '
          'This information will be shared with Bacnotan LGU officials. '
          'By proceeding, you consent to photo capture.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: gradientStart),
            child: const Text('Allow & Take Photo'),
          ),
        ],
      ),
    );

    if (allowed == true) {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1280,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    }
  }

  Future<void> _useGpsLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permission permanently denied.')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationController.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your concern.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = _reportService.generateReportReference();
      final now = DateTime.now();

      final report = ReportModel(
        id: '',
        userId: user.uid,
        userName: _userProfile?.fullName ?? '',
        barangay: _userProfile?.barangay ?? '',
        category: _selectedCategory!,
        description: _descController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        location: _locationController.text.trim(),
        status: statusPending,
        submittedAt: now,
        updatedAt: now,
        reportReference: ref,
      );

      await _reportService.submitReport(report, imageFile: _imageFile);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/report-success',
        arguments: {
          'reportReference': ref,
          'category': _selectedCategory,
          'location': _locationController.text.trim(),
          'submittedAt': now,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  String _stepTitle() {
    switch (_step) {
      case 1:
        return 'Step 1 of 3: Select Category';
      case 2:
        return 'Step 2 of 3: Report Details';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_step == 2) {
                          setState(() => _step = 1);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Report Concern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepTitle(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // Step progress bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: _step >= 2
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _step == 1 ? _buildStep1() : _buildStep2(),
            ),
          ),
        ],
      ),
    );
  }
}
