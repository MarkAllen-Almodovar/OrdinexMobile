import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import '../../utils/constants.dart';

class AlertsScreen extends StatelessWidget {
  final bool embedded;
  const AlertsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final alertService = AlertService();

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gradient Header ──────────────────────────────────
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
                  if (!embedded)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                    ),
                  if (!embedded) const SizedBox(height: 8),
                  const Text(
                    'Alerts & Announcements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stay informed about emergency alerts and community updates.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<AlertModel>>(
            stream: alertService.getAlerts(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: gradientStart));
              }
              final alerts = snap.data ?? [];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Emergency Hotline Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emergency_outlined,
                                color: Colors.red.shade700, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Emergency Hotline',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For immediate assistance, call',
                          style: TextStyle(
                              color: Colors.red.shade400, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _HotlineButton(
                              label: '911',
                              tel: 'tel:911',
                            ),
                            const SizedBox(width: 10),
                            _HotlineButton(
                              label: '0917-123-4567',
                              tel: 'tel:09171234567',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (alerts.isEmpty) ...[
                    const SizedBox(height: 60),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              size: 56, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No alerts at this time',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Recent Alerts (emergency)
                    if (alerts.any((a) => a.type == 'emergency')) ...[
                      const _SectionHeader(title: 'Recent Alerts'),
                      ...alerts
                          .where((a) => a.type == 'emergency')
                          .map((a) => _AlertCard(alert: a)),
                    ],

                    // Community Announcements
                    if (alerts.any((a) => a.type != 'emergency')) ...[
                      const _SectionHeader(title: 'Community Announcements'),
                      ...alerts
                          .where((a) => a.type != 'emergency')
                          .map((a) => _AnnouncementCard(alert: a)),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: body,
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

// ── Hotline Button ───────────────────────────────────────────────────────────

class _HotlineButton extends StatelessWidget {
  final String label;
  final String tel;
  const _HotlineButton({required this.label, required this.tel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(tel);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Emergency Alert Card ─────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  Color get _priorityColor {
    switch (alert.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return colorPending;
      default:
        return colorCompleted;
    }
  }

  String get _priorityLabel {
    switch (alert.priority) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      default:
        return 'Low Priority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d').format(alert.createdAt);
    final time = DateFormat('HH:mm').format(alert.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: Colors.red.shade400, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                _Badge(
                  label: '🚨 Emergency',
                  bg: Colors.orange.shade50,
                  fg: gradientStart,
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: _priorityLabel,
                  bg: _priorityColor.withValues(alpha: 0.1),
                  fg: _priorityColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              alert.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(date,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_outlined,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(time,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Spacer(),
                if (alert.actionLink != null)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(alert.actionLink!);
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gradientStart.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '→ Get Alert',
                        style: TextStyle(
                          color: gradientStart,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Announcement Card ────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final AlertModel alert;
  const _AnnouncementCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final posted = DateFormat('MMMM d, yyyy').format(alert.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: colorOngoing, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: gradientStart.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.campaign_outlined,
              color: gradientStart, size: 20),
        ),
        title: Text(
          alert.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              alert.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            Text(
              '📅 Posted on $posted',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
