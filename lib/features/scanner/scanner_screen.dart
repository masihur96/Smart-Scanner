import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_qr/features/history/history_screen.dart';
import 'package:smart_qr/features/scanner/result_screen.dart';
import 'package:smart_qr/l10n/app_localizations.dart';
import 'package:smart_qr/main.dart';
import 'package:smart_qr/models/scan_model.dart';
import 'package:smart_qr/services/database_service.dart';
import 'package:smart_qr/services/permission_service.dart';
import 'package:vibration/vibration.dart';

part 'scanning_animation.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );
  final PermissionService _permissionService = PermissionService();
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _checkPermission();
        break;
      case AppLifecycleState.inactive:
        return;
    }
  }

  Future<void> _checkPermission() async {
    final granted = await _permissionService.requestCameraPermission();
    setState(() {
      _isPermissionGranted = granted;
    });
    if (granted) {
      controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_isPermissionGranted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n?.cameraPermissionRequired??""),
              ElevatedButton(
                onPressed: _checkPermission,
                child: Text(l10n?.grantPermission??""),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                debugPrint('Barcode found! ${barcode.rawValue}');

                
                Vibration.vibrate(duration: 50);
                
                controller.stop(); // Stop scanning after detection
                _handleScan(barcode);
                break; // Only handle the first barcode
              }
            },
          ),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Scanning Animation
          _ScanningAnimation(
            isScanning: _isPermissionGranted && controller.value.isRunning,
          ),
          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  color: Colors.white,
                  icon: ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, state, child) {
                      if (!state.isInitialized || !state.isRunning) {
                        return const Icon(Icons.flash_off);
                      }

                      switch (state.torchState) {
                        case TorchState.auto:
                          return const Icon(Icons.flash_auto);
                        case TorchState.off:
                          return const Icon(Icons.flash_off);
                        case TorchState.on:
                          return const Icon(Icons.flash_on);
                        case TorchState.unavailable:
                          return const Icon(Icons.flash_off, color: Colors.grey);
                      }
                    },
                  ),
                  iconSize: 32.0,
                  onPressed: () => controller.toggleTorch(),
                ),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.image),
                  iconSize: 32.0,
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {

                      await controller.stop();
                      
                      final BarcodeCapture? barcodes = await controller.analyzeImage(
                        image.path,
                      );
                      
                      if (!mounted) return;

                      if (barcodes != null && barcodes.barcodes.isNotEmpty) {
                        final Barcode barcode = barcodes.barcodes.first;
                        _handleScan(barcode);
                      } else {
                        controller.start();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No QR code found in the image.'), // TODO: Add to l10n if needed
                          ),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  color: Colors.white,
                  icon: ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, state, child) {
                      if (!state.isInitialized || !state.isRunning) {
                        return const Icon(Icons.cameraswitch);
                      }
                      return Icon(
                        state.cameraDirection == CameraFacing.front
                            ? Icons.camera_front
                            : Icons.camera_rear,
                      );
                    },
                  ),
                  iconSize: 32.0,
                  onPressed: () => controller.switchCamera(),
                ),
              ],
            ),
          ),
          // History Button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.history, color: Colors.white, size: 32),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
          ),
          // Language Switcher
          Positioned(
            top: 50,
            left: 20,
            child: PopupMenuButton<Locale>(
              icon: const Icon(Icons.language, color: Colors.white, size: 32),
              onSelected: (Locale locale) {
                MyApp.setLocale(context, locale);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                const PopupMenuItem<Locale>(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                const PopupMenuItem<Locale>(
                  value: Locale('bn'),
                  child: Text('বাংলা'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(Barcode barcode) async {
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    final type = _detectType(rawValue);
    final scan = ScanModel(
      rawValue: rawValue,
      type: type,
      timestamp: DateTime.now(),
    );

    await DatabaseService().insertScan(scan);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(rawValue: rawValue),
      ),
    ).then((_) => controller.start());
  }

  QrType _detectType(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return QrType.url;
    } else if (value.startsWith('mailto:')) {
      return QrType.email;
    } else if (value.startsWith('tel:')) {
      return QrType.phone;
    } else if (value.startsWith('WIFI:')) {
      return QrType.wifi;
    } else if (value.startsWith('geo:')) {
      return QrType.location;
    } else if (value.startsWith('BEGIN:VCARD')) {
      return QrType.contact;
    } else if (value.startsWith('upi://') || 
               value.toLowerCase().contains('bkash') || 
               value.toLowerCase().contains('nagad')) {
      return QrType.payment;
    }
    return QrType.text;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }
}

// Custom Overlay Shape (Simple implementation for now, can be replaced with a library or custom painter)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero)
      ..addRect(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength > cutOutSize / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final mCutOutSize = cutOutSize < width - borderOffset
        ? cutOutSize
        : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: mCutOutSize,
      height: mCutOutSize,
    );

    canvas.saveLayer(
      rect,
      backgroundPaint,
    );

    canvas.drawRect(
      rect,
      backgroundPaint,
    );

    // Draw cut out
    canvas.drawRect(
      cutOutRect,
      Paint()..blendMode = BlendMode.clear,
    );

    canvas.restore();

    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + mBorderLength)
        ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.top,
            cutOutRect.left + borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.left + mBorderLength, cutOutRect.top)
        ..moveTo(cutOutRect.right, cutOutRect.top + mBorderLength)
        ..lineTo(cutOutRect.right, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.top,
            cutOutRect.right - borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.right - mBorderLength, cutOutRect.top)
        ..moveTo(cutOutRect.right, cutOutRect.bottom - mBorderLength)
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.bottom,
            cutOutRect.right - borderRadius, cutOutRect.bottom)
        ..lineTo(cutOutRect.right - mBorderLength, cutOutRect.bottom)
        ..moveTo(cutOutRect.left, cutOutRect.bottom - mBorderLength)
        ..lineTo(cutOutRect.left, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.bottom,
            cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..lineTo(cutOutRect.left + mBorderLength, cutOutRect.bottom),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
