import 'package:flutter/material.dart';

import '../../core/theme/dalo_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/registration.dart';
import '../../services/event_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/profile_service.dart';
import '../../services/registration_service.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser appUser;

  const ProfileScreen({super.key, required this.appUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _department;
  late final TextEditingController _year;
  late final TextEditingController _gender;
  late final TextEditingController _organizations;
  final _images = ImageUploadService();
  final _profiles = ProfileService();
  String? _newImage;
  bool _removeImage = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.appUser.displayName);
    _department = TextEditingController(text: widget.appUser.department);
    _year = TextEditingController(text: widget.appUser.yearLevel);
    _gender = TextEditingController(text: widget.appUser.gender);
    _organizations = TextEditingController(text: widget.appUser.organizations);
  }

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _year.dispose();
    _gender.dispose();
    _organizations.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await _images.pickPhoto(profilePhoto: true);
      if (image != null && mounted) {
        setState(() {
          _newImage = image;
          _removeImage = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _profiles.saveProfile(
        displayName: _name.text,
        department: _department.text,
        yearLevel: _year.text,
        gender: _gender.text,
        organizations: _organizations.text,
        profileImageBase64: _newImage,
        removeProfileImage: _removeImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appUser;
    final image = _newImage ?? (_removeImage ? null : user.profileImageBase64);
    final events = EventService();
    final registrations = RegistrationService();
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ProfileAvatar(imageBase64: image, radius: 46),
                TextButton.icon(
                  onPressed: _saving ? null : _pickPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                      image == null ? 'Add profile photo' : 'Change photo'),
                ),
                Text(user.email, style: tt.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Nickname or display name', maxLength: 40),
          _field(_department, 'Department / program', maxLength: 80),
          _field(_year, 'Year level (optional)', maxLength: 40),
          _field(
            _gender,
            'Gender (optional)',
            maxLength: 60,
            hint: 'Self-describe, or leave blank',
          ),
          _field(
            _organizations,
            'Organizations and positions',
            maxLength: 240,
            hint: 'For example: Debate Society - Secretary',
            maxLines: 3,
          ),
          const SizedBox(height: 4),
          const Text(
            'These profile details are private to your signed-in account. Gender is optional and open-ended.',
            style: TextStyle(color: DaloPalette.muted, fontSize: 12),
          ),
          if (image != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _newImage = null;
                          _removeImage = true;
                        }),
                child: const Text('Remove photo'),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Save profile',
            onPressed: _save,
            isLoading: _saving,
          ),
          const SizedBox(height: 28),
          Text('Events you have held', style: tt.titleLarge),
          const SizedBox(height: 8),
          StreamBuilder<List<Event>>(
            stream: events.hostedEventsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return _historyMessage('Could not load hosted events.');
              if (!snapshot.hasData)
                return _historyMessage('Loading hosted events…');
              final items = snapshot.data!;
              if (items.isEmpty)
                return _historyMessage('No events hosted yet.');
              return Column(
                  children: items
                      .map((event) => _EventHistoryTile(event: event))
                      .toList());
            },
          ),
          const SizedBox(height: 20),
          Text('Events you have attended or joined', style: tt.titleLarge),
          const SizedBox(height: 8),
          StreamBuilder<List<Registration>>(
            stream: registrations.studentRegistrationsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return _historyMessage('Could not load your event history.');
              if (!snapshot.hasData)
                return _historyMessage('Loading your event history…');
              final items = snapshot.data!;
              if (items.isEmpty)
                return _historyMessage('No events joined yet.');
              return Column(
                children: items
                    .map((registration) => FutureBuilder<Event?>(
                          future: events.getEvent(registration.eventId),
                          builder: (context, eventSnapshot) {
                            final event = eventSnapshot.data;
                            if (event == null) return const SizedBox.shrink();
                            return _EventHistoryTile(
                              event: event,
                              status: registration.isCheckedIn
                                  ? 'Checked in'
                                  : 'Registered',
                            );
                          },
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLength = 120,
    String? hint,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  Widget _historyMessage(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

class _EventHistoryTile extends StatelessWidget {
  final Event event;
  final String? status;

  const _EventHistoryTile({required this.event, this.status});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Row(
            children: [
              const Icon(Icons.event_outlined, color: DaloPalette.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(
                        '${event.location} · ${event.date.day}/${event.date.month}/${event.date.year}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (status != null)
                Text(status!, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      );
}
