import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../../widgets/report_card.dart';

class MyReportsScreen extends StatefulWidget {
  final bool embedded;
  const MyReportsScreen({super.key, this.embedded = false});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ReportService _reportService = ReportService();
  final _searchController = TextEditingController();
  String _filterStatus = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    statusPending,
    statusOngoing,
    statusCompleted,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReportModel> _applyFilter(List<ReportModel> all) {
    var list = all;
    if (_filterStatus != 'All') {
      list = list.where((r) => r.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        return r.category.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.reportReference.toLowerCase().contains(q) ||
            r.location.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  String _filterLabel(String f) {
    if (f == statusOngoing) return 'InProgress';
    if (f == statusCompleted) return 'Resolved';
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final body = Column(
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
                    'My Reports',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track the status of your submitted reports.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Search bar ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search reports...',
              hintStyle:
                  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  color: Color(0xFF9CA3AF), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Color(0xFF9CA3AF), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // ── Report list with count tabs ───────────────────
        Expanded(
          child: StreamBuilder<List<ReportModel>>(
            stream: _reportService.getUserReports(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: gradientStart));
              }
              final all = snap.data ?? [];

              // Count per filter
              Map<String, int> counts = {
                'All': all.length,
                statusPending: all
                    .where((r) => r.status == statusPending)
                    .length,
                statusOngoing: all
                    .where((r) => r.status == statusOngoing)
                    .length,
                statusCompleted: all
                    .where((r) => r.status == statusCompleted)
                    .length,
              };

              final filtered = _applyFilter(all);

              return Column(
                children: [
                  // Filter tabs with counts
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((f) {
                          final active = _filterStatus == f;
                          final count = counts[f] ?? 0;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _filterStatus = f),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: active
                                    ? gradientStart
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active
                                      ? gradientStart
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _filterLabel(f),
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                      fontWeight: active
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (count > 0 && f != 'All') ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.white
                                                .withValues(alpha: 0.3)
                                            : gradientStart
                                                .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: active
                                              ? Colors.white
                                              : gradientStart,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Report list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.assignment_outlined,
                                    size: 56, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _filterStatus == 'All'
                                      ? 'No reports yet'
                                      : 'No ${_filterLabel(_filterStatus)} reports',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                if (_filterStatus == 'All')
                                  const Text(
                                    'Submit your first concern report',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.only(bottom: 80),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) =>
                                ReportCard(report: filtered[i]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: body,
    );
  }
}
