import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/registration_service.dart';
import '../../core/widgets/common_widgets.dart';

class ManualCheckinScreen extends StatefulWidget {
  final Event event;
  const ManualCheckinScreen({super.key, required this.event});

  @override
  State<ManualCheckinScreen> createState() => _ManualCheckinScreenState();
}

class _ManualCheckinScreenState extends State<ManualCheckinScreen> {
  final _regService = RegistrationService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Manual check-in')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              widget.event.title,
              style: tt.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search attendee by name…',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Registration>>(
              stream: _regService.eventRegistrationsStream(widget.event.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Loading attendees…');
                }
                if (snap.hasError) {
                  return const EmptyState(
                    message: 'Could not load attendees.',
                    icon: Icons.wifi_off_outlined,
                  );
                }
                var regs = snap.data ?? [];
                if (_search.isNotEmpty) {
                  regs = regs
                      .where((r) =>
                          r.studentName.toLowerCase().contains(_search))
                      .toList();
                }
                if (regs.isEmpty) {
                  return EmptyState(
                    message: _search.isEmpty
                        ? 'No registrations for this event.'
                        : 'No attendee matches "$_search".',
                    icon: Icons.people_outline,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: regs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _AttendeeRow(
                    reg: regs[i],
                    eventId: widget.event.id,
                    regService: _regService,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatefulWidget {
  final Registration reg;
  final String eventId;
  final RegistrationService regService;

  const _AttendeeRow({
    required this.reg,
    required this.eventId,
    required this.regService,
  });

  @override
  State<_AttendeeRow> createState() => _AttendeeRowState();
}

class _AttendeeRowState extends State<_AttendeeRow> {
  bool _loading = false;

  Future<void> _checkIn() async {
    if (widget.reg.isCheckedIn || _loading) return;
    setState(() => _loading = true);

    final result = await widget.regService.checkInByRegistrationId(
      registrationId: widget.reg.id,
      expectedEventId: widget.eventId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success ? const Color(0xFF1A3A2A) : const Color(0xFF3A1A1A),
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.reg;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reg.studentName,
                  style: tt.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(reg.studentEmail, style: tt.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (reg.isCheckedIn)
            const StatusBadge.checkedIn()
          else if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF111111),
              ),
            )
          else
            GestureDetector(
              onTap: _checkIn,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Check in',
                  style: tt.labelSmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
