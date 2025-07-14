import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../models/karaoke.dart';
import '../services/multi_track_download_manager.dart';
import '../services/multi_track_karaoke_service.dart';
import '../services/auth_service.dart';
import '../services/song_service.dart';
import '../config/theme.dart';
import '../widgets/karaoke_lyrics_view.dart';

class MultiTrackKaraokePlayerScreen extends StatefulWidget {
  final Song song;

  const MultiTrackKaraokePlayerScreen({
    super.key,
    required this.song,
  });

  @override
  State<MultiTrackKaraokePlayerScreen> createState() => _MultiTrackKaraokePlayerScreenState();
}

class _MultiTrackKaraokePlayerScreenState extends State<MultiTrackKaraokePlayerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late MultiTrackDownloadManager _downloadManager;
  final AuthService _authService = AuthService();
  final SongService _songService = SongService();
  late MultiTrackKaraokeService _multiTrackService;

  // Song data with complete chord sheet
  Song? _songWithChords;

  // Audio players for each track
  final Map<TrackType, AudioPlayer> _audioPlayers = {};
  final Map<TrackType, bool> _trackMuted = {};
  final Map<TrackType, double> _trackVolumes = {};
  final Map<TrackType, String?> _trackPaths = {};
  final Map<TrackType, PlayerState> _trackStates = {};
  final Map<TrackType, bool> _trackPlayingStatus = {};

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isDownloading = false;
  String _loadingMessage = 'Initializing AI-powered karaoke...';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _downloadProgress = 0.0;

  // Master track for synchronization (first available track, preferably vocals)
  TrackType? _masterTrack;

  // Track if this is the first play (need to use play() instead of resume())
  bool _hasPlayedBefore = false;

  // Track health monitoring
  Timer? _trackHealthTimer;
  Timer? _syncVerificationTimer;
  int _playingTrackCount = 0;

  // Enhanced synchronization
  Timer? _positionTimer;
  bool _isSeeking = false;
  Duration _lastKnownPosition = Duration.zero;
  final Map<TrackType, Duration> _trackPositions = {};
  bool _isPreloaded = false;

  // Track icons and colors
  final Map<TrackType, IconData> _trackIcons = {
    TrackType.vocals: Icons.mic,
    TrackType.bass: Icons.music_note,
    TrackType.drums: Icons.album,
    TrackType.other: Icons.queue_music,
  };

  final Map<TrackType, Color> _trackColors = {
    TrackType.vocals: const Color(0xFF3B82F6), // Blue
    TrackType.bass: const Color(0xFF10B981),   // Green
    TrackType.drums: const Color(0xFFEF4444),  // Red
    TrackType.other: const Color(0xFF8B5CF6),  // Purple
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackHealthTimer?.cancel();
    _syncVerificationTimer?.cancel();
    _positionTimer?.cancel();
    for (final player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _authService.initializeFirebase();
    _downloadManager = MultiTrackDownloadManager();
    _multiTrackService = MultiTrackKaraokeService(_authService);
    await _downloadManager.initialize();
    await _initializePlayer();
    await _fetchChordSheetIfNeeded();
  }

  Future<void> _fetchChordSheetIfNeeded() async {
    try {
      // Check if the song already has chord sheet data
      if (widget.song.chords != null && widget.song.chords!.isNotEmpty) {
        debugPrint('🎵 Song already has chord sheet data (${widget.song.chords!.length} chars)');
        _songWithChords = widget.song;
        return;
      }

      debugPrint('🎵 Song missing chord sheet data, fetching from backend...');

      // Fetch fresh song data with chord sheet
      final freshSong = await _songService.getSongById(widget.song.id);

      if (freshSong.chords != null && freshSong.chords!.isNotEmpty) {
        debugPrint('🎵 Successfully fetched chord sheet data (${freshSong.chords!.length} chars)');
        _songWithChords = freshSong;
      } else {
        debugPrint('🎵 No chord sheet data available in backend');
        _songWithChords = widget.song;
      }
    } catch (e) {
      debugPrint('🎵 Error fetching chord sheet data: $e');
      _songWithChords = widget.song;
    }
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _loadingMessage = 'Scanning for AI-separated tracks...';
      });

      // Check if song has karaoke data
      if (widget.song.karaoke == null) {
        debugPrint('🎤 No karaoke data available for this song');
        setState(() {
          _isLoading = false;
          _loadingMessage = 'No karaoke data available for this song.';
        });
        return;
      }
      
      // Debug the karaoke data
      debugPrint('🎤 Karaoke data: ${widget.song.karaoke!.tracks.length} tracks available');
      for (final track in widget.song.karaoke!.tracks) {
        debugPrint('🎤 Track: ${track.trackType.displayName}, URL: ${track.fileUrl}');
      }
      
      // Check if song has multi-track karaoke
      if (widget.song.karaoke!.tracks.isEmpty) {
        debugPrint('🎤 No multi-track karaoke available for this song');
        setState(() {
          _isLoading = false;
          _loadingMessage = 'No multi-track karaoke available for this song.';
        });
        return;
      }

      // Initialize audio players for each track type
      for (final trackType in TrackType.values) {
        _audioPlayers[trackType] = AudioPlayer();
        _trackMuted[trackType] = false;
        _trackVolumes[trackType] = 1.0;
        _trackStates[trackType] = PlayerState.stopped;
        _trackPlayingStatus[trackType] = false;

        // Set up individual track state listeners
        _audioPlayers[trackType]!.onPlayerStateChanged.listen((state) {
          _trackStates[trackType] = state;
          _trackPlayingStatus[trackType] = state == PlayerState.playing;

          // Update playing track count
          _playingTrackCount = _trackPlayingStatus.values.where((playing) => playing).length;

          debugPrint('🎤 ${trackType.displayName} state changed: $state (Playing tracks: $_playingTrackCount/${_trackPaths.length})');

          if (mounted) {
            setState(() {});
          }
        });
      }

      await _loadTracks();
    } catch (e) {
      debugPrint('🎤 Error in _initializePlayer: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadTracks() async {
    try {
      setState(() {
        _loadingMessage = 'AI is processing vocal separation...';
        _isDownloading = true;
      });

      // Debug song information
      debugPrint('🎤 Loading tracks for song: ${widget.song.title} (ID: ${widget.song.id})');
      debugPrint('🎤 Song has chord sheet: ${widget.song.chords != null && widget.song.chords!.isNotEmpty}');

      // Check if karaoke data exists
      if (widget.song.karaoke == null) {
        debugPrint('🎤 No karaoke data available for song: ${widget.song.id}');
        setState(() {
          _isLoading = false;
          _isDownloading = false;
          _loadingMessage = 'No karaoke data available for this song.';
        });
        return;
      }

      final tracks = widget.song.karaoke!.tracks;

      // Check if there are any tracks available
      if (tracks.isEmpty) {
        setState(() {
          _isLoading = false;
          _isDownloading = false;
          _loadingMessage = 'No AI-separated tracks available for this song yet.';
        });
        return;
      }

      // First, try to get all track download URLs from the API
      debugPrint('🎤 Fetching track download URLs from API for song: ${widget.song.id}');
      Map<TrackType, KaraokeTrackDownload>? trackDownloads;

      try {
        trackDownloads = await _multiTrackService.getAllTracksDownloadUrls(widget.song.id);
      } catch (e) {
        debugPrint('🎤 Error fetching track download URLs from API: $e');
      }

      if (trackDownloads == null || trackDownloads.isEmpty) {
        debugPrint('🎤 No track download URLs available from API, falling back to song karaoke data');

        // Fallback: use the track URLs from the song's karaoke data
        if (tracks.isNotEmpty) {
          debugPrint('🎤 Using fallback track URLs from song karaoke data');
          await _loadTracksFromSongData(tracks);
          return;
        } else {
          debugPrint('🎤 No tracks available in song karaoke data either');
          setState(() {
            _isLoading = false;
            _isDownloading = false;
            _loadingMessage = 'No track download URLs available from server or song data.';
          });
          return;
        }
      }

      debugPrint('🎤 Got ${trackDownloads.length} track download URLs from API');

      int completedTracks = 0;
      final totalTracks = trackDownloads.length;

      for (final entry in trackDownloads.entries) {
        final trackType = entry.key;
        final trackDownload = entry.value;

        setState(() {
          _loadingMessage = 'Processing ${trackType.displayName.toLowerCase()} track...';
        });

        // Check if track is already downloaded
        debugPrint('🎤 Checking for local track: ${trackType.displayName} for song ID: ${widget.song.id}');
        final localPath = _downloadManager.getLocalPath(widget.song.id, trackType);
        debugPrint('🎤 Download manager returned path: $localPath');

        if (localPath != null) {
          final fileExists = await File(localPath).exists();
          debugPrint('🎤 File exists at path: $fileExists');

          if (fileExists) {
            _trackPaths[trackType] = localPath;
            debugPrint('🎤 ✅ Found local ${trackType.displayName} track: $localPath');
          } else {
            debugPrint('🎤 ❌ File does not exist at path: $localPath');
          }
        } else {
          debugPrint('🎤 ❌ No local path found for ${trackType.displayName}');
        }

        if (localPath == null || !await File(localPath).exists()) {
          // Download the track using the API download URL
          debugPrint('🎤 Downloading ${trackType.displayName} track from: ${trackDownload.downloadUrl}');
          final success = await _downloadManager.downloadTrack(
            widget.song.id,
            trackType,
            trackDownload.downloadUrl,
            fileSize: trackDownload.fileSize,
            duration: trackDownload.duration,
          );

          if (success) {
            final downloadedPath = _downloadManager.getLocalPath(widget.song.id, trackType);
            if (downloadedPath != null) {
              _trackPaths[trackType] = downloadedPath;
              debugPrint('🎤 ✅ Downloaded ${trackType.displayName} track: $downloadedPath');
            } else {
              debugPrint('🎤 ❌ Failed to get downloaded path for ${trackType.displayName}');
            }
          } else {
            debugPrint('🎤 ❌ Failed to download ${trackType.displayName} track');
          }
        }

        completedTracks++;
        setState(() {
          _downloadProgress = completedTracks / totalTracks;
        });
      }

      // Set up audio sources for all tracks
      await _setupAudioSources(trackDownloads: trackDownloads);

      debugPrint('🎤 Multi-track karaoke player initialized successfully');
    } catch (e) {
      debugPrint('🎤 Error loading tracks: $e');
      setState(() {
        _isLoading = false;
        _isDownloading = false;
        _loadingMessage = 'Error loading tracks: $e';
      });
    }
  }

  /// Fallback method to load tracks from song karaoke data
  Future<void> _loadTracksFromSongData(List<KaraokeTrack> tracks) async {
    try {
      int completedTracks = 0;
      final totalTracks = tracks.length;

      for (final track in tracks) {
        setState(() {
          _loadingMessage = 'Processing ${track.trackType.displayName.toLowerCase()} track...';
        });

        // Check if track is already downloaded
        debugPrint('🎤 [Fallback] Checking for local track: ${track.trackType.displayName} for song ID: ${widget.song.id}');
        final localPath = _downloadManager.getLocalPath(widget.song.id, track.trackType);

        if (localPath != null && await File(localPath).exists()) {
          _trackPaths[track.trackType] = localPath;
          debugPrint('🎤 [Fallback] ✅ Found local ${track.trackType.displayName} track: $localPath');
        } else {
          // Download the track using the song's track URL
          debugPrint('🎤 [Fallback] Downloading ${track.trackType.displayName} track from: ${track.fileUrl}');
          final success = await _downloadManager.downloadTrack(
            widget.song.id,
            track.trackType,
            track.fileUrl,
            fileSize: track.fileSize ?? 0,
            duration: track.duration ?? 0,
          );

          if (success) {
            final downloadedPath = _downloadManager.getLocalPath(widget.song.id, track.trackType);
            if (downloadedPath != null) {
              _trackPaths[track.trackType] = downloadedPath;
              debugPrint('🎤 [Fallback] ✅ Downloaded ${track.trackType.displayName} track: $downloadedPath');
            }
          }
        }

        completedTracks++;
        setState(() {
          _downloadProgress = completedTracks / totalTracks;
        });
      }

      // Set up audio sources for all tracks
      await _setupAudioSources(tracks: tracks);

    } catch (e) {
      debugPrint('🎤 Error in fallback track loading: $e');
      setState(() {
        _isLoading = false;
        _isDownloading = false;
        _loadingMessage = 'Error loading tracks: $e';
      });
    }
  }

  /// Set up audio sources for all downloaded tracks
  Future<void> _setupAudioSources({
    Map<TrackType, KaraokeTrackDownload>? trackDownloads,
    List<KaraokeTrack>? tracks,
  }) async {
    setState(() {
      _loadingMessage = 'Synchronizing AI-separated tracks...';
    });

    int successfulTracks = 0;
    for (final entry in _trackPaths.entries) {
      if (entry.value != null) {
        try {
          debugPrint('🎤 Setting up audio source for ${entry.key.displayName}: ${entry.value}');

          // Set the source but don't start playing yet
          await _audioPlayers[entry.key]!.setSourceDeviceFile(entry.value!);

          // Set initial volume based on track settings
          if (trackDownloads != null && trackDownloads.containsKey(entry.key)) {
            // Use API track download data
            final trackDownload = trackDownloads[entry.key]!;
            _trackVolumes[entry.key] = trackDownload.volume;
            _trackMuted[entry.key] = trackDownload.isMuted;

            final initialVolume = trackDownload.isMuted ? 0.0 : trackDownload.volume;
            await _audioPlayers[entry.key]!.setVolume(initialVolume);

            debugPrint('🎤 Set ${entry.key.displayName} volume: $initialVolume (muted: ${trackDownload.isMuted})');
          } else if (tracks != null) {
            // Use song karaoke track data
            final track = tracks.firstWhere((t) => t.trackType == entry.key, orElse: () => tracks.first);
            _trackVolumes[entry.key] = track.volume;
            _trackMuted[entry.key] = track.isMuted;

            final initialVolume = track.isMuted ? 0.0 : track.volume;
            await _audioPlayers[entry.key]!.setVolume(initialVolume);

            debugPrint('🎤 Set ${entry.key.displayName} volume: $initialVolume (muted: ${track.isMuted})');
          } else {
            // Fallback to default settings
            _trackVolumes[entry.key] = 1.0;
            _trackMuted[entry.key] = false;
            await _audioPlayers[entry.key]!.setVolume(1.0);

            debugPrint('🎤 Set ${entry.key.displayName} to default volume: 1.0');
          }

          // Set player mode to allow multiple instances
          await _audioPlayers[entry.key]!.setPlayerMode(PlayerMode.mediaPlayer);

          // Set audio context to allow simultaneous playback
          await _audioPlayers[entry.key]!.setAudioContext(AudioContext(
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: true,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.none, // Don't request audio focus to allow multiple players
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {
                AVAudioSessionOptions.mixWithOthers, // Allow mixing with other audio
              },
            ),
          ));

          debugPrint('🎤 Successfully set up ${entry.key.displayName} track');
          successfulTracks++;
        } catch (e) {
          debugPrint('🎤 Error setting up ${entry.key.displayName} track: $e');
          // Remove the failed track from our paths so it won't be used in playback
          _trackPaths.remove(entry.key);
        }
      } else {
        debugPrint('🎤 No path available for ${entry.key.displayName} track');
      }
    }

    final totalExpected = trackDownloads?.length ?? tracks?.length ?? 0;
    debugPrint('🎤 Successfully set up $successfulTracks out of $totalExpected tracks');
    debugPrint('🎤 Available tracks for playback: ${_trackPaths.keys.map((k) => k.displayName).join(', ')}');

    if (successfulTracks == 0) {
      throw Exception('No tracks were successfully loaded');
    }

    // Set up master track for synchronization (prefer vocals, then first available)
    _setupMasterTrack();

    // Start track health monitoring
    _startTrackHealthMonitoring();

    // Start continuous sync verification
    _startSyncVerification();

    setState(() {
      _isLoading = false;
      _isDownloading = false;
      _loadingMessage = '';
    });
  }

  void _setupMasterTrack() {
    // Prefer vocals as master, then first available track
    if (_trackPaths.containsKey(TrackType.vocals)) {
      _masterTrack = TrackType.vocals;
    } else {
      _masterTrack = _trackPaths.keys.first;
    }

    debugPrint('🎤 Setting up master track: ${_masterTrack!.displayName}');

    // Set up duration detection from all tracks to get the longest duration
    _detectAndSetDuration();

    // Set up player state listener on master track (for debugging only)
    _audioPlayers[_masterTrack]!.onPlayerStateChanged.listen((state) {
      debugPrint('🎤 Master track state changed: $state');
      // Don't automatically update _isPlaying here to avoid conflicts
    });

    debugPrint('🎤 Master track listeners set up successfully');

    // Start enhanced position tracking
    _startEnhancedPositionTracking();
  }

  Future<void> _detectAndSetDuration() async {
    debugPrint('🎤 🕐 Detecting duration from all tracks...');

    // Get duration from all tracks and use the longest one
    Duration longestDuration = Duration.zero;
    final trackDurations = <TrackType, Duration>{};

    for (final entry in _trackPaths.entries) {
      if (entry.value != null && _audioPlayers[entry.key] != null) {
        try {
          // Try to get duration immediately
          Duration? duration = await _audioPlayers[entry.key]!.getDuration();

          // If duration is not available yet, set up a listener
          if (duration == null || duration == Duration.zero) {
            _audioPlayers[entry.key]!.onDurationChanged.listen((newDuration) {
              if (mounted && newDuration > Duration.zero) {
                trackDurations[entry.key] = newDuration;
                debugPrint('🎤 ${entry.key.displayName} duration: ${newDuration.inSeconds}s');

                // Update the longest duration
                Duration currentLongest = Duration.zero;
                for (final d in trackDurations.values) {
                  if (d > currentLongest) {
                    currentLongest = d;
                  }
                }

                if (currentLongest > _duration) {
                  setState(() {
                    _duration = currentLongest;
                  });
                  debugPrint('🎤 ✅ Updated song duration to: ${_duration.inSeconds}s from ${entry.key.displayName}');
                }
              }
            });
          } else {
            trackDurations[entry.key] = duration;
            debugPrint('🎤 ${entry.key.displayName} duration: ${duration.inSeconds}s');

            if (duration > longestDuration) {
              longestDuration = duration;
            }
          }
        } catch (e) {
          debugPrint('🎤 ❌ Error getting duration for ${entry.key.displayName}: $e');
        }
      }
    }

    // Set the longest duration found
    if (longestDuration > Duration.zero) {
      setState(() {
        _duration = longestDuration;
      });
      debugPrint('🎤 ✅ Set song duration to: ${_duration.inSeconds}s (longest track)');
    }

    // Log all track durations
    debugPrint('🎤 📊 TRACK DURATIONS:');
    for (final entry in trackDurations.entries) {
      debugPrint('🎤   ${entry.key.displayName}: ${entry.value.inSeconds}s');
    }
  }

  void _startEnhancedPositionTracking() {
    _positionTimer?.cancel();

    // Use high-frequency polling for accurate position updates
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted || _isSeeking) return;

      try {
        // Get position from master track
        final masterPosition = await _audioPlayers[_masterTrack]?.getCurrentPosition();

        if (masterPosition != null) {
          // Update position if it's different from last known
          if ((masterPosition.inMilliseconds - _lastKnownPosition.inMilliseconds).abs() > 50) {
            _lastKnownPosition = masterPosition;

            if (mounted) {
              setState(() {
                _position = masterPosition;
              });
            }
          }

          // Store position for this track
          _trackPositions[_masterTrack!] = masterPosition;

          // Periodically verify sync (every 2 seconds during playback)
          if (_isPlaying && timer.tick % 20 == 0) {
            _verifyAndCorrectSync();
          }
        }
      } catch (e) {
        debugPrint('🎤 Error in position tracking: $e');
      }
    });
  }

  Future<void> _verifyAndCorrectSync() async {
    if (_isSeeking || !_isPlaying) return;

    try {
      // Get positions from all tracks
      final positions = <TrackType, Duration>{};
      for (final trackType in _trackPaths.keys) {
        if (_audioPlayers[trackType] != null) {
          final pos = await _audioPlayers[trackType]!.getCurrentPosition();
          if (pos != null) {
            positions[trackType] = pos;
          }
        }
      }

      if (positions.isEmpty) return;

      // Find the reference position (master track)
      final masterPos = positions[_masterTrack];
      if (masterPos == null) return;

      // Check for tracks that are out of sync (reduced to 100ms for tighter sync)
      final outOfSyncTracks = <TrackType>[];
      for (final entry in positions.entries) {
        final diff = (entry.value.inMilliseconds - masterPos.inMilliseconds).abs();
        if (diff > 100) {
          debugPrint('🎤 ⚠️ SYNC DRIFT: ${entry.key.displayName} out of sync by ${diff}ms (master: ${masterPos.inMilliseconds}ms)');
          outOfSyncTracks.add(entry.key);
        }
      }

      // Correct out-of-sync tracks immediately
      if (outOfSyncTracks.isNotEmpty) {
        debugPrint('🎤 🔧 AUTO-CORRECTING ${outOfSyncTracks.length} out-of-sync tracks to ${masterPos.inMilliseconds}ms');
        final correctionFutures = <Future>[];
        for (final trackType in outOfSyncTracks) {
          if (_audioPlayers[trackType] != null) {
            correctionFutures.add(_audioPlayers[trackType]!.seek(masterPos));
          }
        }
        await Future.wait(correctionFutures);

        // Verify correction worked
        await Future.delayed(const Duration(milliseconds: 50));
        for (final trackType in outOfSyncTracks) {
          if (_audioPlayers[trackType] != null) {
            final newPos = await _audioPlayers[trackType]!.getCurrentPosition();
            final newDiff = (newPos?.inMilliseconds ?? 0 - masterPos.inMilliseconds).abs();
            if (newDiff <= 100) {
              debugPrint('🎤 ✅ ${trackType.displayName} corrected successfully (diff: ${newDiff}ms)');
            } else {
              debugPrint('🎤 ❌ ${trackType.displayName} correction failed (diff: ${newDiff}ms)');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🎤 ❌ Error in sync verification: $e');
    }
  }

  void _startTrackHealthMonitoring() {
    // Monitor track health every 2 seconds
    _trackHealthTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final expectedPlaying = _isPlaying;
      final actualPlayingCount = _playingTrackCount;
      final totalTracks = _trackPaths.length;

      debugPrint('🎤 Track Health Check: Expected playing: $expectedPlaying, '
          'Actually playing: $actualPlayingCount/$totalTracks tracks');

      // Check for track sync issues
      if (expectedPlaying && actualPlayingCount < totalTracks) {
        debugPrint('🎤 WARNING: Not all tracks are playing! Expected: $totalTracks, Playing: $actualPlayingCount');

        // Log individual track states
        for (final entry in _trackStates.entries) {
          debugPrint('🎤 ${entry.key.displayName}: ${entry.value} (Playing: ${_trackPlayingStatus[entry.key]})');
        }
      }

      // Auto-recovery attempt if tracks are out of sync
      if (expectedPlaying && actualPlayingCount == 0) {
        debugPrint('🎤 CRITICAL: No tracks playing when they should be! Attempting recovery...');
        _attemptTrackRecovery();
      }
    });
  }

  void _startSyncVerification() {
    // Monitor sync every 3 seconds during playback
    _syncVerificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Only check sync when playing
      if (!_isPlaying || _trackPaths.isEmpty) {
        return;
      }

      try {
        // Get current positions of all tracks
        final positions = <TrackType, Duration>{};
        for (final entry in _trackPaths.entries) {
          if (entry.value != null && _audioPlayers[entry.key] != null) {
            final currentPos = await _audioPlayers[entry.key]!.getCurrentPosition();
            positions[entry.key] = currentPos ?? Duration.zero;
          }
        }

        if (positions.isEmpty) return;

        // Calculate average position
        final totalMs = positions.values.fold(0, (sum, pos) => sum + pos.inMilliseconds);
        final avgMs = totalMs / positions.length;
        final avgPosition = Duration(milliseconds: avgMs.round());

        // Check for tracks that are significantly out of sync (>200ms)
        final outOfSyncTracks = <TrackType>[];
        for (final entry in positions.entries) {
          final diff = (entry.value.inMilliseconds - avgMs).abs();
          if (diff > 200) {
            debugPrint('🎤 SYNC DRIFT: ${entry.key.displayName} is ${diff.round()}ms out of sync');
            outOfSyncTracks.add(entry.key);
          }
        }

        // Auto-correct significant drift
        if (outOfSyncTracks.isNotEmpty) {
          debugPrint('🎤 AUTO-CORRECTING ${outOfSyncTracks.length} tracks with sync drift');
          final correctionFutures = <Future>[];
          for (final trackType in outOfSyncTracks) {
            if (_audioPlayers[trackType] != null) {
              correctionFutures.add(_audioPlayers[trackType]!.seek(avgPosition));
            }
          }
          await Future.wait(correctionFutures);
        }
      } catch (e) {
        debugPrint('🎤 Error in sync verification: $e');
      }
    });
  }

  Future<void> _attemptTrackRecovery() async {
    try {
      debugPrint('🎤 Attempting track recovery...');

      // Try to restart all tracks
      final playFutures = <Future>[];
      for (final entry in _trackPaths.entries) {
        if (entry.value != null && _audioPlayers[entry.key] != null) {
          debugPrint('🎤 Recovery: Restarting ${entry.key.displayName} track');
          playFutures.add(_audioPlayers[entry.key]!.play(DeviceFileSource(entry.value!)));
        }
      }

      await Future.wait(playFutures);
      debugPrint('🎤 Track recovery completed');
    } catch (e) {
      debugPrint('🎤 Track recovery failed: $e');
    }
  }

  Future<void> _playPause() async {
    try {
      final currentlyPlaying = _isPlaying;
      debugPrint('🎤 Play/Pause clicked. Current state: _isPlaying = $currentlyPlaying');
      debugPrint('🎤 Available tracks: ${_trackPaths.keys.map((k) => k.displayName).join(', ')}');
      debugPrint('🎤 Has played before: $_hasPlayedBefore');

      if (currentlyPlaying) {
        // Pause all tracks simultaneously
        await _pauseAllTracks();
      } else {
        // Start/resume all tracks
        if (!_hasPlayedBefore) {
          await _startAllTracksFirstTime();
        } else {
          await _resumeAllTracks();
        }
      }

      debugPrint('🎤 Play/Pause completed. New state: _isPlaying = $_isPlaying');
    } catch (e) {
      debugPrint('🎤 Error in _playPause: $e');
    }
  }

  Future<void> _pauseAllTracks() async {
    debugPrint('🎤 Pausing all tracks simultaneously...');

    final pauseFutures = <Future>[];
    for (final entry in _trackPaths.entries) {
      if (entry.value != null && _audioPlayers[entry.key] != null) {
        pauseFutures.add(_audioPlayers[entry.key]!.pause());
      }
    }

    await Future.wait(pauseFutures);

    setState(() {
      _isPlaying = false;
    });

    debugPrint('🎤 All tracks paused successfully');
  }

  Future<void> _startAllTracksFirstTime() async {
    debugPrint('🎤 🚀 Starting all tracks for the first time - ZERO delay approach');

    // Preload all tracks first
    if (!_isPreloaded) {
      await _preloadAllTracks();
    }

    // Get all valid track entries
    final trackEntries = _trackPaths.entries.where((entry) =>
        entry.value != null && _audioPlayers[entry.key] != null).toList();

    debugPrint('🎤 Starting ${trackEntries.length} tracks simultaneously...');

    // Start ALL tracks at exactly the same time - no delays
    final startFutures = <Future>[];
    for (final entry in trackEntries) {
      debugPrint('🎤 Queuing start for ${entry.key.displayName} track');
      startFutures.add(_audioPlayers[entry.key]!.play(DeviceFileSource(entry.value!)));
    }

    // Wait for all tracks to start
    await Future.wait(startFutures);

    // Log positions immediately after start
    await _logAllTrackPositions("IMMEDIATELY AFTER START");

    // Immediate sync to position 0 to ensure perfect alignment
    debugPrint('🎤 Performing immediate sync to position 0');
    await _synchronizeAllTracksToPosition(Duration.zero);

    _hasPlayedBefore = true;
    setState(() {
      _isPlaying = true;
    });

    // Final position check
    await _logAllTrackPositions("FINAL FIRST-TIME START");

    debugPrint('🎤 ✅ All tracks started and synced perfectly');
  }

  Future<void> _preloadAllTracks() async {
    debugPrint('🎤 Preloading all tracks for instant startup...');

    final preloadFutures = <Future>[];
    for (final entry in _trackPaths.entries) {
      if (entry.value != null && _audioPlayers[entry.key] != null) {
        // Set source but don't play yet
        preloadFutures.add(_audioPlayers[entry.key]!.setSourceDeviceFile(entry.value!));
      }
    }

    await Future.wait(preloadFutures);
    _isPreloaded = true;

    debugPrint('🎤 All tracks preloaded successfully');
  }

  Future<void> _resumeAllTracks() async {
    debugPrint('🎤 🔄 Resuming all tracks from position: ${_position.inSeconds}s (${_position.inMilliseconds}ms)');

    // First, ensure all tracks are at the exact same position
    await _synchronizeAllTracksToPosition(_position);

    // Log positions before resume
    await _logAllTrackPositions("BEFORE RESUME");

    // Then resume all tracks simultaneously
    debugPrint('🎤 Starting simultaneous resume of all tracks...');
    final resumeFutures = <Future>[];
    for (final entry in _trackPaths.entries) {
      if (entry.value != null && _audioPlayers[entry.key] != null) {
        debugPrint('🎤 Queuing resume for ${entry.key.displayName}');
        resumeFutures.add(_audioPlayers[entry.key]!.resume());
      }
    }

    // Wait for all tracks to resume
    await Future.wait(resumeFutures);

    setState(() {
      _isPlaying = true;
    });

    // Verify sync after resume
    await Future.delayed(const Duration(milliseconds: 100));
    await _logAllTrackPositions("AFTER RESUME");

    debugPrint('🎤 ✅ All tracks resumed successfully');
  }

  Future<void> _seek(Duration position) async {
    try {
      debugPrint('🎤 🎯 SEEKING to position: ${position.inSeconds}s (${position.inMilliseconds}ms)');

      _isSeeking = true;

      // Store the playing state
      final wasPlaying = _isPlaying;

      // Pause all tracks first for clean seeking
      if (wasPlaying) {
        debugPrint('🎤 Pausing all tracks before seek...');
        await _pauseAllTracks();
      }

      // Perform synchronized seek to exact position
      debugPrint('🎤 Synchronizing all tracks to position: ${position.inSeconds}s');
      await _synchronizeAllTracksToPosition(position);

      // Update UI position immediately
      setState(() {
        _position = position;
        _lastKnownPosition = position;
      });

      // Resume if was playing
      if (wasPlaying) {
        debugPrint('🎤 Resuming all tracks after seek...');
        await _resumeAllTracks();
      }

      _isSeeking = false;
      debugPrint('🎤 ✅ Seek completed successfully to ${position.inSeconds}s');
    } catch (e) {
      _isSeeking = false;
      debugPrint('🎤 ❌ Error seeking: $e');
    }
  }

  Future<void> _synchronizeAllTracksToPosition(Duration position) async {
    debugPrint('🎤 🎯 Synchronizing all tracks to position: ${position.inSeconds}s (${position.inMilliseconds}ms)');

    // Log current positions before seeking
    await _logAllTrackPositions("BEFORE SEEK");

    // Seek all tracks simultaneously to the exact position
    final seekFutures = <Future>[];
    for (final entry in _trackPaths.entries) {
      if (entry.value != null && _audioPlayers[entry.key] != null) {
        debugPrint('🎤 Seeking ${entry.key.displayName} to ${position.inMilliseconds}ms');
        seekFutures.add(_audioPlayers[entry.key]!.seek(position));
      }
    }

    // Wait for all seeks to complete
    await Future.wait(seekFutures);

    // Small delay to ensure all players have processed the seek
    await Future.delayed(const Duration(milliseconds: 50));

    // Log positions after seeking
    await _logAllTrackPositions("AFTER SEEK");

    // Verify all tracks are at the correct position
    await _verifyPositionSync(position);
  }

  Future<void> _logAllTrackPositions(String context) async {
    debugPrint('🎤 📊 TRACK POSITIONS - $context:');
    for (final entry in _trackPaths.entries) {
      if (entry.value != null && _audioPlayers[entry.key] != null) {
        try {
          final currentPos = await _audioPlayers[entry.key]!.getCurrentPosition();
          final duration = await _audioPlayers[entry.key]!.getDuration();
          debugPrint('🎤   ${entry.key.displayName}: ${currentPos?.inMilliseconds ?? 0}ms / ${duration?.inMilliseconds ?? 0}ms');
        } catch (e) {
          debugPrint('🎤   ${entry.key.displayName}: ERROR - $e');
        }
      }
    }
  }

  Future<void> _verifyPositionSync(Duration targetPosition) async {
    debugPrint('🎤 🔍 Verifying position sync at ${targetPosition.inSeconds}s (${targetPosition.inMilliseconds}ms)');

    final positions = <TrackType, Duration>{};
    for (final entry in _trackPaths.entries) {
      if (entry.value != null && _audioPlayers[entry.key] != null) {
        try {
          final currentPos = await _audioPlayers[entry.key]!.getCurrentPosition();
          positions[entry.key] = currentPos ?? Duration.zero;
          debugPrint('🎤   ${entry.key.displayName}: ${currentPos?.inMilliseconds ?? 0}ms (target: ${targetPosition.inMilliseconds}ms)');
        } catch (e) {
          debugPrint('🎤 ❌ Error getting position for ${entry.key.displayName}: $e');
        }
      }
    }

    // Check for tracks that are out of sync (reduced tolerance to 50ms for better sync)
    final targetMs = targetPosition.inMilliseconds;
    final outOfSyncTracks = <TrackType>[];

    for (final entry in positions.entries) {
      final diff = (entry.value.inMilliseconds - targetMs).abs();
      if (diff > 50) {
        debugPrint('🎤 ⚠️ ${entry.key.displayName} out of sync by ${diff}ms (tolerance: 50ms)');
        outOfSyncTracks.add(entry.key);
      } else {
        debugPrint('🎤 ✅ ${entry.key.displayName} in sync (diff: ${diff}ms)');
      }
    }

    // Correct out-of-sync tracks with multiple attempts
    if (outOfSyncTracks.isNotEmpty) {
      debugPrint('🎤 🔧 Correcting ${outOfSyncTracks.length} out-of-sync tracks');

      for (int attempt = 1; attempt <= 2; attempt++) {
        debugPrint('🎤 Correction attempt $attempt');
        final correctionFutures = <Future>[];
        for (final trackType in outOfSyncTracks) {
          if (_audioPlayers[trackType] != null) {
            correctionFutures.add(_audioPlayers[trackType]!.seek(targetPosition));
          }
        }
        await Future.wait(correctionFutures);

        // Small delay between attempts
        await Future.delayed(const Duration(milliseconds: 30));

        // Verify correction worked
        bool allCorrected = true;
        for (final trackType in outOfSyncTracks) {
          if (_audioPlayers[trackType] != null) {
            final newPos = await _audioPlayers[trackType]!.getCurrentPosition();
            final newDiff = (newPos?.inMilliseconds ?? 0 - targetMs).abs();
            if (newDiff > 50) {
              allCorrected = false;
              debugPrint('🎤 ⚠️ ${trackType.displayName} still out of sync by ${newDiff}ms after attempt $attempt');
            } else {
              debugPrint('🎤 ✅ ${trackType.displayName} corrected (diff: ${newDiff}ms)');
            }
          }
        }

        if (allCorrected) {
          debugPrint('🎤 ✅ All tracks corrected successfully');
          break;
        }
      }
    } else {
      debugPrint('🎤 ✅ All tracks are in perfect sync');
    }
  }



  Future<void> _stopAllTracks() async {
    try {
      debugPrint('🎤 Stopping all tracks with sync reset');

      // Stop sync verification during stop operation
      _syncVerificationTimer?.cancel();

      final stopFutures = <Future>[];
      for (final entry in _trackPaths.entries) {
        if (entry.value != null && _audioPlayers[entry.key] != null) {
          debugPrint('🎤 Stopping ${entry.key.displayName} track');
          stopFutures.add(_audioPlayers[entry.key]!.stop());
        }
      }

      await Future.wait(stopFutures);

      // Reset all sync-related state
      setState(() {
        _isPlaying = false;
        _hasPlayedBefore = false;
        _position = Duration.zero;
      });

      // Restart sync verification for next playback
      _startSyncVerification();

      debugPrint('🎤 All tracks stopped and sync reset');
    } catch (e) {
      debugPrint('🎤 Error stopping tracks: $e');
    }
  }

  Future<void> _toggleTrackMute(TrackType trackType) async {
    try {
      final isMuted = !(_trackMuted[trackType] ?? false);
      _trackMuted[trackType] = isMuted;

      final volume = isMuted ? 0.0 : (_trackVolumes[trackType] ?? 1.0);

      // Only set volume if the track has a valid source
      if (_trackPaths[trackType] != null && _audioPlayers[trackType] != null) {
        await _audioPlayers[trackType]!.setVolume(volume);
        debugPrint('🎤 ${isMuted ? 'Muted' : 'Unmuted'} ${trackType.displayName} track (volume: $volume)');
      }

      setState(() {});
    } catch (e) {
      debugPrint('🎤 Error toggling mute for ${trackType.displayName}: $e');
    }
  }

  Future<void> _setTrackVolume(TrackType trackType, double volume) async {
    try {
      _trackVolumes[trackType] = volume;

      // Only set volume if the track is not muted and has a valid source
      if (!(_trackMuted[trackType] ?? false) &&
          _trackPaths[trackType] != null &&
          _audioPlayers[trackType] != null) {
        await _audioPlayers[trackType]!.setVolume(volume);
        debugPrint('🎤 Set ${trackType.displayName} volume to $volume');
      }

      setState(() {});
    } catch (e) {
      debugPrint('🎤 Error setting volume for ${trackType.displayName}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.song.title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.displayFontFamily,
            letterSpacing: -0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.background,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Multi-Track'),
            Tab(text: 'Lyrics'),
          ],
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildPlayerContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI Processing Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'AI-Powered Karaoke',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: AppTheme.displayFontFamily,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            _loadingMessage,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_downloadProgress * 100).toInt()}% Complete',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ] else ...[
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerContent() {
    return Column(
      children: [
        // Tab content area
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMultiTrackTab(),
              _buildLyricsTab(),
            ],
          ),
        ),

        // Bottom player controls (always visible)
        _buildBottomPlayerControls(),
      ],
    );
  }

  Widget _buildMultiTrackTab() {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Track Status Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.multitrack_audio,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-Track Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_playingTrackCount/${_trackPaths.length} tracks playing',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _playingTrackCount == _trackPaths.length && _isPlaying
                          ? Colors.green
                          : _playingTrackCount > 0 && _isPlaying
                              ? Colors.orange
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Track Controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: TrackType.values.map((trackType) {
                return _buildTrackControl(trackType);
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTrackControl(TrackType trackType) {
    final isMuted = _trackMuted[trackType] ?? false;
    final volume = _trackVolumes[trackType] ?? 1.0;
    final icon = _trackIcons[trackType] ?? Icons.music_note;
    final color = _trackColors[trackType] ?? AppTheme.primary;
    final hasTrack = _trackPaths.containsKey(trackType);
    final isPlaying = _trackPlayingStatus[trackType] ?? false;
    final trackState = _trackStates[trackType] ?? PlayerState.stopped;

    return Opacity(
      opacity: hasTrack ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
        children: [
          // Track Icon with Status Indicator
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: isPlaying ? color : color.withValues(alpha: 0.3),
                width: isPlaying ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                // Playing indicator
                if (isPlaying)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                // Error indicator
                if (hasTrack && !isPlaying && _isPlaying)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Volume Slider
          Expanded(
            child: Column(
              children: [
                // Track name with status
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        trackType.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasTrack ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasTrack)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPlaying ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPlaying ? 'PLAYING' : trackState.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: isPlaying ? Colors.green : Colors.grey,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Custom Slider that looks like Moises
                SizedBox(
                  height: 32,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                        pressedElevation: 6,
                      ),
                      thumbColor: color,
                      activeTrackColor: color,
                      inactiveTrackColor: color.withValues(alpha: 0.2),
                      overlayColor: color.withValues(alpha: 0.1),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Slider(
                      value: isMuted ? 0.0 : volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: hasTrack ? (value) {
                        if (value == 0.0 && !isMuted) {
                          _toggleTrackMute(trackType);
                        } else if (value > 0.0 && isMuted) {
                          _toggleTrackMute(trackType);
                          _setTrackVolume(trackType, value);
                        } else if (!isMuted) {
                          _setTrackVolume(trackType, value);
                        }
                      } : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildBottomPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Progress Bar
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      thumbColor: AppTheme.primary,
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.border,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0.0,
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds: (value * _duration.inMilliseconds).round(),
                        );
                        _seek(newPosition);
                      },
                    ),
                  ),
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Player Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Metronome Button
              _buildControlButton(
                icon: Icons.av_timer,
                onTap: () {
                  // TODO: Toggle metronome
                },
              ),

              // Previous/Stop Button
              _buildControlButton(
                icon: Icons.stop,
                onTap: _stopAllTracks,
              ),

              // Play/Pause Button
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _playPause,
                    borderRadius: BorderRadius.circular(32),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Next Button
              _buildControlButton(
                icon: Icons.skip_next,
                onTap: () {
                  _seek(_duration);
                },
              ),

              // Playlist Button
              _buildControlButton(
                icon: Icons.playlist_play,
                onTap: () {
                  // TODO: Show playlist
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.background,
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Icon(
            icon,
            color: AppTheme.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsTab() {
    // Use the song with chord sheet data if available, otherwise use the original song
    final songToUse = _songWithChords ?? widget.song;

    return Container(
      padding: const EdgeInsets.all(24),
      child: KaraokeLyricsView(
        song: songToUse,
        position: _position,
        duration: _duration,
        isPlaying: _isPlaying,
        onPlayPause: _playPause,
        onSeek: _seek,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
