import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/simple_metronome_service.dart';
import '../services/chord_timing_service.dart';
import '../services/metronome_audio_service.dart';
import '../config/theme.dart';

class PracticeModeScreen extends StatefulWidget {
  final Map<String, dynamic> songData;

  const PracticeModeScreen({
    super.key,
    required this.songData,
  });

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen>
    with TickerProviderStateMixin {
  late SimpleMetronomeService _metronomeService;
  late ChordTimingService _chordTimingService;

  // Auto-scroll controller
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  final double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _metronomeService = SimpleMetronomeService();
    _chordTimingService = ChordTimingService();

    // Set up song data
    _initializeSong();

    // Keep screen awake during practice
    WakelockPlus.enable();
  }

  void _initializeSong() async {
    // Initialize audio service first
    await _metronomeService.initialize();

    // Set original tempo from song data
    int originalTempo = widget.songData['tempo'] ?? 120;
    _metronomeService.bpm = originalTempo;

    debugPrint('🎵 Initialized song: ${widget.songData['title']} at $originalTempo BPM');

    // Initialize chord timing with song data
    _chordTimingService.initializeWithSong(widget.songData);

    // Set time signature if available
    String? timeSignature = widget.songData['timeSignature'];
    if (timeSignature != null) {
      List<String> parts = timeSignature.split('/');
      if (parts.isNotEmpty) {
        int beatsPerMeasure = int.tryParse(parts[0]) ?? 4;
        _metronomeService.beatsPerMeasure = beatsPerMeasure;
        debugPrint('🎼 Time signature: $timeSignature ($beatsPerMeasure beats per measure)');
      }
    }
  }

