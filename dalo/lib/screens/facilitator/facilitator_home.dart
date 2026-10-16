import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/dalo_brand_mark.dart';
import 'scanner_screen.dart';
import 'manual_checkin_screen.dart';

class FacilitatorHome extends StatelessWidget {
  final AppUser appUser;
  const FacilitatorHome({super.key, required this.appUser});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DaloBrandMark(width: 98),
            SizedBox(width: 10),
            Text('Facilitator'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => AuthService().signOut(),
          ),
        ],
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
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return const EmptyState(
              message: 'No events available.',
              icon: Icons.event_busy_outlined,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Select an event to manage attendance',
                  style: tt.bodySmall,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final event = events[i];
                    return AppCard(
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
                          const SizedBox(height: 6),
                          Text(
                            '${_formatDate(event.date)} · ${event.time} · ${event.location}',
                            style: tt.bodySmall,
                          ),
                          Text(
                            '${event.registeredCount}/${event.capacity} registered',
                            style: tt.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScannerScreen(event: event),
                                    ),
                                  ),
                                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                                  label: const Text('Scan QR'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ManualCheckinScreen(event: event),
                                    ),
                                  ),
                                  icon: const Icon(Icons.people_outline, size: 18),
                                  label: const Text('Manual'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
