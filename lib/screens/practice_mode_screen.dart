import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/professional_metronome_service.dart';
import '../config/theme.dart';
import '../widgets/chord_diagram_bottom_sheet.dart';

class PracticeModeScreen extends StatefulWidget {
  final Map<String, dynamic> songData;

  const PracticeModeScreen({super.key, required this.songData});

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  late ProfessionalMetronomeService _metronomeService;
  
  // Controllers
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _chordProgressionTimer;
  
  // Practice state
  bool _isPlaying = false;
  bool _metronomeEnabled = true;
  bool _autoScrollEnabled = true;
  bool _loopEnabled = false;
  

  
  // Song data
  String get _songTitle => widget.songData['title'] as String? ?? 'Unknown Song';
  String get _songContent => widget.songData['content'] as String? ?? '';
  int get _originalTempo => widget.songData['tempo'] as int? ?? 120;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing Practice Mode Screen...');

    // Force stop metronome first
    try {
      _metronomeService.stop();
      debugPrint('✅ Metronome stopped in dispose');
    } catch (e) {
      debugPrint('❌ Error stopping metronome in dispose: $e');
    }

    // Dispose metronome service
    try {
      _metronomeService.dispose();
      debugPrint('✅ Metronome service disposed');
    } catch (e) {
      debugPrint('❌ Error disposing metronome service: $e');
    }

    // Clean up other resources
    _autoScrollTimer?.cancel();
    _chordProgressionTimer?.cancel();
    _scrollController.dispose();
    WakelockPlus.disable();

    debugPrint('✅ Practice Mode Screen disposed');
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _metronomeService = ProfessionalMetronomeService();

    debugPrint('🎵 Initializing Professional metronome service...');
    await _metronomeService.initialize();

    _metronomeService.bpm = _originalTempo;
    _metronomeService.beatsPerMeasure = 4;
    _metronomeService.enabled = _metronomeEnabled;

    // Listen to metronome beats
    _metronomeService.onBeat = _onMetronomeBeat;

