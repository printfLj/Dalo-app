import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/event.dart';
import '../../models/registration.dart';
import '../../core/widgets/common_widgets.dart';

class QrTicketScreen extends StatefulWidget {
  final Registration registration;
  final Event event;

  const QrTicketScreen({
    super.key,
    required this.registration,
    required this.event,
  });

  @override
  State<QrTicketScreen> createState() => _QrTicketScreenState();
}

class _QrTicketScreenState extends State<QrTicketScreen> {
  final _qrKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareQr() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // Render the QR widget to an image
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dalo_qr_${widget.registration.id}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text:
            'My Daló ticket for ${widget.event.title} on ${_formatDate(widget.event.date)}.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share QR code.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.registration;
    final event = widget.event;
    final tt = Theme.of(context).textTheme;
    final isCheckedIn = reg.isCheckedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('My ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isCheckedIn) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EDDA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF155724), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance recorded',
                      style: tt.bodyMedium?.copyWith(
                        color: const Color(0xFF155724),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(event.title, style: tt.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(event.date)} · ${event.time}',
              style: tt.bodySmall,
              textAlign: TextAlign.center,
            ),
            Text(
              event.location,
              style: tt.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF111111), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isCheckedIn
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                        child: QrImageView(
                          data: reg.qrToken,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF111111),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF111111),
                          ),
                        ),
                      )
                    : QrImageView(
                        data: reg.qrToken,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF111111),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF111111),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (isCheckedIn)
              Text(
                'This QR code has been used.',
                style: tt.bodySmall?.copyWith(color: const Color(0xFF888888)),
              )
            else
              Text(
                'Show this QR at the event entrance.',
                style: tt.bodySmall,
              ),
            const SizedBox(height: 28),
            if (!isCheckedIn)
              PrimaryButton(
                label: 'Share QR code',
                icon: Icons.share_outlined,
                onPressed: _shareQr,
                isLoading: _sharing,
              ),
          ],
        ),
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
