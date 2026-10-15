import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../core/widgets/common_widgets.dart';
import 'event_detail_screen.dart';
import 'my_registrations_screen.dart';
import '../organizer/create_event_screen.dart';
import '../organizer/event_attendees_screen.dart';
import '../facilitator/facilitator_home.dart';

class StudentHome extends StatefulWidget {
  final AppUser appUser;
  const StudentHome({super.key, required this.appUser});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _EventsTab(appUser: widget.appUser),
      _MyEventsTab(appUser: widget.appUser),
      MyRegistrationsScreen(appUser: widget.appUser),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daló'),
        actions: [
          if (widget.appUser.role == UserRole.facilitator)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Facilitator tools',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FacilitatorHome(appUser: widget.appUser),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: screens[_tabIndex],
      floatingActionButton: _tabIndex < 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateEventScreen(organizer: widget.appUser),
                ),
              ),
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New event'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        selectedItemColor: const Color(0xFF111111),
        unselectedItemColor: const Color(0xFF888888),
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            activeIcon: Icon(Icons.edit_calendar),
            label: 'My events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_outlined),
            activeIcon: Icon(Icons.qr_code),
            label: 'My tickets',
          ),
        ],
      ),
    );
  }
}

class _MyEventsTab extends StatelessWidget {
  final AppUser appUser;
  const _MyEventsTab({required this.appUser});

  @override
  Widget build(BuildContext context) {
    final service = EventService();
    final tt = Theme.of(context).textTheme;
    return StreamBuilder<List<Event>>(
      stream: service.eventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading your events…');
        }
        if (snapshot.hasError) {
          return const EmptyState(
            message: 'Could not load your events. Check your connection.',
            icon: Icons.wifi_off_outlined,
          );
        }
        final events = (snapshot.data ?? [])
            .where((event) => event.organizerUid == appUser.uid)
            .toList();
        if (events.isEmpty) {
          return const EmptyState(
            message:
                'You have not created an event yet. Tap New event to start.',
            icon: Icons.event_note_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];
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
                  Row(children: [
                    Expanded(child: Text(event.title, style: tt.titleMedium)),
                    event.isOpen
                        ? const StatusBadge.open()
                        : const StatusBadge.full(),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                      '${event.date.day}/${event.date.month}/${event.date.year} · ${event.time}',
                      style: tt.bodySmall),
                  Text(event.location, style: tt.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                      '${event.registeredCount}/${event.capacity} registered · Tap to manage',
                      style: tt.labelSmall),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EventsTab extends StatefulWidget {
  final AppUser appUser;
  const _EventsTab({required this.appUser});

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  final _eventService = EventService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search events…',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                'Hello, ${widget.appUser.displayName.split(' ').first}',
                style: tt.bodyMedium?.copyWith(color: const Color(0xFF888888)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Event>>(
            stream: _eventService.eventsStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'Loading events…');
              }
              if (snap.hasError) {
                return EmptyState(
                  message: 'Could not load events. Check your connection.',
                  icon: Icons.wifi_off_outlined,
                );
              }
              var events = snap.data ?? [];
              if (_search.isNotEmpty) {
                events = events
                    .where((e) =>
                        e.title.toLowerCase().contains(_search) ||
                        e.location.toLowerCase().contains(_search))
                    .toList();
              }
              if (events.isEmpty) {
                return const EmptyState(
                  message: 'No events found.',
                  icon: Icons.event_busy_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _EventCard(event: events[i], appUser: widget.appUser),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final AppUser appUser;

  const _EventCard({required this.event, required this.appUser});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isOpen = event.isOpen;

    return SketchCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event, appUser: appUser),
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
              const SizedBox(width: 8),
              isOpen ? const StatusBadge.open() : const StatusBadge.full(),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: _formatDate(event.date),
          ),
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.access_time_outlined, text: event.time),
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.place_outlined, text: event.location),
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
                    color: isOpen
                        ? const Color(0xFF111111)
                        : const Color(0xFF888888),
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
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${_weekday(d.weekday)}, ${d.day} ${_month(d.month)} ${d.year}';

  String _weekday(int w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  String _month(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF888888)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
