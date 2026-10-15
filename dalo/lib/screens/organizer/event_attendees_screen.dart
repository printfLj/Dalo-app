import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../facilitator/scanner_screen.dart';
import '../facilitator/manual_checkin_screen.dart';

class EventAttendeesScreen extends StatefulWidget {
  final Event event;
  const EventAttendeesScreen({super.key, required this.event});

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  final _eventService = EventService();
  final _regService = RegistrationService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ScannerScreen(event: event))),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ManualCheckinScreen(event: event))),
                icon: const Icon(Icons.person_search_outlined),
                label: const Text('Manual check-in'),
              )),
            ]),
          ),
          StreamBuilder<Event?>(
            stream: _eventService.eventStream(event.id),
            builder: (context, snapshot) {
              final currentEvent = snapshot.data ?? event;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${currentEvent.registeredCount}',
                              style: tt.headlineMedium,
                            ),
                            Text(' / ${currentEvent.capacity}',
                                style: tt.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              currentEvent.isOpen ? 'Open' : 'Full',
                              style: tt.headlineMedium,
                            ),
                            Text('registration', style: tt.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search attendees by name…',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Registration>>(
              stream: _regService.eventRegistrationsStream(event.id),
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
                      .where(
                          (r) => r.studentName.toLowerCase().contains(_search))
                      .toList();
                }
                if (regs.isEmpty) {
                  return EmptyState(
                    message: _search.isEmpty
                        ? 'No registrations yet.'
                        : 'No attendee matches "$_search".',
                    icon: Icons.people_outline,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: regs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _AttendeeRow(reg: regs[i], eventId: event.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  final Registration reg;
  final String eventId;
  const _AttendeeRow({required this.reg, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reg.studentName,
                    style:
                        tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(reg.studentEmail, style: tt.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          reg.isCheckedIn
              ? const StatusBadge.checkedIn()
              : const StatusBadge(
                  label: 'Registered',
                  color: Color(0xFFF0F0F0),
                  textColor: Color(0xFF555555),
                ),
        ],
      ),
    );
  }
}
