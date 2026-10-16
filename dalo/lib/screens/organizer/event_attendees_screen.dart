import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _deleting = false;

  Future<void> _confirmDelete(Event event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteEventConfirmationDialog(eventTitle: event.title),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _eventService.deleteEvent(event.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event and its registrations deleted.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not finish deleting the event. Try again; cleanup can resume.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

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
          if (FirebaseAuth.instance.currentUser?.uid == event.organizerUid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.045),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danger zone',
                        style: tt.titleSmall
                            ?.copyWith(color: Colors.red.shade800)),
                    const SizedBox(height: 4),
                    Text(
                        'Permanently remove this event and all attendee records.',
                        style: tt.bodySmall),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _deleting ? null : () => _confirmDelete(event),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade800),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(_deleting ? 'Deleting…' : 'Delete event'),
                    ),
                  ],
                ),
              ),
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

class _DeleteEventConfirmationDialog extends StatefulWidget {
  final String eventTitle;

  const _DeleteEventConfirmationDialog({required this.eventTitle});

  @override
  State<_DeleteEventConfirmationDialog> createState() =>
      _DeleteEventConfirmationDialogState();
}

class _DeleteEventConfirmationDialogState
    extends State<_DeleteEventConfirmationDialog> {
  final _titleController = TextEditingController();
  bool _titleMatches = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _close(bool confirmed) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(confirmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
      title: const Text('Permanently delete event?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“${widget.eventTitle}” and all its registrations and check-in records will be deleted. This cannot be undone.',
          ),
          const SizedBox(height: 16),
          Text(
            'Type the event title to enable deletion: ${widget.eventTitle}',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            autofocus: true,
            onChanged: (value) => setState(
              () => _titleMatches = value.trim() == widget.eventTitle,
            ),
            decoration: const InputDecoration(labelText: 'Event title'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _close(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _titleMatches ? () => _close(true) : null,
          child: const Text('Delete permanently'),
        ),
      ],
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
