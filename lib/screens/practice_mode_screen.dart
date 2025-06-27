import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/simple_metronome_service.dart';
import '../services/chord_timing_service.dart';
import '../services/metronome_audio_service.dart';
import '../config/theme.dart';
import '../widgets/chord_diagram_bottom_sheet.dart';
import '../models/practice_models.dart';

class PracticeModeScreen extends StatefulWidget {
  final Map<String, dynamic> songData;

  const PracticeModeScreen({super.key, required this.songData});

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

  // Enhanced practice mode features
  PracticeDifficulty _currentDifficulty = PracticeDifficulty.beginner;
  bool _showChordDiagrams = true;
  bool _showChordTransitions = true;
  final int _chordChangeCountdown = 0;
  String? _nextChord;

  // Practice session tracking
  DateTime? _sessionStartTime;
  int _correctChordChanges = 0;
  int _totalChordChanges = 0;
  final List<String> _practiceLog = [];

  // Visual enhancements
  bool _showBeatVisualization = true;

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

    debugPrint(
      '🎵 Initialized song: ${widget.songData['title']} at $originalTempo BPM',
    );

    // Initialize chord timing with song data
    _chordTimingService.initializeWithSong(widget.songData);

    // Set time signature if available
    String? timeSignature = widget.songData['timeSignature'];
    if (timeSignature != null) {
      List<String> parts = timeSignature.split('/');
      if (parts.isNotEmpty) {
        int beatsPerMeasure = int.tryParse(parts[0]) ?? 4;
        _metronomeService.beatsPerMeasure = beatsPerMeasure;
        debugPrint(
          '🎼 Time signature: $timeSignature ($beatsPerMeasure beats per measure)',
        );
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

  /// Show chord diagram in bottom sheet
  void _showChordDiagram(String chordName) {
    // Clean up the chord name (remove any brackets)
    final cleanChordName = chordName.replaceAll(RegExp(r'[\[\]]'), '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ChordDiagramBottomSheet(chordName: cleanChordName),
          ),
    );
  }

  /// Start practice session tracking
  void _startPracticeSession() {
    setState(() {
      _sessionStartTime = DateTime.now();
      _correctChordChanges = 0;
      _totalChordChanges = 0;
      _practiceLog.clear();
    });
  }

  /// End practice session and save data
  void _endPracticeSession() {
    if (_sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      final accuracy =
          _totalChordChanges > 0
              ? _correctChordChanges / _totalChordChanges
              : 0.0;

      // Log practice session (could save to local storage or send to backend)
      debugPrint('Practice Session Complete:');
      debugPrint(
        '  Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s',
      );
      debugPrint('  Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%');
      debugPrint('  Chord Changes: $_correctChordChanges/$_totalChordChanges');
    }
  }

  /// Update difficulty level and adjust tempo
  void _changeDifficulty(PracticeDifficulty newDifficulty) {
    setState(() {
      _currentDifficulty = newDifficulty;
      final originalTempo = widget.songData['tempo'] ?? 120;
      final newTempo = (originalTempo * newDifficulty.tempoMultiplier).round();
      _metronomeService.bpm = newTempo;
    });
  }

  /// Toggle chord diagram visibility
  void _toggleChordDiagrams() {
    setState(() {
      _showChordDiagrams = !_showChordDiagrams;
    });
  }

  /// Toggle chord transition helpers
  void _toggleChordTransitions() {
    setState(() {
      _showChordTransitions = !_showChordTransitions;
    });
  }

  /// Show practice settings panel
  void _showPracticeSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPracticeSettingsPanel(),
    );
  }

  /// Build practice settings panel
  Widget _buildPracticeSettingsPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Practice Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Difficulty Level Section
                  _buildSettingsSection(
                    'Difficulty Level',
                    _buildDifficultySelector(),
                  ),

                  const SizedBox(height: 24),

                  // Practice Features Section
                  _buildSettingsSection(
                    'Practice Features',
                    Column(
                      children: [
                        _buildToggleOption(
                          'Show Chord Diagrams',
                          'Tap chords to see fingering positions',
                          _showChordDiagrams,
                          _toggleChordDiagrams,
                        ),
                        _buildToggleOption(
                          'Chord Transition Helpers',
                          'Visual countdown for chord changes',
                          _showChordTransitions,
                          _toggleChordTransitions,
                        ),
                        _buildToggleOption(
                          'Beat Visualization',
                          'Visual metronome indicator',
                          _showBeatVisualization,
                          () => setState(
                            () =>
                                _showBeatVisualization =
                                    !_showBeatVisualization,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Practice Session Section
                  _buildSettingsSection(
                    'Practice Session',
                    Column(
                      children: [
                        _buildActionButton(
                          'Start New Session',
                          'Begin tracking your practice progress',
                          Icons.play_circle_outline,
                          _sessionStartTime == null
                              ? _startPracticeSession
                              : null,
                        ),
                        if (_sessionStartTime != null) ...[
                          const SizedBox(height: 12),
                          _buildSessionStats(),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build settings section with title and content
  Widget _buildSettingsSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  /// Build difficulty selector
  Widget _buildDifficultySelector() {
    return Column(
      children:
          PracticeDifficulty.values.map((difficulty) {
            final isSelected = _currentDifficulty == difficulty;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  difficulty.displayName,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${(difficulty.tempoMultiplier * 100).round()}% tempo - ${difficulty.description}',
                  style: TextStyle(
                    color:
                        isSelected
                            ? AppTheme.primary.withValues(alpha: 0.8)
                            : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                leading: Radio<PracticeDifficulty>(
                  value: difficulty,
                  groupValue: _currentDifficulty,
                  onChanged: (value) {
                    if (value != null) {
                      _changeDifficulty(value);
                      Navigator.pop(context);
                    }
                  },
                  activeColor: AppTheme.primary,
                ),
                tileColor:
                    isSelected ? AppTheme.primary.withValues(alpha: 0.1) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side:
                      isSelected
                          ? BorderSide(color: AppTheme.primary)
                          : BorderSide.none,
                ),
              ),
            );
          }).toList(),
    );
  }

  /// Build toggle option
  Widget _buildToggleOption(
    String title,
    String subtitle,
    bool value,
    VoidCallback onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: (_) => onChanged(),
          activeColor: AppTheme.primary,
        ),
        tileColor: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? AppTheme.primary : Colors.grey,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// Build session statistics
  Widget _buildSessionStats() {
    if (_sessionStartTime == null) return const SizedBox.shrink();

    final duration = DateTime.now().difference(_sessionStartTime!);
    final accuracy =
        _totalChordChanges > 0
            ? (_correctChordChanges / _totalChordChanges * 100)
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Duration',
                '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
              ),
              _buildStatItem('Accuracy', '${accuracy.toStringAsFixed(1)}%'),
              _buildStatItem(
                'Changes',
                '$_correctChordChanges/$_totalChordChanges',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _endPracticeSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('End Session'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background color from theme
          Container(color: Theme.of(context).scaffoldBackgroundColor),

          // Main content
          Column(
            children: [
              // Clean header
              _buildCleanHeader(),

              // Current chord/section display
              _buildCurrentChordDisplay(),

              // Chord transition helper
              _buildChordTransitionHelper(),

              // Chord sheet
              Expanded(child: _buildImprovedChordSheet()),

              // Simple controls
              _buildSimpleControls(),
            ],
          ),
        ],
      ),
    );
  }

  // Compact header
  Widget _buildCleanHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 4,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
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

          // Practice settings button
          IconButton(
            onPressed: _showPracticeSettings,
            icon: const Icon(Icons.settings, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: const CircleBorder(),
            ),
          ),

          const SizedBox(width: 8),

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
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ListenableBuilder(
              listenable: _metronomeService,
              builder: (context, child) {
                return Text(
                  '${_metronomeService.bpm}',
                  style: TextStyle(
                    color: AppTheme.primary,
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
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

              // Current chord (tappable for diagram)
              GestureDetector(
                onTap: () {
                  final currentChord = _chordTimingService.currentChord;
                  if (currentChord != null && currentChord != '—') {
                    _showChordDiagram(currentChord);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _chordTimingService.currentChord ?? '—',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      if (_chordTimingService.currentChord != null &&
                          _chordTimingService.currentChord != '—') ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.touch_app,
                          color: Colors.black,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Beat indicator with enhanced visualization
              const SizedBox(width: 16),
              ListenableBuilder(
                listenable: _metronomeService,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _metronomeService.isRunning && _showBeatVisualization
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color:
                            _metronomeService.isRunning &&
                                    _showBeatVisualization
                                ? AppTheme.primary
                                : Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_metronomeService.currentBeat}',
                        style: TextStyle(
                          color:
                              _metronomeService.isRunning &&
                                      _showBeatVisualization
                                  ? AppTheme.primary
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

  /// Build chord transition helper (shows next chord and countdown)
  Widget _buildChordTransitionHelper() {
    if (!_showChordTransitions || !_metronomeService.isRunning) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Next: ',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _nextChord ?? 'Same chord',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_chordChangeCountdown > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$_chordChangeCountdown',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
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
      bool isCurrentSection =
          _chordTimingService.currentSection == sectionName.toLowerCase();

      return Container(
        margin: const EdgeInsets.only(top: 24, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isCurrentSection
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(5),
          border:
              isCurrentSection
                  ? Border.all(color: AppTheme.primary, width: 1)
                  : null,
        ),
        child: Text(
          sectionName.toUpperCase(),
          style: TextStyle(
            color:
                isCurrentSection
                    ? AppTheme.primary
                    : Colors.white.withValues(alpha: 0.8),
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
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: _fontSize,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        );
      }

      // Add chord
      String chord = match.group(1) ?? '';
      bool isCurrentChord = chord == _chordTimingService.currentChord;

      spans.add(
        WidgetSpan(
          child: GestureDetector(
            onTap: _showChordDiagrams ? () => _showChordDiagram(chord) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isCurrentChord
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
                border:
                    isCurrentChord
                        ? Border.all(color: Colors.white, width: 1)
                        : _showChordDiagrams
                        ? Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        )
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chord,
                    style: TextStyle(
                      color: isCurrentChord ? Colors.black : Colors.white,
                      fontSize: _fontSize - 2,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                  if (_showChordDiagrams) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color:
                          isCurrentChord
                              ? Colors.black
                              : AppTheme.primary.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < line.length) {
      String text = line.substring(lastEnd);
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: _fontSize,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
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
                bool isPlaying =
                    _metronomeService.isRunning ||
                    _metronomeService.isCountingIn;
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
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
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

  // Start practice with auto-scroll and session tracking
  void _startPractice() {
    // Start practice session if not already started
    if (_sessionStartTime == null) {
      _startPracticeSession();
    }

    // Set up chord change tracking
    _chordTimingService.onChordChange = (chord, beat) {
      setState(() {
        _nextChord = _chordTimingService.getNextChord();
        _totalChordChanges++;

        // For now, assume all chord changes are correct
        // In a real implementation, this could track user input
        _correctChordChanges++;
      });
    };

    _metronomeService.start();
    _startAutoScroll();
    debugPrint('🎵 Started practice mode with enhanced tracking');
  }

  // Stop practice and auto-scroll
  void _stopPractice() {
    _metronomeService.stop();
    _stopAutoScroll();

    // Clear chord change tracking
    _chordTimingService.onChordChange = null;

    debugPrint('⏹️ Stopped practice mode');
  }

  // Start auto-scroll
  void _startAutoScroll() {
    _stopAutoScroll(); // Stop any existing timer

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
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
      builder:
          (context) => AlertDialog(
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
                ...MetronomeAudioType.values.map(
                  (type) => ListenableBuilder(
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
                        activeColor: AppTheme.primary,
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
                    color: AppTheme.primary,
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