    debugPrint('✅ Professional metronome service initialized');
  }



  void _onMetronomeBeat(int beat, bool isAccented) {
    if (!mounted) return;

    // Update UI state for metronome visual feedback
    if (mounted) {
      setState(() {
        // This ensures the UI stays responsive to metronome beats
        // and can be used for visual indicators if needed
      });
    }
  }



  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      debugPrint('🎵 Starting metronome - enabled: ${_metronomeService.enabled}');
      _metronomeService.start();
      _startSmoothAutoScroll();
    } else {
      debugPrint('🛑 Stopping metronome');
      _metronomeService.stop();
      _stopSmoothAutoScroll();
    }
  }

  void _startSmoothAutoScroll() {
    if (_autoScrollEnabled) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (_isPlaying && _autoScrollEnabled && _scrollController.hasClients) {
          final bpm = _metronomeService.bpm;
          final scrollSpeed = (bpm / 120.0) * 0.8; // Smooth incremental scroll
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.offset;

          if (currentScroll < maxScroll) {
            final newPosition = (currentScroll + scrollSpeed).clamp(0.0, maxScroll);
            _scrollController.jumpTo(newPosition);
          }
        }
      });
    }
  }

  void _stopSmoothAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _adjustTempo(int delta) {
    final newTempo = (_metronomeService.bpm + delta).clamp(60, 200);
    _metronomeService.bpm = newTempo;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Force stop metronome when screen is popped
          _metronomeService.stop();
          debugPrint('🛑 Metronome stopped due to screen pop');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildSongContent()),
            _buildPracticeControls(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.appBar,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () {
          // Force stop metronome before navigating back
          _metronomeService.stop();
          Navigator.pop(context);
        },
      ),
      title: Text(
        _songTitle,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.volume_up, color: AppTheme.textPrimary),
          onPressed: () {
            // Test SoLoud audio
            _metronomeService.testAudio();
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
          onPressed: () {
            _showPracticeOptionsMenu();
          },
        ),
      ],
    );
  }



  Widget _buildSongContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: _buildFormattedContent(),
      ),
    );
  }

  Widget _buildFormattedContent() {
    if (_songContent.isEmpty) {
      return const Center(
        child: Text(
          'No song content available',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    // Parse and format the song content
    final lines = _songContent.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check if line contains chords
      if (line.contains('[') && line.contains(']')) {
        widgets.add(_buildChordLine(line));
      } else if (line.startsWith('{') && line.endsWith('}')) {
        // Section headers like {verse}, {chorus}
        widgets.add(_buildSectionHeader(line));
      } else {
        // Regular lyrics
        widgets.add(_buildLyricsLine(line));
      }

      widgets.add(const SizedBox(height: 4));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildChordLine(String line) {
    final spans = <InlineSpan>[];
    final RegExp chordRegex = RegExp(r'\[([A-G][#b]?[^]]*)\]');
    int lastEnd = 0;

    for (final match in chordRegex.allMatches(line)) {
      // Add text before chord
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: const TextStyle(color: AppTheme.textPrimary),
        ));
      }

      // Add chord as clickable
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: () => _showChordDiagram(match.group(1) ?? ''),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.primary, width: 1),
            ),
            child: Text(
              match.group(1) ?? '',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: const TextStyle(color: AppTheme.textPrimary),
      ));
    }

    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildSectionHeader(String line) {
    final sectionName = line.replaceAll(RegExp(r'[{}]'), '').toUpperCase();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        sectionName,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLyricsLine(String line) {
    return Text(
      line,
      textAlign: TextAlign.left,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildPracticeControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          // Play/Pause button
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: _togglePlayPause,
            isPrimary: true,
          ),
          const SizedBox(width: 12),

          // Tempo controls
          _buildTempoControls(),
          const SizedBox(width: 12),

          // Metronome toggle
          _buildControlButton(
            icon: _metronomeEnabled ? Icons.music_note : Icons.music_off,
            onPressed: () {
              setState(() {
                _metronomeEnabled = !_metronomeEnabled;
                _metronomeService.enabled = _metronomeEnabled;
              });
            },
            isActive: _metronomeEnabled,
          ),
          const SizedBox(width: 12),

          // Auto-scroll toggle
          _buildControlButton(
            icon: Icons.swap_vert,
            onPressed: () {
              setState(() {
                _autoScrollEnabled = !_autoScrollEnabled;
              });
              // Restart auto-scroll with new setting
              if (_isPlaying) {
                _startSmoothAutoScroll();
              }
            },
            isActive: _autoScrollEnabled,
          ),
          const SizedBox(width: 12),

          // Loop toggle
          _buildControlButton(
            icon: Icons.repeat,
            onPressed: () {
              setState(() {
                _loopEnabled = !_loopEnabled;
              });
            },
            isActive: _loopEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.primary
              : isActive
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: isActive && !isPrimary
              ? Border.all(color: AppTheme.primary, width: 1)
              : null,
        ),
        child: Icon(
          icon,
          color: isPrimary
              ? AppTheme.background
              : isActive
                  ? AppTheme.primary
                  : AppTheme.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTempoControls() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _adjustTempo(-1),
          onLongPress: () => _adjustTempo(-5), // Hold for faster adjustment
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.remove,
              color: AppTheme.textPrimary,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${_metronomeService.bpm}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _adjustTempo(1),
          onLongPress: () => _adjustTempo(5), // Hold for faster adjustment
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.add,
              color: AppTheme.textPrimary,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showPracticeOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Practice Options',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Metronome Sound Selection
            const Text(
              'Metronome Sound',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSoundOptions(),

            const SizedBox(height: 20),

            // Debug buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _metronomeService.testAllSounds();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Test All',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _metronomeService.forceReloadSound();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Force Reload',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundOptions() {
    final soundOptions = [
      {'key': 'hihat', 'name': 'Hi-Hat', 'description': 'Crisp percussion sound (working)'},
      {'key': 'click', 'name': 'Click', 'description': 'Sharp click sound (test)'},
      {'key': 'wood', 'name': 'Wood Block', 'description': 'Warm wooden percussion (test)'},
      {'key': 'beep', 'name': 'Beep', 'description': 'Electronic beep tone (test)'},
    ];

    return Column(
      children: soundOptions.map((option) {
        final isSelected = _metronomeService.soundType == option['key'];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            tileColor: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surfaceSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isSelected
                ? BorderSide(color: AppTheme.primary, width: 1)
                : BorderSide.none,
            ),
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            title: Text(
              option['name']!,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              option['description']!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            onTap: () {
              setState(() {
                _metronomeService.soundType = option['key']!;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  void _showChordDiagram(String chordName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ChordDiagramBottomSheet(chordName: chordName),
      ),
    );
  }
}
