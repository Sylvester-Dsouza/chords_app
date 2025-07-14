import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/karaoke.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class MultiTrackKaraokeService {
  final AuthService _authService;

  MultiTrackKaraokeService(this._authService);

  /// Get all tracks download URLs for a song
  Future<Map<TrackType, KaraokeTrackDownload>?> getAllTracksDownloadUrls(String songId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/karaoke/songs/$songId/tracks/download-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🎤 Multi-track download API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final Map<TrackType, KaraokeTrackDownload> tracks = {};

        for (final entry in data.entries) {
          final trackType = TrackTypeExtension.fromApiValue(entry.key);
          final trackData = entry.value as Map<String, dynamic>;
          
          tracks[trackType] = KaraokeTrackDownload(
            downloadUrl: trackData['downloadUrl'] as String,
            fileSize: trackData['fileSize'] as int? ?? 0,
            duration: trackData['duration'] as int? ?? 0,
            trackType: trackType,
            volume: (trackData['volume'] as num?)?.toDouble() ?? 1.0,
            isMuted: trackData['isMuted'] as bool? ?? false,
          );
        }

        debugPrint('🎤 Parsed ${tracks.length} track download URLs');
        return tracks;
      } else {
        debugPrint('🎤 API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get track download URLs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🎤 Error getting multi-track download URLs: $e');
      return null;
    }
  }

  /// Get single track download URL
  Future<KaraokeTrackDownload?> getTrackDownloadUrl(String songId, TrackType trackType) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/karaoke/songs/$songId/tracks/${trackType.apiValue}/download'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🎤 Single track download API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        return KaraokeTrackDownload(
          downloadUrl: data['downloadUrl'] as String,
          fileSize: data['fileSize'] as int? ?? 0,
          duration: data['duration'] as int? ?? 0,
          trackType: trackType,
          volume: (data['volume'] as num?)?.toDouble() ?? 1.0,
          isMuted: data['isMuted'] as bool? ?? false,
        );
      } else {
        debugPrint('🎤 API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get track download URL: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🎤 Error getting track download URL: $e');
      return null;
    }
  }

  /// Update track settings (volume, mute)
  Future<bool> updateTrackSettings(String songId, TrackType trackType, {
    double? volume,
    bool? isMuted,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final body = <String, dynamic>{};
      if (volume != null) body['volume'] = volume;
      if (isMuted != null) body['isMuted'] = isMuted;

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/karaoke/songs/$songId/tracks/${trackType.apiValue}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint('🎤 Update track settings API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('🎤 Track settings updated successfully');
        return true;
      } else {
        debugPrint('🎤 API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('🎤 Error updating track settings: $e');
      return false;
    }
  }
}

/// Data class for track download information
class KaraokeTrackDownload {
  final String downloadUrl;
  final int fileSize;
  final int duration;
  final TrackType trackType;
  final double volume;
  final bool isMuted;

  const KaraokeTrackDownload({
    required this.downloadUrl,
    required this.fileSize,
    required this.duration,
    required this.trackType,
    required this.volume,
    required this.isMuted,
  });

  factory KaraokeTrackDownload.fromJson(Map<String, dynamic> json) {
    return KaraokeTrackDownload(
      downloadUrl: json['downloadUrl'] as String,
      fileSize: json['fileSize'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      trackType: TrackTypeExtension.fromApiValue(json['trackType'] as String),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'duration': duration,
      'trackType': trackType.apiValue,
      'volume': volume,
      'isMuted': isMuted,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
