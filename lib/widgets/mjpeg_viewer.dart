import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A lightweight, fully null-safe MJPEG stream viewer for Flutter.
/// Connects directly to FastAPI `/api/video/feed` or any IP camera MJPEG stream.
class MjpegViewer extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const MjpegViewer({
    Key? key,
    required this.streamUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<MjpegViewer> createState() => _MjpegViewerState();
}

class _MjpegViewerState extends State<MjpegViewer> {
  Uint8List? _currentFrame;
  http.Client? _client;
  StreamSubscription? _subscription;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void didUpdateWidget(MjpegViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _stopStream();
      _startStream();
    }
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  void _stopStream() {
    _subscription?.cancel();
    _client?.close();
    _subscription = null;
    _client = null;
  }

  void _startStream() async {
    _stopStream();
    setState(() {
      _hasError = false;
    });

    try {
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      final List<int> buffer = [];
      _subscription = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);

          // Find JPEG Start Of Image (0xFF, 0xD8) and End Of Image (0xFF, 0xD9)
          while (true) {
            int soi = -1;
            for (int i = 0; i < buffer.length - 1; i++) {
              if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
                soi = i;
                break;
              }
            }

            if (soi == -1) {
              if (buffer.length > 2048) {
                buffer.removeRange(0, buffer.length - 2);
              }
              break;
            }

            int eoi = -1;
            for (int i = soi + 2; i < buffer.length - 1; i++) {
              if (buffer[i] == 0xFF && buffer[i + 1] == 0xD9) {
                eoi = i + 2;
                break;
              }
            }

            if (eoi != -1) {
              final frameBytes = Uint8List.fromList(buffer.sublist(soi, eoi));
              buffer.removeRange(0, eoi);
              if (mounted) {
                setState(() {
                  _currentFrame = frameBytes;
                  _hasError = false;
                });
              }
            } else {
              break;
            }
          }
        },
        onError: (err) {
          if (mounted) setState(() => _hasError = true);
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Image.asset('assets/live_feed.jpg', fit: widget.fit);
    }

    if (_currentFrame != null) {
      return Image.memory(
        _currentFrame!,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }

    return widget.placeholder ??
        Image.asset('assets/live_feed.jpg', fit: widget.fit);
  }
}
