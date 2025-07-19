import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _apiService = ApiService();
  String? _sessionId;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Initialize analytics session
  Future<void> initializeSession({
    String? deviceInfo,
    String? appVersion,
    String? platform,
  }) async {
    try {
      debugPrint('Initializing analytics session...');
      
      final response = await _apiService.post('/analytics/session/start', data: {
        'deviceInfo': deviceInfo ?? 'Flutter App',
        'appVersion': appVersion ?? '1.0.0',
        'platform': platform ?? 'mobile',
      });

      if (response.statusCode == 200 && response.data['sessionId'] != null) {
        _sessionId = response.data['sessionId'] as String?;
        debugPrint('Analytics session initialized: $_sessionId');
      }
    } catch (e) {
      debugPrint('Error initializing analytics session: $e');
      // Don't throw error - analytics should not break the app
    }
  }

  /// Track a content view (song, artist, collection)
  Future<void> trackContentView({
    required String contentType,
    required String contentId,
    String? source,
  }) async {
    try {
      debugPrint('Tracking $contentType view: $contentId');
      
      await _apiService.post('/analytics/track/view', data: {
        'contentType': contentType,
        'contentId': contentId,
        'sessionId': _sessionId,
        'source': source,
      });

      debugPrint('Successfully tracked $contentType view: $contentId');
    } catch (e) {
      debugPrint('Error tracking $contentType view: $e');
      // Don't throw error - analytics should not break the app
    }
  }

  /// Track a song view
  Future<void> trackSongView(String songId, {String? source}) async {
    await trackContentView(
      contentType: 'song',
      contentId: songId,
      source: source,
    );
  }

  /// Track an artist view
  Future<void> trackArtistView(String artistId, {String? source}) async {
    await trackContentView(
      contentType: 'artist',
      contentId: artistId,
      source: source,
    );
  }

  /// Track a collection view
  Future<void> trackCollectionView(String collectionId, {String? source}) async {
    await trackContentView(
      contentType: 'collection',
      contentId: collectionId,
      source: source,
    );
  }

  /// Track a page view
  Future<void> trackPageView({
    required String page,
    String? referrer,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (_sessionId == null) {
        debugPrint('No session ID available for page view tracking');
        return;
      }

      debugPrint('Tracking page view: $page');
      
      await _apiService.post('/analytics/track/page', data: {
        'page': page,
        'sessionId': _sessionId,
        'referrer': referrer,
        'parameters': parameters,
      });

      debugPrint('Successfully tracked page view: $page');
    } catch (e) {
      debugPrint('Error tracking page view: $e');
      // Don't throw error - analytics should not break the app
    }
  }

  /// End the current session
  Future<void> endSession() async {
    try {
      if (_sessionId == null) {
        debugPrint('No session to end');
        return;
      }

      debugPrint('Ending analytics session: $_sessionId');
      
      await _apiService.post('/analytics/session/end', data: {
        'sessionId': _sessionId,
      });

      _sessionId = null;
      debugPrint('Analytics session ended');
    } catch (e) {
      debugPrint('Error ending analytics session: $e');
      // Don't throw error - analytics should not break the app
    }
  }

  /// Get current session ID
  String? get sessionId => _sessionId;

  /// Check if session is active
  bool get hasActiveSession => _sessionId != null;
}
