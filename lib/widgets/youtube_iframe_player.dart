import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:developer' as developer;

class YoutubeIframePlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final bool isFullScreen;
  final VoidCallback? onClose;

  const YoutubeIframePlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.isFullScreen = false,
    this.onClose,
  });

  @override
  State<YoutubeIframePlayer> createState() => _YoutubeIframePlayerState();
}

class _YoutubeIframePlayerState extends State<YoutubeIframePlayer> {
  late final YoutubePlayerController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      // Extract video ID from URL
      _videoId = _extractVideoId(widget.videoUrl);

      if (_videoId != null) {
        developer.log('Initializing YouTube iFrame player with video ID: $_videoId');

        // Create controller with the video ID directly
        _controller = YoutubePlayerController.fromVideoId(
          videoId: _videoId!,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            enableCaption: false,
            mute: false,
          ),
        );

        // Set a timeout to handle cases where the video doesn't load
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isLoading) {
            developer.log('Video loading timeout reached');
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
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    // Always show the player, but overlay a loading indicator if still loading
    return Stack(
      children: [
        _buildPlayer(),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildPlayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isFullScreen) _buildHeader(),
        Expanded(
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withAlpha(178), // Using withAlpha instead of withOpacity
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC19FFF)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFF1E1E1E),
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
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFF121212),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.white),
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
                backgroundColor: const Color(0xFFC19FFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
            if (widget.onClose != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onClose,
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
