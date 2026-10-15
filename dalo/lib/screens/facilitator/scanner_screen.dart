import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/event.dart';
import '../../services/registration_service.dart';

enum _ScanState { scanning, processing, result }

class ScannerScreen extends StatefulWidget {
  final Event event;
  const ScannerScreen({super.key, required this.event});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final _regService = RegistrationService();
  final _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  _ScanState _state = _ScanState.scanning;
  CheckInResult? _lastResult;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state != _ScanState.scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final token = barcode!.rawValue!;
    setState(() => _state = _ScanState.processing);
    await _controller.stop();

    HapticFeedback.mediumImpact();

    final result = await _regService.checkInByQrToken(
      qrToken: token,
      expectedEventId: widget.event.id,
    );

    if (mounted) {
      setState(() {
        _lastResult = result;
        _state = _ScanState.result;
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.scanning;
      _lastResult = null;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(event.title,
            style: tt.titleMedium?.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flashlight_off : Icons.flashlight_on,
              color: Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view (always rendered so permissions are requested)
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return _CameraError(error: error);
            },
          ),
          // Viewfinder overlay
          if (_state == _ScanState.scanning) _ScanOverlay(event: event),
          // Processing spinner
          if (_state == _ScanState.processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Checking in…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          // Result overlay
          if (_state == _ScanState.result && _lastResult != null)
            _ResultOverlay(
              result: _lastResult!,
              event: event,
              onDismiss: _reset,
            ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final Event event;
  const _ScanOverlay({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Corner accents
                _Corner(top: true, left: true),
                _Corner(top: true, left: false),
                _Corner(top: false, left: true),
                _Corner(top: false, left: false),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Point camera at QR code',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          event.title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  final CheckInResult result;
  final Event event;
  final VoidCallback onDismiss;

  const _ResultOverlay({
    required this.result,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.success;
    final bgColor = isSuccess
        ? const Color(0xFF1A3A2A)
        : const Color(0xFF3A1A1A);
    final iconColor = isSuccess ? Colors.greenAccent : Colors.redAccent;
    final icon = isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      color: bgColor.withOpacity(0.97),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: iconColor),
              const SizedBox(height: 20),
              Text(
                result.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (result.studentName != null) ...[
                const SizedBox(height: 12),
                Text(
                  result.studentName!,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Scan next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message =
            'Camera permission denied.\nPlease grant camera access in Settings → Apps → Daló → Permissions.';
        break;
      case MobileScannerErrorCode.unsupported:
        message = 'Camera is not available on this device.';
        break;
      default:
        message = 'Camera error: ${error.errorDetails?.message ?? 'unknown'}';
    }
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
