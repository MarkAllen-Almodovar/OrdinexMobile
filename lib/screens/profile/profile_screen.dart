import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? userProfile;
  final bool embedded;

  const ProfileScreen({
    super.key,
    this.userProfile,
    this.embedded = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.userProfile;
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of BEE-Alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: _profile),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final reportService = ReportService();
    final name = _profile?.fullName ?? 'Resident';
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final phone = _profile?.phoneNumber ?? '';
    final address = _profile?.address ?? '';
    final barangay = _profile?.barangay ?? '';
    final fullAddress = [
      if (barangay.isNotEmpty) 'Brgy. $barangay',
      address,
    ].where((s) => s.isNotEmpty).join(', ');

    Widget body = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Header ───────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.embedded)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                    if (!widget.embedded) const SizedBox(height: 8),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your account information.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar Card ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Resident',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: gradientStart),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                              color: gradientStart,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: gradientStart),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Personal Information ──────────────────────
                const _SectionTitle(title: 'Personal Information'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email.isEmpty ? '—' : email,
                      ),
                      const Divider(height: 1, indent: 56),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: phone.isEmpty ? '—' : phone,
                      ),
                      const Divider(height: 1, indent: 56),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: fullAddress.isEmpty ? '—' : fullAddress,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Settings ─────────────────────────────────
                const _SectionTitle(title: 'Settings'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const _NotificationToggleTile(),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: gradientStart.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.security_outlined,
                              color: gradientStart, size: 18),
                        ),
                        title: const Text('Privacy & Security',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937))),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade400),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacySecurityScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── My Activity ───────────────────────────────
                const _SectionTitle(title: 'My Activity'),
                const SizedBox(height: 10),
                StreamBuilder<List<ReportModel>>(
                  stream: reportService.getUserReports(uid),
                  builder: (ctx, snap) {
                    final reports = snap.data ?? [];
                    final total = reports.length;
                    final resolved = reports
                        .where((r) => r.status == statusCompleted)
                        .length;
                    return Row(
                      children: [
                        Expanded(
                          child: _ActivityBox(
                            value: '$total',
                            label: 'Total Reports',
                            bg: gradientStart.withValues(alpha: 0.15),
                            valueColor: gradientStart,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActivityBox(
                            value: '$resolved',
                            label: 'Resolved',
                            bg: colorPending.withValues(alpha: 0.15),
                            valueColor: colorPending,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Logout Button ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmSignOut,
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.red, size: 20),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFFFCDD2), width: 1.5),
                      backgroundColor: Colors.red.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: const Color(0xFFF5F5F5), body: body);
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserModel? profile;
  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  String? _selectedBarangay;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.profile?.fullName ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.profile?.phoneNumber ?? '');
    _addressCtrl =
        TextEditingController(text: widget.profile?.address ?? '');
    _selectedBarangay = widget.profile?.barangay.isNotEmpty == true
        ? widget.profile!.barangay
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final fields = {
        'fullName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        if (_selectedBarangay != null) 'barangay': _selectedBarangay,
      };
      await AuthService().updateUserProfile(uid, fields);

      final updated = (widget.profile ?? UserModel(
        uid: uid,
        fullName: '',
        email: '',
        barangay: '',
        address: '',
        phoneNumber: '',
        createdAt: DateTime.now(),
      )).copyWith(
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        barangay: _selectedBarangay,
      );

      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Profile',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your personal information.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 20),

              // Full Name
              _fieldLabel('Full Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                decoration: _inputDeco(
                    hint: 'Juan Dela Cruz',
                    icon: Icons.person_outline),
              ),

              const SizedBox(height: 14),

              // Phone
              _fieldLabel('Mobile Number'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length == 11 && digits.startsWith('09')) {
                    return null;
                  }
                  return 'Enter a valid PH number (09XXXXXXXXX)';
                },
                decoration: _inputDeco(
                    hint: '09XXXXXXXXX',
                    icon: Icons.phone_outlined),
              ),

              const SizedBox(height: 14),

              // Barangay dropdown
              _fieldLabel('Barangay'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedBarangay,
                hint: const Text('Select barangay',
                    style: TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 14)),
                validator: (v) =>
                    v == null ? 'Please select your barangay' : null,
                items: bacnotanBarangays
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBarangay = v),
                decoration: _inputDeco(
                    hint: '', icon: Icons.location_city_outlined),
                isExpanded: true,
              ),

              const SizedBox(height: 14),

              // Address
              _fieldLabel('Home Address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressCtrl,
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                decoration: _inputDeco(
                    hint: 'House No., Street',
                    icon: Icons.home_outlined),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gradientStart,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)),
      );

  InputDecoration _inputDeco(
          {required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon:
            Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: gradientStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.red, width: 2),
        ),
      );
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937)),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: gradientStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: gradientStart, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 11, color: Color(0xFF9CA3AF))),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500)),
    );
  }
}

