import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/registration_service.dart';
import '../../core/widgets/common_widgets.dart';
import 'qr_ticket_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final AppUser appUser;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.appUser,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _regService = RegistrationService();
  bool _registering = false;
  String? _error;
  Registration? _existingReg;
  bool _checkingExisting = true;

  @override
  void initState() {
    super.initState();
    _checkExistingRegistration();
  }

  Future<void> _checkExistingRegistration() async {
    final reg = await _regService.findStudentRegistration(
      eventId: widget.event.id,
      studentUid: widget.appUser.uid,
    );
    if (mounted) {
      setState(() {
        _existingReg = reg;
        _checkingExisting = false;
      });
    }
  }

  Future<void> _register() async {
    if (_registering) return;
    setState(() { _registering = true; _error = null; });
    try {
      final reg = await _regService.registerForEvent(
        eventId: widget.event.id,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QrTicketScreen(
              registration: reg,
              event: widget.event,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('capacity') || raw.contains('resource-exhausted') || raw.contains('full')) {
      return 'This event is now full. Registration is closed.';
    }
    if (raw.contains('already-exists') || raw.contains('already registered')) {
      return 'You are already registered for this event.';
    }
    if (raw.contains('network') || raw.contains('unavailable')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: tt.headlineLarge),
            const SizedBox(height: 20),
            SketchCard(
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(event.date),
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value: event.time,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Location',
                    value: event.location,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.people_outline,
                    label: 'Capacity',
                    value: '${event.registeredCount} / ${event.capacity} registered',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: event.capacity > 0
                    ? event.registeredCount / event.capacity
                    : 0,
                backgroundColor: const Color(0xFFEEEEEE),
                color: event.isOpen
                    ? const Color(0xFF111111)
                    : const Color(0xFF888888),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              event.isOpen
                  ? '${event.spotsLeft} spot${event.spotsLeft == 1 ? '' : 's'} remaining'
                  : 'Registration closed — event is full',
              style: tt.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 28),
            if (_checkingExisting)
              const LoadingView(message: 'Checking registration status…')
            else if (_existingReg != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                    ),
                    child: Text(
                      'You are registered for this event.',
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'View my QR ticket',
                    icon: Icons.qr_code,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrTicketScreen(
                          registration: _existingReg!,
                          event: event,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (!event.isOpen)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Text(
                  'Registration is closed. This event is full.',
                  style: tt.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else
              PrimaryButton(
                label: 'Register for this event',
                onPressed: _register,
                isLoading: _registering,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${_weekday(d.weekday)}, ${d.day} ${_month(d.month)} ${d.year}';

  String _weekday(int w) =>
      ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][w - 1];

  String _month(int m) => [
        'January','February','March','April','May','June',
        'July','August','September','October','November','December'
      ][m - 1];
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF888888)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tt.labelSmall),
            const SizedBox(height: 2),
            Text(value, style: tt.bodyMedium),
          ],
        ),
      ],
    );
  }
}
