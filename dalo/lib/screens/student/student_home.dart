import 'package:flutter/material.dart';

import '../../core/theme/dalo_theme.dart';
import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/dalo_brand_mark.dart';
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
        titleSpacing: 20,
        title: const DaloBrandMark(width: 98),
        actions: [
          if (widget.appUser.role == UserRole.facilitator)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Facilitator tools',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FacilitatorHome(appUser: widget.appUser),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => AuthService().signOut(),
          ),
          const SizedBox(width: 8),
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
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create event'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Hosting',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number_rounded),
            label: 'Tickets',
          ),
        ],
      ),
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
  late final Stream<List<Event>> _eventsStream = _eventService.eventsStream();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: _eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Finding events…');
        }
        if (snapshot.hasError) {
          return const EmptyState(
            message:
                'Could not load events. Check your connection and try again.',
            icon: Icons.wifi_off_outlined,
          );
        }

        var events = snapshot.data ?? [];
        if (_search.isNotEmpty) {
          events = events
              .where((event) =>
                  event.title.toLowerCase().contains(_search) ||
                  event.location.toLowerCase().contains(_search))
              .toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          itemCount: events.isEmpty ? 2 : events.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _DiscoverHeader(
                firstName: widget.appUser.displayName.split(' ').first,
                onSearchChanged: (value) =>
                    setState(() => _search = value.trim().toLowerCase()),
                resultCount: events.length,
              );
            }
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 22),
                child: EmptyState(
                  message:
                      'No events match that search. Try another title or location.',
                  icon: Icons.event_busy_outlined,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child:
                  _EventCard(event: events[index - 1], appUser: widget.appUser),
            );
          },
        );
      },
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  final String firstName;
  final ValueChanged<String> onSearchChanged;
  final int resultCount;

  const _DiscoverHeader({
    required this.firstName,
    required this.onSearchChanged,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hi, $firstName',
              style: textTheme.labelLarge?.copyWith(color: DaloPalette.accent)),
          const SizedBox(height: 8),
          Text('Make plans\nthat matter.', style: textTheme.displayMedium),
          const SizedBox(height: 9),
          Text(
            'Find the next good thing happening on campus.',
            style: textTheme.bodyMedium?.copyWith(color: DaloPalette.muted),
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search events or places',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text('Coming up', style: textTheme.titleLarge),
              const Spacer(),
              Text('$resultCount ${resultCount == 1 ? 'event' : 'events'}',
                  style: textTheme.labelMedium),
            ],
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
    final textTheme = Theme.of(context).textTheme;
    return StreamBuilder<List<Event>>(
      stream: service.eventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading your hosted events…');
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
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            Text('Your events', style: textTheme.displayMedium),
            const SizedBox(height: 8),
            Text('Keep an eye on your guest list and check-ins.',
                style:
                    textTheme.bodyMedium?.copyWith(color: DaloPalette.muted)),
            const SizedBox(height: 24),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: EmptyState(
                  message:
                      'You have not created an event yet. Start one when you are ready.',
                  icon: Icons.event_note_outlined,
                ),
              )
            else
              ...events.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventAttendeesScreen(event: event),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 58,
                            decoration: BoxDecoration(
                              color: DaloPalette.accentSoft,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.event_rounded,
                                color: DaloPalette.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: textTheme.titleMedium),
                                const SizedBox(height: 5),
                                Text(
                                  '${_formatDate(event.date)} · ${event.time}',
                                  style: textTheme.bodySmall,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                    '${event.registeredCount} of ${event.capacity} guests',
                                    style: textTheme.labelSmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          event.isOpen
                              ? const StatusBadge.open()
                              : const StatusBadge.full(),
                        ],
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final AppUser appUser;

  const _EventCard({required this.event, required this.appUser});

  static const _coverColors = [
    Color(0xFFFFE7DB),
    Color(0xFFE5EBE3),
    Color(0xFFE7EAF4),
    Color(0xFFF4E9C9),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOpen = event.isOpen;
    final coverColor =
        _coverColors[event.title.hashCode.abs() % _coverColors.length];

    return Material(
      color: DaloPalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event, appUser: appUser),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DaloPalette.outline),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 18,
                  offset: Offset(0, 7)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: coverColor),
                    Positioned(
                      top: -32,
                      right: 32,
                      child: Container(
                        width: 126,
                        height: 126,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.38),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: -45,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: DaloPalette.accent.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(_month(event.date.month).toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: DaloPalette.accent,
                                  letterSpacing: 1,
                                )),
                            Text('${event.date.day}',
                                style: textTheme.titleLarge
                                    ?.copyWith(fontSize: 22)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 18,
                      child: Row(
                        children: [
                          const Icon(Icons.local_activity_outlined,
                              size: 16, color: DaloPalette.ink),
                          const SizedBox(width: 6),
                          Text('CAMPUS MOMENT',
                              style: textTheme.labelSmall?.copyWith(
                                color: DaloPalette.ink,
                                letterSpacing: 1.1,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child:
                                Text(event.title, style: textTheme.titleLarge)),
                        const SizedBox(width: 8),
                        isOpen
                            ? const StatusBadge.open()
                            : const StatusBadge.full(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _EventInfo(icon: Icons.schedule_rounded, text: event.time),
                    const SizedBox(height: 6),
                    _EventInfo(
                        icon: Icons.place_outlined, text: event.location),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: event.capacity > 0
                                  ? (event.registeredCount / event.capacity)
                                      .clamp(0.0, 1.0)
                                      .toDouble()
                                  : 0,
                              backgroundColor: const Color(0xFFF0EEEA),
                              color: isOpen
                                  ? DaloPalette.accent
                                  : DaloPalette.muted,
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${event.registeredCount}/${event.capacity} spots',
                            style: textTheme.labelSmall),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 17, color: DaloPalette.muted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EventInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DaloPalette.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}';

String _weekday(int weekday) =>
    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

String _month(int month) => [
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
    ][month - 1];
