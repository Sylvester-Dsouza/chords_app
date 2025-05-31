import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/setlist_service.dart';
import '../utils/ui_helpers.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final SetlistService _setlistService = SetlistService();
  late MobileScannerController controller;

  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
        if (!result.isGranted) {
          _errorMessage = 'Camera permission is required to scan QR codes';
        }
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (!_isProcessing && barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _processQRCode(barcodes.first.rawValue!);
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop scanning while processing
      await controller.stop();

      String? shareCode;

      // Check if it's a deep link
      if (qrData.startsWith('stuthi://join/')) {
        shareCode = qrData.replaceFirst('stuthi://join/', '');
      } else if (RegExp(r'^\d{4}$').hasMatch(qrData)) {
        // Direct 4-digit code
        shareCode = qrData;
      } else {
        throw Exception('Invalid QR code format');
      }

      // Validate share code format
      if (shareCode.length != 4 || !RegExp(r'^\d{4}$').hasMatch(shareCode)) {
        throw Exception('Invalid share code format. Expected 4-digit code.');
      }

      // Preview the setlist first
      debugPrint('Attempting to get setlist with share code: $shareCode');
      final setlist = await _setlistService.getSetlistByShareCode(shareCode);
      debugPrint('Successfully retrieved setlist: ${setlist.name}');

      if (mounted) {
        // Show preview dialog
        final shouldJoin = await _showJoinConfirmationDialog(setlist.name, 'Setlist Owner', shareCode);

        if (shouldJoin == true) {
          // Join the setlist
          debugPrint('User confirmed joining setlist, attempting to join...');
          await _setlistService.joinSetlist(shareCode);
          debugPrint('Successfully joined setlist');

          if (mounted) {
            UIHelpers.showSuccessSnackBar(
              context,
              'Successfully joined "${setlist.name}"!',
            );

            // Navigate back to setlists screen and trigger refresh
            Navigator.of(context).pop(); // Pop QR scanner
            Navigator.of(context).pop(true); // Pop back to setlists with refresh signal
          }
        } else {
          // Resume scanning if user cancels
          await controller.start();
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );

        // Resume scanning after error
        await controller.start();
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _showJoinConfirmationDialog(String setlistName, String ownerName, String shareCode) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.queue_music,
              color: const Color(0xFFC19FFF),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Join Setlist',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to join this setlist?',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    setlistName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created by: $ownerName',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code: $shareCode',
                    style: TextStyle(
                      color: const Color(0xFFC19FFF),
                      fontSize: 14,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC19FFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: _hasPermission
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: _onDetect,
                      ),
                      // Custom overlay with cutout
                      CustomPaint(
                        painter: QRScannerOverlay(
                          borderColor: const Color(0xFFC19FFF),
                          borderWidth: 4,
                          cutOutSize: 250,
                          borderRadius: 16,
                        ),
                        child: Container(),
                      ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.7),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFFC19FFF),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Processing QR code...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? 'Camera permission required',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkCameraPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC19FFF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Grant Permission'),
                        ),
                      ],
                    ),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The camera will automatically scan when a valid QR code is detected',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerOverlay extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double cutOutSize;
  final double borderRadius;

  QRScannerOverlay({
    required this.borderColor,
    required this.borderWidth,
    required this.cutOutSize,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw background overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Calculate cutout position (center)
    final double cutOutLeft = (size.width - cutOutSize) / 2;
    final double cutOutTop = (size.height - cutOutSize) / 2;

    // Create cutout path
    final Path cutOutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cutOutLeft, cutOutTop, cutOutSize, cutOutSize),
        Radius.circular(borderRadius),
      ));

    // Clear the cutout area
    canvas.drawPath(cutOutPath, Paint()..blendMode = BlendMode.clear);

    // Draw border around cutout
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cutOutLeft, cutOutTop, cutOutSize, cutOutSize),
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    // Draw corner indicators
    final double cornerLength = 30;
    final Paint cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 2
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(cutOutLeft, cutOutTop + cornerLength),
      Offset(cutOutLeft, cutOutTop + borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutLeft + cornerLength, cutOutTop),
      Offset(cutOutLeft + borderRadius, cutOutTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cutOutLeft + cutOutSize, cutOutTop + cornerLength),
      Offset(cutOutLeft + cutOutSize, cutOutTop + borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutLeft + cutOutSize - cornerLength, cutOutTop),
      Offset(cutOutLeft + cutOutSize - borderRadius, cutOutTop),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cutOutLeft, cutOutTop + cutOutSize - cornerLength),
      Offset(cutOutLeft, cutOutTop + cutOutSize - borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutLeft + cornerLength, cutOutTop + cutOutSize),
      Offset(cutOutLeft + borderRadius, cutOutTop + cutOutSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cutOutLeft + cutOutSize, cutOutTop + cutOutSize - cornerLength),
      Offset(cutOutLeft + cutOutSize, cutOutTop + cutOutSize - borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutLeft + cutOutSize - cornerLength, cutOutTop + cutOutSize),
      Offset(cutOutLeft + cutOutSize - borderRadius, cutOutTop + cutOutSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
