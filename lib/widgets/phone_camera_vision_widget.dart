import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import 'mjpeg_viewer.dart';

class PhoneCameraVisionWidget extends StatefulWidget {
  final Function(Map<String, dynamic> summary, List<dynamic> detections)? onGuidanceUpdated;
  final bool isVoiceEnabled;

  const PhoneCameraVisionWidget({
    Key? key,
    this.onGuidanceUpdated,
    this.isVoiceEnabled = true,
  }) : super(key: key);

  @override
  State<PhoneCameraVisionWidget> createState() => _PhoneCameraVisionWidgetState();
}

class _PhoneCameraVisionWidgetState extends State<PhoneCameraVisionWidget> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  bool _usePhoneCamera = true;
  Timer? _frameStreamTimer;
  String _cameraStatus = "Initializing camera...";
  String? _networkError;
  int _successFrames = 0;

  List<dynamic> _detections = [];
  Map<String, dynamic>? _latestSummary;

  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraStatus = "No camera found on this device";
            _usePhoneCamera = false;
          });
        }
        return;
      }

      // Select back camera by default
      final backCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _cameraStatus = "Camera Ready";
        });
        _startStreamingFrames();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraStatus = "Camera Error: $e";
          _usePhoneCamera = false;
        });
      }
    }
  }

  void _startStreamingFrames() {
    _frameStreamTimer?.cancel();
    // Capture & send frames every 450ms (~2.2 FPS, optimal stability for Android CameraX)
    _frameStreamTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      _captureAndSendFrame();
    });
  }

  Future<void> _captureAndSendFrame() async {
    if (!_isCameraReady ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessingFrame ||
        !_usePhoneCamera) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final xfile = await _cameraController!.takePicture();
      final bytes = await xfile.readAsBytes();

      final result = await ApiService.uploadFrame(bytes);
      if (result != null && mounted) {
        final detections = result["detections"] as List<dynamic>? ?? [];
        final summary = result["summary"] as Map<String, dynamic>? ?? {};

        setState(() {
          _detections = detections;
          _latestSummary = summary;
          _networkError = null;
          _successFrames++;
        });

        if (widget.onGuidanceUpdated != null) {
          widget.onGuidanceUpdated!(summary, detections);
        }

        // Voice Guidance Check
        if (widget.isVoiceEnabled && summary.containsKey("voice_text")) {
          final voiceText = summary["voice_text"] as String? ?? "";
          if (voiceText.isNotEmpty) {
            _voiceService.speak(voiceText);
          }
        }
      } else if (mounted) {
        setState(() {
          _networkError = "Cannot reach server at ${ApiService.baseUrl}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _networkError = "Connection error: $e";
        });
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _showIpDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Server IP', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the laptop IP (current: http://10.236.58.218:8000):',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://10.236.58.218:8000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiService.setBaseUrl(newUrl);
                setState(() {
                  _networkError = null;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _frameStreamTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Preview (Phone Camera or Robot MJPEG Feed)
            _usePhoneCamera ? _buildPhoneCameraView() : _buildRobotMjpegView(),

            // Top Status & Switch HUD
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (_networkError == null)
                            ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                            : const Color(0xFFEF4444).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: (_networkError == null) ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _usePhoneCamera
                              ? (_networkError == null ? 'YOLOv8 ONLINE ($_successFrames)' : 'SERVER OFFLINE')
                              : 'ROBOT MJPEG STREAM',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Toggle Button (Switch between Phone Camera & Robot Stream)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_networkError != null)
                        GestureDetector(
                          onTap: _showIpDialog,
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.settings_ethernet_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 3),
                                Text('Set IP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _usePhoneCamera = !_usePhoneCamera;
                            if (_usePhoneCamera && _isCameraReady) {
                              _startStreamingFrames();
                            } else {
                              _frameStreamTimer?.cancel();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _usePhoneCamera ? Icons.switch_video_rounded : Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _usePhoneCamera ? 'Robot Feed' : 'Phone Cam',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Network Error Banner
            if (_usePhoneCamera && _networkError != null)
              Positioned(
                top: 45,
                left: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _showIpDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$_networkError\nTap here to verify/change backend IP address.',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Detections HUD
            if (_usePhoneCamera && _latestSummary != null)
              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_latestSummary!["recommended_action"] == "FORWARD")
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (_latestSummary!["recommended_action"] == "FORWARD")
                            ? Icons.navigation_rounded
                            : Icons.warning_amber_rounded,
                        color: (_latestSummary!["recommended_action"] == "FORWARD")
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _latestSummary!["instruction"] ?? "Scanning corridor...",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_detections.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_detections.length} DETECTED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneCameraView() {
    if (!_isCameraReady || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4F46E5)),
            const SizedBox(height: 12),
            Text(
              _cameraStatus,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        if (_detections.isNotEmpty)
          CustomPaint(
            painter: YoloBoundingBoxPainter(detections: _detections),
          ),
      ],
    );
  }

  Widget _buildRobotMjpegView() {
    return MjpegViewer(
      streamUrl: ApiService.liveStreamUrl,
      fit: BoxFit.cover,
    );
  }
}

/// Paints YOLOv8 detection boxes and distance tags directly on top of the CameraPreview
class YoloBoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;

  YoloBoundingBoxPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    for (var det in detections) {
      final bbox = det['bbox'] as List<dynamic>?;
      if (bbox == null || bbox.length < 4) continue;

      // Normalized/Scale: assuming camera frames are typically 640x480
      final double origW = 640.0;
      final double origH = 480.0;

      final double scaleX = size.width / origW;
      final double scaleY = size.height / origH;

      final double left = (bbox[0] as num).toDouble() * scaleX;
      final double top = (bbox[1] as num).toDouble() * scaleY;
      final double right = (bbox[2] as num).toDouble() * scaleX;
      final double bottom = (bbox[3] as num).toDouble() * scaleY;

      final double dist = (det['distance_m'] as num?)?.toDouble() ?? 2.5;
      final String cls = (det['class'] as String? ?? 'object').toUpperCase();
      final int conf = (det['confidence_pct'] as num?)?.toInt() ?? 90;
      final String zone = det['zone'] as String? ?? 'CENTER';

      // Pick color based on distance
      Color boxColor = const Color(0xFF22C55E); // Green
      if (dist < 1.8) {
        boxColor = const Color(0xFFEF4444); // Red
      } else if (dist < 3.0) {
        boxColor = const Color(0xFFF59E0B); // Amber
      }

      final paint = Paint()
        ..color = boxColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      // Draw bounding box
      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, paint);

      // Draw center target crosshair
      final cx = (left + right) / 2;
      final cy = (top + bottom) / 2;
      canvas.drawLine(Offset(cx - 8, cy), Offset(cx + 8, cy), paint);
      canvas.drawLine(Offset(cx, cy - 8), Offset(cx, cy + 8), paint);

      // Draw label badge
      final label = '$cls $conf% | ${dist.toStringAsFixed(1)}m [$zone]';
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromLTWH(left, (top - 18).clamp(0, size.height), textPainter.width + 8, 16);
      final bgPaint = Paint()..color = boxColor;
      canvas.drawRect(bgRect, bgPaint);
      textPainter.paint(canvas, Offset(left + 4, (top - 16).clamp(0, size.height)));
    }
  }

  @override
  bool shouldRepaint(covariant YoloBoundingBoxPainter oldDelegate) {
    return true;
  }
}