class _ActivityBox extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color valueColor;
  const _ActivityBox(
      {required this.value,
      required this.label,
      required this.bg,
      required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: valueColor),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _NotificationToggleTile extends StatefulWidget {
  const _NotificationToggleTile();

  @override
  State<_NotificationToggleTile> createState() =>
      _NotificationToggleTileState();
}

class _NotificationToggleTileState
    extends State<_NotificationToggleTile> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: gradientStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.notifications_outlined,
            color: gradientStart, size: 18),
      ),
      title: const Text('Notifications',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937))),
      trailing: Switch(
        value: _enabled,
        onChanged: (v) => setState(() => _enabled = v),
        activeThumbColor: gradientStart,
      ),
    );
  }
}

// ── Privacy & Security Screen ─────────────────────────────────────────────────

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
    });

    final current = _currentPasswordCtrl.text;
    final newPwd = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      setState(() => _passwordError = 'All fields are required.');
      return;
    }
    if (newPwd.length < 6) {
      setState(
          () => _passwordError = 'New password must be at least 6 characters.');
      return;
    }
    if (newPwd != confirm) {
      setState(() => _passwordError = 'Passwords do not match.');
      return;
    }

    setState(() => _savingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPwd);

      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();

      setState(() {
        _savingPassword = false;
        _passwordSuccess = 'Password changed successfully.';
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Current password is incorrect.';
          break;
        case 'weak-password':
          msg = 'New password is too weak.';
          break;
        case 'requires-recent-login':
          msg = 'Please sign out and sign in again before changing your password.';
          break;
        default:
          msg = e.message ?? 'Failed to change password.';
      }
      setState(() {
        _savingPassword = false;
        _passwordError = msg;
      });
    } catch (_) {
      setState(() {
        _savingPassword = false;
        _passwordError = 'Something went wrong. Please try again.';
      });
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
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Privacy & Security',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your account security and data privacy.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Change Password ─────────────────────────
                  const _PsSection(title: 'Change Password'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_passwordError != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(_passwordError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13)),
                          ),
                        if (_passwordSuccess != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(_passwordSuccess!,
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 13)),
                          ),
                        _PasswordField(
                          controller: _currentPasswordCtrl,
                          label: 'Current Password',
                          obscure: _obscureCurrent,
                          onToggle: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          controller: _newPasswordCtrl,
                          label: 'New Password',
                          obscure: _obscureNew,
                          onToggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          controller: _confirmPasswordCtrl,
                          label: 'Confirm New Password',
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _savingPassword ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gradientStart,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _savingPassword
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text('Update Password',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Data Privacy ────────────────────────────
                  const _PsSection(title: 'Data Privacy'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _PsMenuItem(
                          icon: Icons.description_outlined,
                          label: 'Privacy Policy',
                          onTap: () => _showPrivacyPolicy(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        _PsMenuItem(
                          icon: Icons.info_outline,
                          label: 'Data Collection Notice',
                          onTap: () => _showDataCollection(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Account Security ────────────────────────
                  const _PsSection(title: 'Account Security'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _PsMenuItem(
                          icon: Icons.email_outlined,
                          label: 'Linked Email',
                          subtitle: FirebaseAuth
                                  .instance.currentUser?.email ??
                              '—',
                          showChevron: false,
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56),
                        _PsMenuItem(
                          icon: Icons.lock_reset_outlined,
                          label: 'Send Password Reset Email',
                          onTap: () async {
                            final email =
                                FirebaseAuth.instance.currentUser?.email;
                            if (email == null) return;
                            await AuthService().sendPasswordReset(email);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Password reset email sent.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'BEE-Alert collects personal information including your name, '
            'phone number, barangay, and location data solely for processing '
            'community concern reports.\n\n'
            'Your data is shared only with authorized Bacnotan LGU officials. '
            'We do not sell or share your information with third parties.\n\n'
            'Photos and videos attached to reports may include location metadata. '
            'By using BEE-Alert, you consent to this data collection and use.\n\n'
            'You may request deletion of your account and data by contacting '
            'the Bacnotan Municipal Hall.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: gradientStart),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataCollection(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Data Collection Notice'),
        content: const SingleChildScrollView(
          child: Text(
            'BEE-Alert collects the following data:\n\n'
            '• Full name, email, phone number, and barangay address\n'
            '• GPS location when submitting reports\n'
            '• Photos and videos attached to reports\n'
            '• Report history and status updates\n\n'
            'This data is stored securely in Firebase (Google Cloud) and '
            'is accessible only to authorized Bacnotan LGU staff.\n\n'
            'Data is retained for as long as your account is active or '
            'as required by law.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: gradientStart),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PsSection extends StatelessWidget {
  final String title;
  const _PsSection({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937)),
      );
}

class _PsMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool showChevron;
  final VoidCallback onTap;

  const _PsMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: gradientStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: gradientStart, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937))),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF)))
          : null,
      trailing: showChevron
          ? Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade400)
          : null,
      onTap: onTap,
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        prefixIcon: const Icon(Icons.lock_outline,
            size: 18, color: Color(0xFF9CA3AF)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: const Color(0xFF9CA3AF),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gradientStart, width: 2),
        ),
      ),
    );
  }
}
