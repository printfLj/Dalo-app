import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/registration.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../core/widgets/common_widgets.dart';
import 'qr_ticket_screen.dart';

class MyRegistrationsScreen extends StatelessWidget {
  final AppUser appUser;
  const MyRegistrationsScreen({super.key, required this.appUser});

  @override
  Widget build(BuildContext context) {
    final regService = RegistrationService();
    final eventService = EventService();

    return StreamBuilder<List<Registration>>(
      stream: regService.studentRegistrationsStream(appUser.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading tickets…');
        }
        if (snap.hasError) {
          return const EmptyState(
            message: 'Could not load registrations. Check your connection.',
            icon: Icons.wifi_off_outlined,
          );
        }
        final regs = snap.data ?? [];
        if (regs.isEmpty) {
          return const EmptyState(
            message: 'No registrations yet.\nBrowse events and register!',
            icon: Icons.confirmation_number_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: regs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final reg = regs[i];
            return FutureBuilder(
              future: eventService.getEvent(reg.eventId),
              builder: (context, eventSnap) {
                final event = eventSnap.data;
                final tt = Theme.of(context).textTheme;
                return AppCard(
                  onTap: event == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrTicketScreen(
                                registration: reg,
                                event: event,
                              ),
                            ),
                          ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_2,
                        size: 40,
                        color: Color(0xFF111111),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event?.title ?? 'Loading…',
                              style: tt.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (event != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(event.date)} · ${event.time}',
                                style: tt.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      reg.isCheckedIn
                          ? const StatusBadge.checkedIn()
                          : const StatusBadge.open(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_month(d.month)} ${d.year}';

  String _month(int m) => [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ][m - 1];
}
