import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:developer' as developer;
import '../services/video_controller_service.dart';

class YouTubeIframeBottomSheet extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YouTubeIframeBottomSheet({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<YouTubeIframeBottomSheet> createState() => _YouTubeIframeBottomSheetState();
}

class _YouTubeIframeBottomSheetState extends State<YouTubeIframeBottomSheet> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;
  String? _errorMessage;

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
        developer.log('Initializing YouTube iFrame bottom sheet with video ID: $videoId');

        // Create a simpler controller configuration
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            enableCaption: false,
            mute: false,
            strictRelatedVideos: true,
            enableJavaScript: true,
            pointerEvents: PointerEvents.auto,
          ),
        );

        // Register this controller with the video service to manage multiple players
        VideoControllerService().registerActiveController(_controller, videoId);

        // Listen for player state changes
        _controller.listen((event) {
          if (event.playerState == PlayerState.playing) {
            if (mounted && _isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        });

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
      developer.log('Error initializing YouTube player: $e');
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

  @override
  void dispose() {
    // Unregister from the video service
    VideoControllerService().unregisterController(_controller);
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle error state
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    // Create the base container with the YouTube player
    return Container(
      padding: const EdgeInsets.only(top: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    // Pause video before closing
                    try {
                      _controller.pauseVideo();
                      // Unregister when closing manually
                      VideoControllerService().unregisterController(_controller);
                    } catch (e) {
                      developer.log('Error pausing video: $e');
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // YouTube player with loading overlay
          Expanded(
            child: Stack(
              children: [
                // YouTube player
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: YoutubePlayer(
                            controller: _controller,
                            aspectRatio: 16 / 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withAlpha(150),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading video...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _initializePlayer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB388FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFB388FF)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
