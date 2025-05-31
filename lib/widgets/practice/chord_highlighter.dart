import 'package:flutter/material.dart';
import '../../services/chord_timing_service.dart';
import '../../services/simple_metronome_service.dart';
import '../../config/theme.dart';

class ChordHighlighter extends StatefulWidget {
  final String chordSheet;
  final ChordTimingService chordTimingService;
  final SimpleMetronomeService metronomeService;
  final bool showChords;
  final bool showLyrics;
  final double fontSize;

  const ChordHighlighter({
    super.key,
    required this.chordSheet,
    required this.chordTimingService,
    required this.metronomeService,
    this.showChords = true,
    this.showLyrics = true,
    this.fontSize = 16.0,
  });

  @override
  State<ChordHighlighter> createState() => _ChordHighlighterState();
}

class _ChordHighlighterState extends State<ChordHighlighter>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;
  String? _currentHighlightedChord;
  int _currentBeat = 1;

  @override
  void initState() {
    super.initState();
    
    // Highlight animation for current chord
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _highlightAnimation = ColorTween(
      begin: AppTheme.primaryColor.withValues(alpha: 0.3),
      end: AppTheme.primaryColor.withValues(alpha: 0.7),
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    // Listen to metronome beats
    widget.metronomeService.onBeat = (beat, isAccented) {
      _onBeat(beat, isAccented);
    };

    // Listen to chord changes
    widget.chordTimingService.onChordChange = (chord, beat) {
      _onChordChange(chord, beat);
    };
  }

  void _onBeat(int beat, bool isAccented) {
    setState(() {
      _currentBeat = beat;
    });
    widget.chordTimingService.updateBeat(beat);
    
    // Pulse animation on beat
    if (isAccented) {
      _highlightController.forward().then((_) {
        _highlightController.reverse();
      });
    }
  }

  void _onChordChange(String chord, int beat) {
    setState(() {
      _currentHighlightedChord = chord;
    });
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current chord display
            _buildCurrentChordDisplay(),
            
            const SizedBox(height: 16),
            
            // Chord sheet with highlighting
            _buildChordSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentChordDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Current chord
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Current Chord: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              AnimatedBuilder(
                animation: _highlightAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _highlightAnimation.value,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: Text(
                      _currentHighlightedChord ?? '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Next chord preview
          if (widget.chordTimingService.getNextChord() != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Next: ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.chordTimingService.getNextChord()!,
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
          
          // Beat indicator
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Beat: ',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              Text(
                '$_currentBeat',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChordSheet() {
    List<String> lines = widget.chordSheet.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _buildChordLine(line)).toList(),
    );
  }

  Widget _buildChordLine(String line) {
    if (line.trim().isEmpty) {
      return const SizedBox(height: 8);
    }

    // Check if line is a section header
    if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
      return _buildSectionHeader(line);
    }

    // Parse line for chords and lyrics
    return _buildMixedLine(line);
  }

  Widget _buildSectionHeader(String line) {
    String sectionName = line.trim().substring(1, line.trim().length - 1);
    bool isCurrentSection = widget.chordTimingService.currentSection == sectionName.toLowerCase();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentSection 
            ? AppTheme.primaryColor.withValues(alpha: 0.2)
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: isCurrentSection 
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Text(
        sectionName.toUpperCase(),
        style: TextStyle(
          color: isCurrentSection ? AppTheme.primaryColor : Colors.white70,
          fontSize: widget.fontSize + 2,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.primaryFontFamily,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMixedLine(String line) {
    List<InlineSpan> spans = [];
    RegExp chordRegex = RegExp(r'\[([^\]]+)\]');
    int lastEnd = 0;

    for (RegExpMatch match in chordRegex.allMatches(line)) {
      // Add text before chord
      if (match.start > lastEnd) {
        String textBefore = line.substring(lastEnd, match.start);
        if (textBefore.isNotEmpty && widget.showLyrics) {
          spans.add(TextSpan(
            text: textBefore,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.fontSize,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ));
        }
      }

      // Add chord
      if (widget.showChords) {
        String chord = match.group(1) ?? '';
        bool isCurrentChord = chord == _currentHighlightedChord;
        
        spans.add(WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrentChord 
                  ? AppTheme.primaryColor
                  : Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
              border: isCurrentChord 
                  ? Border.all(color: Colors.white, width: 1)
                  : null,
            ),
            child: Text(
              chord,
              style: TextStyle(
                color: isCurrentChord ? Colors.black : Colors.white,
                fontSize: widget.fontSize - 2,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < line.length) {
      String remainingText = line.substring(lastEnd);
      if (remainingText.isNotEmpty && widget.showLyrics) {
        spans.add(TextSpan(
          text: remainingText,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.fontSize,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(children: spans),
      ),
    );
  }
}

// Practice mode display options
class PracticeModeOptions {
  final bool showChords;
  final bool showLyrics;
  final bool highlightCurrentChord;
  final bool showNextChord;
  final double fontSize;

  const PracticeModeOptions({
    this.showChords = true,
    this.showLyrics = true,
    this.highlightCurrentChord = true,
    this.showNextChord = true,
    this.fontSize = 16.0,
  });

  PracticeModeOptions copyWith({
    bool? showChords,
    bool? showLyrics,
    bool? highlightCurrentChord,
    bool? showNextChord,
    double? fontSize,
  }) {
    return PracticeModeOptions(
      showChords: showChords ?? this.showChords,
      showLyrics: showLyrics ?? this.showLyrics,
      highlightCurrentChord: highlightCurrentChord ?? this.highlightCurrentChord,
      showNextChord: showNextChord ?? this.showNextChord,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
