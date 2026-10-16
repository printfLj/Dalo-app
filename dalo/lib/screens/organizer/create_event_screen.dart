import 'package:flutter/material.dart';
import 'dart:convert';

import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../../services/image_upload_service.dart';

class CreateEventScreen extends StatefulWidget {
  final AppUser organizer;
  const CreateEventScreen({super.key, required this.organizer});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _saving = false;
  String? _error;
  String? _coverImage;
  final _images = ImageUploadService();

  final _eventService = EventService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF111111),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF111111),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickCover() async {
    try {
      final image = await _images.pickPhoto(profilePhoto: false);
      if (image != null && mounted) setState(() => _coverImage = image);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  String _timeString() {
    if (_selectedTime == null) return '';
    final h = _selectedTime!.hourOfPeriod.toString().padLeft(2, '0');
    final m = _selectedTime!.minute.toString().padLeft(2, '0');
    final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      setState(() => _error = 'Please pick a date.');
      return;
    }
    if (_selectedTime == null) {
      setState(() => _error = 'Please pick a time.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final event = Event(
        id: '',
        title: _titleCtrl.text.trim(),
        date: _selectedDate!,
        time: _timeString(),
        location: _locationCtrl.text.trim(),
        capacity: int.parse(_capacityCtrl.text.trim()),
        registeredCount: 0,
        organizerUid: widget.organizer.uid,
        organizerName: widget.organizer.displayName,
        createdAt: DateTime.now(),
        coverImageBase64: _coverImage,
      );
      await _eventService.createEvent(event);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Could not create event. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create event', style: tt.headlineLarge),
              const SizedBox(height: 28),
              InkWell(
                onTap: _saving ? null : _pickCover,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 170,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9E1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _coverImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36),
                            SizedBox(height: 8),
                            Text('Add an event cover photo (optional)'),
                          ],
                        )
                      : Image.memory(base64Decode(_coverImage!),
                          fit: BoxFit.cover),
                ),
              ),
              if (_coverImage != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _pickCover,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Change cover'),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Event title'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a title.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      hintText: _selectedDate == null
                          ? 'Select a date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    controller: TextEditingController(
                      text: _selectedDate == null
                          ? ''
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                    validator: (_) =>
                        _selectedDate == null ? 'Pick a date.' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Time picker
              GestureDetector(
                onTap: _pickTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Time',
                      hintText: _selectedTime == null
                          ? 'Select a time'
                          : _timeString(),
                      suffixIcon: const Icon(Icons.access_time_outlined),
                    ),
                    controller: TextEditingController(
                      text: _selectedTime == null ? '' : _timeString(),
                    ),
                    validator: (_) =>
                        _selectedTime == null ? 'Pick a time.' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                maxLength: 160,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a location.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration:
                    const InputDecoration(labelText: 'Maximum capacity'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter capacity.';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Enter a positive number.';
                  if (n > Event.maximumCapacity) {
                    return 'Capacity cannot exceed ${Event.maximumCapacity}.';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Create event',
                onPressed: _save,
                isLoading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
