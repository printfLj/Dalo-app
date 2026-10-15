import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../core/widgets/common_widgets.dart';
import 'create_event_screen.dart';
import 'event_attendees_screen.dart';

class OrganizerHome extends StatelessWidget {
  final AppUser appUser;
  const OrganizerHome({super.key, required this.appUser});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daló — Organizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateEventScreen(organizer: appUser),
          ),
        ),
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
      body: StreamBuilder<List<Event>>(
        stream: eventService.eventsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading events…');
          }
          if (snap.hasError) {
            return const EmptyState(
              message: 'Could not load events.',
              icon: Icons.wifi_off_outlined,
            );
          }
          final events = (snap.data ?? [])
              .where((e) => e.organizerUid == appUser.uid)
              .toList();

          if (events.isEmpty) {
            return EmptyState(
              message: 'No events yet.\nCreate your first event!',
              icon: Icons.event_note_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final event = events[i];
              return SketchCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventAttendeesScreen(event: event),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(event.title, style: tt.titleMedium),
                        ),
                        event.isOpen
                            ? const StatusBadge.open()
                            : const StatusBadge.full(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(event.date)} · ${event.time}',
                      style: tt.bodySmall,
                    ),
                    Text(event.location, style: tt.bodySmall),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: event.capacity > 0
                                  ? event.registeredCount / event.capacity
                                  : 0,
                              backgroundColor: const Color(0xFFEEEEEE),
                              color: const Color(0xFF111111),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${event.registeredCount}/${event.capacity}',
                          style: tt.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view attendees',
                      style: tt.labelSmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_month(d.month)} ${d.year}';

  String _month(int m) => [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ][m - 1];
}