  @override
  void dispose() {
    _metronomeService.stop();
    _metronomeService.dispose();
    _chordTimingService.dispose();
    _autoScrollTimer?.cancel();
    _scrollController.dispose();

    // Disable wakelock
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A1A),
                  AppTheme.primaryColor.withValues(alpha: 0.03),
                ],
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Clean header
              _buildCleanHeader(),

              // Current chord/section display
              _buildCurrentChordDisplay(),

              // Chord sheet
              Expanded(
                child: _buildImprovedChordSheet(),
              ),

              // Simple controls
              _buildSimpleControls(),
            ],
          ),
        ],
      ),
    );
  }

  // Clean minimal header
  Widget _buildCleanHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),

          // Song title
          Expanded(
            child: Text(
              widget.songData['title'] ?? 'Practice Mode',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Audio settings button
          IconButton(
            onPressed: _showAudioSettings,
            icon: const Icon(Icons.tune, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: const CircleBorder(),
            ),
          ),

          const SizedBox(width: 8),

          // BPM display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListenableBuilder(
              listenable: _metronomeService,
              builder: (context, child) {
                return Text(
                  '${_metronomeService.bpm}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Current chord and section display
  Widget _buildCurrentChordDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListenableBuilder(
        listenable: _chordTimingService,
        builder: (context, child) {
          return Row(
            children: [
              // Current section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECTION',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _chordTimingService.currentSection.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ],
                ),
              ),

              // Current chord
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _chordTimingService.currentChord ?? '—',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
              ),

              // Beat indicator
              const SizedBox(width: 16),
              ListenableBuilder(
                listenable: _metronomeService,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _metronomeService.isRunning
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _metronomeService.isRunning
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_metronomeService.currentBeat}',
                        style: TextStyle(
                          color: _metronomeService.isRunning
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Improved chord sheet display
  Widget _buildImprovedChordSheet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: _buildSimpleChordSheet(),
      ),
    );
  }

  // Simple, readable chord sheet
  Widget _buildSimpleChordSheet() {
    String chordSheet = widget.songData['chordSheet'] ?? '';
    List<String> lines = chordSheet.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _buildSimpleLine(line)).toList(),
    );
  }

  Widget _buildSimpleLine(String line) {
    if (line.trim().isEmpty) {
      return const SizedBox(height: 12);
    }

    // Section headers
    if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
      String sectionName = line.trim().substring(1, line.trim().length - 1);
      bool isCurrentSection = _chordTimingService.currentSection == sectionName.toLowerCase();

      return Container(
        margin: const EdgeInsets.only(top: 24, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentSection
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: isCurrentSection
              ? Border.all(color: AppTheme.primaryColor, width: 1)
              : null,
        ),
        child: Text(
          sectionName.toUpperCase(),
          style: TextStyle(
            color: isCurrentSection ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
      );
    }

    // Regular lines with chords and lyrics
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: _buildLineWithChords(line),
    );
  }

  Widget _buildLineWithChords(String line) {
    // Parse chords in square brackets
    RegExp chordRegex = RegExp(r'\[([^\]]+)\]');
    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (RegExpMatch match in chordRegex.allMatches(line)) {
      // Add text before chord
      if (match.start > lastEnd) {
        String text = line.substring(lastEnd, match.start);
        spans.add(TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: _fontSize,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ));
      }

      // Add chord
      String chord = match.group(1) ?? '';
      bool isCurrentChord = chord == _chordTimingService.currentChord;

      spans.add(WidgetSpan(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentChord
                ? AppTheme.primaryColor
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: isCurrentChord
                ? Border.all(color: Colors.white, width: 1)
                : null,
          ),
          child: Text(
            chord,
            style: TextStyle(
              color: isCurrentChord ? Colors.black : Colors.white,
              fontSize: _fontSize - 2,
              fontWeight: FontWeight.w700,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < line.length) {
      String text = line.substring(lastEnd);
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: _fontSize,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  // Simple bottom controls
  Widget _buildSimpleControls() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
      ),
      child: Row(
        children: [
          // Tempo controls
          IconButton(
            onPressed: () => _metronomeService.decreaseTempo(),
            icon: const Icon(Icons.remove, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: const CircleBorder(),
            ),
          ),

          const SizedBox(width: 16),

          // Play/pause button
          Expanded(
            child: ListenableBuilder(
              listenable: _metronomeService,
              builder: (context, child) {
                bool isPlaying = _metronomeService.isRunning || _metronomeService.isCountingIn;
                return GestureDetector(
                  onTap: () {
                    if (isPlaying) {
                      _stopPractice();
                    } else {
                      _startPractice();
                    }
                  },
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPlaying ? 'PAUSE' : 'PLAY',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          // Tempo increase
          IconButton(
            onPressed: () => _metronomeService.increaseTempo(),
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // Start practice with auto-scroll
  void _startPractice() {
    _metronomeService.start();
    _startAutoScroll();
    debugPrint('🎵 Started practice mode with auto-scroll');
  }

  // Stop practice and auto-scroll
  void _stopPractice() {
    _metronomeService.stop();
    _stopAutoScroll();
    debugPrint('⏹️ Stopped practice mode');
  }

  // Start auto-scroll
  void _startAutoScroll() {
    _stopAutoScroll(); // Stop any existing timer

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_scrollController.hasClients && _metronomeService.isRunning) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.offset;

        // Calculate scroll speed based on BPM (slower BPM = slower scroll)
        double scrollSpeed = (_metronomeService.bpm / 120.0) * 0.5;

        if (currentScroll < maxScroll) {
          _scrollController.animateTo(
            currentScroll + scrollSpeed,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  // Stop auto-scroll
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  // Show audio settings dialog
  void _showAudioSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Audio Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metronome Sound',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
            const SizedBox(height: 16),
            ...MetronomeAudioType.values.map((type) =>
              ListenableBuilder(
                listenable: _metronomeService,
                builder: (context, child) {
                  return RadioListTile<MetronomeAudioType>(
                    title: Text(
                      type.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                    value: type,
                    groupValue: _metronomeService.audioType,
                    onChanged: (value) {
                      if (value != null) {
                        _metronomeService.audioType = value;
                      }
                    },
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
