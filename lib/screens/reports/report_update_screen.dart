import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/constants.dart';

class ReportUpdateScreen extends StatelessWidget {
  final ReportModel report;

  const ReportUpdateScreen({super.key, required this.report});

  // Map status to step index: 0 = submitted, 1 = in progress, 2 = resolved
  int get _currentStep {
    switch (report.status) {
      case statusOngoing:
        return 1;
      case statusCompleted:
        return 2;
      case 'Cancelled':
        return -1; // special case
      default:
        return 0; // Pending
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$m AM';
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Orange header ──────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                    ),
                    const Text(
                      'Report Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Timeline body ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repair Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Timeline
                  ...List.generate(steps.length, (i) {
                    return _TimelineStep(
                      step: steps[i],
                      isLast: i == steps.length - 1,
                    );
                  }),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  List<_StepData> _buildSteps() {
    final step = _currentStep;
    final isCancelled = report.status == 'Cancelled';

    if (isCancelled) {
      return [
        _StepData(
          icon: Icons.check,
          title: 'Report Submitted',
          subtitle: 'System recorded incident through citizen portal.',
          date: _formatDate(report.submittedAt),
          state: _StepState.done,
        ),
        _StepData(
          icon: Icons.cancel_outlined,
          title: 'Report Cancelled',
          subtitle: report.cancellationReason?.isNotEmpty == true
              ? report.cancellationReason!
              : 'Report was cancelled.',
          date: _formatDate(report.updatedAt),
          state: _StepState.cancelled,
        ),
      ];
    }

    return [
      _StepData(
        icon: Icons.check,
        title: 'Report Submitted',
        subtitle: 'System recorded incident through citizen portal.',
        date: _formatDate(report.submittedAt),
        state: step >= 0 ? _StepState.done : _StepState.pending,
      ),
      _StepData(
        icon: Icons.engineering,
        title: 'Work in Progress',
        subtitle: step >= 1
            ? (report.lastUpdate?.isNotEmpty == true
                ? report.lastUpdate!
                : 'Your report is being reviewed and actioned.')
            : 'Awaiting assignment to municipal team.',
        date: step >= 1 ? _formatDate(report.updatedAt) : null,
        state: step == 1
            ? _StepState.active
            : step > 1
                ? _StepState.done
                : _StepState.pending,
      ),
      _StepData(
        icon: Icons.task_alt,
        title: 'Resolved',
        subtitle: step >= 2
            ? 'Issue has been resolved. Final cleanup and photo verification.'
            : 'Final cleanup and photo verification.',
        date: step >= 2 ? _formatDate(report.updatedAt) : null,
        state: step >= 2 ? _StepState.done : _StepState.pending,
      ),
    ];
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

enum _StepState { done, active, pending, cancelled }

class _StepData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? date;
  final _StepState state;

  const _StepData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.date,
    required this.state,
  });
}

// ── Timeline step widget ─────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final _StepData step;
  final bool isLast;

  const _TimelineStep({required this.step, required this.isLast});

  Color get _circleColor {
    switch (step.state) {
      case _StepState.done:
        return gradientStart;
      case _StepState.active:
        return gradientStart;
      case _StepState.cancelled:
        return Colors.red;
      case _StepState.pending:
        return const Color(0xFFD1D5DB);
    }
  }

  Color get _lineColor {
    switch (step.state) {
      case _StepState.done:
      case _StepState.active:
        return gradientStart;
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = step.state == _StepState.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: circle + vertical line ──────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circle icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    color: isPending
                        ? const Color(0xFF9CA3AF)
                        : Colors.white,
                    size: 18,
                  ),
                ),
                // Vertical line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _lineColor,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ── Right: text ───────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + date on same row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isPending
                                ? const Color(0xFF9CA3AF)
                                : step.state == _StepState.cancelled
                                    ? Colors.red
                                    : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (step.date != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          step.date!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPending
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
