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
      children: [
        // Header
        Container(
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!embedded)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      padding: EdgeInsets.zero,
                    ),
                  if (!embedded) const SizedBox(height: 4),
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
                    municipality,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Emergency hotline strip
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚨',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text('Emergency Hotlines: ',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse('tel:911');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: const Text('911',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
              ),
              const Text('  |  ',
                  style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse('tel:09171234567');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: const Text('0917-123-4567',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),

        // Alert list
        Expanded(
          child: StreamBuilder<List<AlertModel>>(
            stream: alertService.getAlerts(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: gradientStart));
              }
              final alerts = snap.data ?? [];
              if (alerts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.notifications_none_outlined,
                          size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No alerts at this time',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                );
              }

              // Split into emergency and announcements
              final emergencies =
                  alerts.where((a) => a.type == 'emergency').toList();
              final announcements =
                  alerts.where((a) => a.type != 'emergency').toList();

              return ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  if (emergencies.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Emergency Alerts',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                    ),
                    ...emergencies.map((a) => _AlertCard(alert: a)),
                  ],
                  if (announcements.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Community Announcements',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                    ),
                    ...announcements.map((a) => _AlertCard(alert: a)),
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

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  Color get _typeColor =>
      alert.type == 'emergency' ? Colors.red : const Color(0xFF3B82F6);

  Color get _priorityColor {
    switch (alert.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return colorPending;
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy – h:mm a').format(alert.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.type == 'emergency'
                        ? '🚨 Emergency'
                        : '📢 Announcement',
                    style: TextStyle(
                      color: _typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${alert.priority[0].toUpperCase()}${alert.priority.substring(1)} Priority',
                    style: TextStyle(
                      color: _priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alert.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              alert.description,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
                if (alert.type == 'emergency' &&
                    alert.actionLink != null)
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.parse(alert.actionLink!);
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                    child: const Text('Alert Action',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
