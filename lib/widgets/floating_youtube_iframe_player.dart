import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:developer' as developer;
import 'dart:math';
import '../services/video_controller_service.dart';

class FloatingYoutubeIframePlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final VoidCallback onClose;

  const FloatingYoutubeIframePlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.onClose,
  });

  @override
  State<FloatingYoutubeIframePlayer> createState() => _FloatingYoutubeIframePlayerState();
}

class _FloatingYoutubeIframePlayerState extends State<FloatingYoutubeIframePlayer> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  // For draggable functionality
  Offset _position = const Offset(10, 100); // Positioned to be more visible on the screen
  bool _isMinimized = false; // Start in expanded mode by default

  // Size constants - maximized for visibility while maintaining compatibility
  final double _minimizedWidth = 280.0;
  final double _minimizedHeight = 157.5; // Maintains 16:9 aspect ratio
  final double _expandedWidth = 560.0;
  final double _expandedHeight = 315.0; // Maintains 16:9 aspect ratio

  // Dynamic size variables that will be calculated based on screen size
  double _actualWidth = 560.0;
  double _actualHeight = 315.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      // Extract video ID from URL
      final videoId = _extractVideoId(widget.videoUrl);

      if (videoId != null) {
        developer.log('Initializing floating YouTube iFrame player with video ID: $videoId');

        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: false, // Disable fullscreen in floating mode
            enableCaption: false,
            mute: false,
          ),
        );

        // Register this controller with the video service to manage multiple players
        VideoControllerService().registerActiveController(_controller, videoId);

        // Set loading to false after a timeout
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Could not extract video ID from the provided URL.';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error initializing floating YouTube player: $e');
      setState(() {
        _errorMessage = 'Error initializing video player: $e';
        _isLoading = false;
      });
    }
  }

  String? _extractVideoId(String url) {
    try {
      // Special case for the example video
      if (url == 'https://www.youtube.com/watch?v=Zq92Gm4W88M' ||
          url == 'https://youtu.be/Zq92Gm4W88M') {
        return 'Zq92Gm4W88M';
      }

      // Try to extract using the YoutubePlayerController's utility
      return YoutubePlayerController.convertUrlToId(url);
    } catch (e) {
      developer.log('Error extracting video ID: $e');
      return null;
    }
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  @override
  void dispose() {
    // Unregister from the video service
    VideoControllerService().unregisterController(_controller);
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Dynamically adjust player size based on screen dimensions
    _actualWidth = _isMinimized ? _minimizedWidth : _expandedWidth;
    _actualHeight = _isMinimized ? _minimizedHeight : _expandedHeight;

    // If the player is too large for the screen, adjust the size
    if (_actualWidth > screenSize.width * 0.9) {
      // Use 90% of screen width and maintain aspect ratio
      _actualWidth = screenSize.width * 0.9;
      _actualHeight = _actualWidth * 9 / 16; // Maintain 16:9 aspect ratio
    }

    // If still too tall, further adjust
    if (_actualHeight > screenSize.height * 0.6) {
      _actualHeight = screenSize.height * 0.6;
      _actualWidth = _actualHeight * 16 / 9; // Maintain 16:9 aspect ratio
    }

    // Calculate max bounds, ensuring they're never negative
    final maxX = max(0.0, screenSize.width - _actualWidth);
    final maxY = max(0.0, screenSize.height - _actualHeight - 100);

    // Ensure the player stays within screen bounds
    _position = Offset(
      _position.dx.clamp(0.0, maxX),
      _position.dy.clamp(0.0, maxY),
    );

    // Dynamically adjust player size based on screen dimensions
    _actualWidth = _isMinimized ? _minimizedWidth : _expandedWidth;
    _actualHeight = _isMinimized ? _minimizedHeight : _expandedHeight;

    // If the player is too large for the screen, adjust the size
    if (_actualWidth > screenSize.width * 0.9) {
      // Use 90% of screen width and maintain aspect ratio
      _actualWidth = screenSize.width * 0.9;
      _actualHeight = _actualWidth * 9 / 16; // Maintain 16:9 aspect ratio
    }

    // If still too tall, further adjust
    if (_actualHeight > screenSize.height * 0.6) {
      _actualHeight = screenSize.height * 0.6;
      _actualWidth = _actualHeight * 16 / 9; // Maintain 16:9 aspect ratio
    }

    // Handle error state
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    // Always show the player with a loading overlay if needed
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        child: Stack(
          children: [
            // Main container with player
            Container(
              width: _actualWidth,
              height: _actualHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(128),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Control bar - increased height for better touch targets
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title (only show when not minimized)
                        if (!_isMinimized)
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minimize/Expand button
                            InkWell(
                              onTap: _toggleMinimize,
                              child: Icon(
                                _isMinimized ? Icons.open_in_full : Icons.close_fullscreen,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Close button
                            InkWell(
                              onTap: () {
                                try {
                                  _controller.pauseVideo();
                                  // Unregister when closing manually
                                  VideoControllerService().unregisterController(_controller);
                                } catch (e) {
                                  developer.log('Error pausing video: $e');
                                }
                                widget.onClose();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // YouTube player - fill the entire container
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _actualWidth / (_actualHeight - 40),
                            child: YoutubePlayer(
                              controller: _controller,
                              aspectRatio: _actualWidth / (_actualHeight - 40), // Dynamic aspect ratio
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                width: _actualWidth,
                height: _actualHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(178),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Container(
        width: _actualWidth,
        height: _actualHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(128),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC19FFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 30),
              ),
              child: const Text('Try Again', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onClose,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Close', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
