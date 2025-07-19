import 'package:flutter/foundation.dart';

class ChordTimingService extends ChangeNotifier {
  // Current state
  String? _currentChord;
  int _currentBeat = 1;
  String _currentSection = 'verse';
  bool _isLooping = false;
  String? _loopSection;

  // Song structure
  final List<SongSection> _sections = [];
  final Map<String, List<ChordTiming>> _chordTimings = {};

  // Callbacks
  void Function(String chord, int beat)? onChordChange;
  void Function(String section)? onSectionChange;

  // Getters
  String? get currentChord => _currentChord;
  int get currentBeat => _currentBeat;
  String get currentSection => _currentSection;
  bool get isLooping => _isLooping;
  String? get loopSection => _loopSection;
  List<SongSection> get sections => _sections;

  // Initialize with song data
  void initializeWithSong(Map<String, dynamic> songData) {
    _parseSongStructure(songData);
    _currentBeat = 1;
    _currentSection = _sections.isNotEmpty ? _sections.first.name : 'verse';
    _currentChord = _getCurrentChordForBeat(_currentBeat);
    notifyListeners();
  }

  // Parse song structure from chord sheet
  void _parseSongStructure(Map<String, dynamic> songData) {
    _sections.clear();
    _chordTimings.clear();

    final String chordSheet = songData['chordSheet'] as String? ?? '';
    final int? tempo = songData['tempo'] as int?;
    final String? timeSignature = songData['timeSignature'] as String?;

    // Parse the chord sheet into sections
    _parseChordSheet(chordSheet, tempo, timeSignature);
  }

  void _parseChordSheet(String chordSheet, int? tempo, String? timeSignature) {
    // Split chord sheet into sections
    List<String> lines = chordSheet.split('\n');
    String currentSectionName = 'intro';
    List<String> currentSectionLines = [];
    int beatCounter = 1;

    for (String line in lines) {
      String trimmedLine = line.trim();

      // Check if line is a section header (e.g., {verse}, {chorus})
      if (trimmedLine.startsWith('{') && trimmedLine.endsWith('}')) {
        // Save previous section if it exists
        if (currentSectionLines.isNotEmpty) {
          _processSectionLines(
            currentSectionName,
            currentSectionLines,
            beatCounter,
          );
          beatCounter += _calculateSectionBeats(currentSectionLines);
        }

        // Start new section
        currentSectionName =
            trimmedLine.substring(1, trimmedLine.length - 1).toLowerCase();
        currentSectionLines.clear();
      } else if (trimmedLine.isNotEmpty) {
        currentSectionLines.add(trimmedLine);
      }
    }

    // Process the last section
    if (currentSectionLines.isNotEmpty) {
      _processSectionLines(
        currentSectionName,
        currentSectionLines,
        beatCounter,
      );
    }

    // If no sections were found, create a default section
    if (_sections.isEmpty) {
      _createDefaultSection(chordSheet);
    }
  }

  void _processSectionLines(
    String sectionName,
    List<String> lines,
    int startBeat,
  ) {
    List<ChordTiming> chordTimings = [];
    int currentBeat = startBeat;

    for (String line in lines) {
      List<ChordTiming> lineChords = _parseChordLine(line, currentBeat);
      chordTimings.addAll(lineChords);
      currentBeat += _estimateLineBeats(line);
    }

    // Create section
    SongSection section = SongSection(
      name: sectionName,
      displayName: _formatSectionName(sectionName),
      startBeat: startBeat,
      endBeat: currentBeat - 1,
      chordTimings: chordTimings,
    );

    _sections.add(section);
    _chordTimings[sectionName] = chordTimings;
  }

  List<ChordTiming> _parseChordLine(String line, int startBeat) {
    List<ChordTiming> chords = [];
    RegExp chordRegex = RegExp(r'\[([^\]]+)\]');
    Iterable<RegExpMatch> matches = chordRegex.allMatches(line);

    int beatOffset = 0;
    for (RegExpMatch match in matches) {
      String chord = match.group(1) ?? '';
      chords.add(
        ChordTiming(
          chord: chord,
          beat: startBeat + beatOffset,
          duration: 4, // Default 4 beats per chord
        ),
      );
      beatOffset += 4;
    }

    return chords;
  }

  int _estimateLineBeats(String line) {
    // Estimate beats per line based on chord count
    RegExp chordRegex = RegExp(r'\[([^\]]+)\]');
    int chordCount = chordRegex.allMatches(line).length;
    return chordCount > 0
        ? chordCount * 4
        : 4; // 4 beats per chord, minimum 4 beats
  }

  int _calculateSectionBeats(List<String> lines) {
    int totalBeats = 0;
    for (String line in lines) {
      totalBeats += _estimateLineBeats(line);
    }
    return totalBeats;
  }

  void _createDefaultSection(String chordSheet) {
    List<ChordTiming> chordTimings = _parseChordLine(chordSheet, 1);

    SongSection section = SongSection(
      name: 'song',
      displayName: 'Song',
      startBeat: 1,
      endBeat: chordTimings.length * 4,
      chordTimings: chordTimings,
    );

    _sections.add(section);
    _chordTimings['song'] = chordTimings;
  }

  String _formatSectionName(String name) {
    return name
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : word,
        )
        .join(' ');
  }

  // Beat tracking
  void updateBeat(int beat) {
    _currentBeat = beat;

    // Update current section based on beat
    _updateCurrentSection(beat);

    // Update current chord
    String? newChord = _getCurrentChordForBeat(beat);
    if (newChord != _currentChord) {
      _currentChord = newChord;
      onChordChange?.call(_currentChord ?? '', beat);
    }

    notifyListeners();
  }

  void _updateCurrentSection(int beat) {
    for (SongSection section in _sections) {
      if (beat >= section.startBeat && beat <= section.endBeat) {
        if (_currentSection != section.name) {
          _currentSection = section.name;
          onSectionChange?.call(_currentSection);
        }
        break;
      }
    }
  }

  String? _getCurrentChordForBeat(int beat) {
    // If looping, adjust beat to loop section
    if (_isLooping && _loopSection != null) {
      SongSection? section = _sections.firstWhere(
        (s) => s.name == _loopSection,
        orElse: () => _sections.first,
      );

      int sectionLength = section.endBeat - section.startBeat + 1;
      int adjustedBeat =
          section.startBeat + ((beat - section.startBeat) % sectionLength);
      beat = adjustedBeat;
    }

    // Find chord for current beat
    List<ChordTiming>? timings = _chordTimings[_currentSection];
    if (timings != null) {
      for (ChordTiming timing in timings) {
        if (beat >= timing.beat && beat < timing.beat + timing.duration) {
          return timing.chord;
        }
      }
    }

    return null;
  }

  // Section navigation
  void jumpToSection(String sectionName) {
    SongSection? section = _sections.firstWhere(
      (s) => s.name == sectionName,
      orElse: () => _sections.first,
    );

    _currentSection = sectionName;
    _currentBeat = section.startBeat;
    _currentChord = _getCurrentChordForBeat(_currentBeat);
    onSectionChange?.call(_currentSection);
    notifyListeners();
  }

  void nextSection() {
    int currentIndex = _sections.indexWhere((s) => s.name == _currentSection);
    if (currentIndex < _sections.length - 1) {
      jumpToSection(_sections[currentIndex + 1].name);
    }
  }

  void previousSection() {
    int currentIndex = _sections.indexWhere((s) => s.name == _currentSection);
    if (currentIndex > 0) {
      jumpToSection(_sections[currentIndex - 1].name);
    }
  }

  // Loop functionality
  void toggleLoop(String? sectionName) {
    if (_isLooping && _loopSection == sectionName) {
      // Stop looping
      _isLooping = false;
      _loopSection = null;
    } else {
      // Start looping
      _isLooping = true;
      _loopSection = sectionName ?? _currentSection;
      jumpToSection(_loopSection!);
    }
    notifyListeners();
  }

  // Get next chord for preview
  String? getNextChord() {
    return _getCurrentChordForBeat(_currentBeat + 4); // Look ahead 4 beats
  }

  // Get section progress (0.0 to 1.0)
  double getSectionProgress() {
    SongSection? section = _sections.firstWhere(
      (s) => s.name == _currentSection,
      orElse: () => _sections.first,
    );

    int sectionLength = section.endBeat - section.startBeat + 1;
    int progressBeats = _currentBeat - section.startBeat;
    return (progressBeats / sectionLength).clamp(0.0, 1.0);
  }

  void reset() {
    _currentBeat = 1;
    _currentSection = _sections.isNotEmpty ? _sections.first.name : 'verse';
    _currentChord = _getCurrentChordForBeat(_currentBeat);
    _isLooping = false;
    _loopSection = null;
    notifyListeners();
  }
}

// Data classes
class SongSection {
  final String name;
  final String displayName;
  final int startBeat;
  final int endBeat;
  final List<ChordTiming> chordTimings;

  SongSection({
    required this.name,
    required this.displayName,
    required this.startBeat,
    required this.endBeat,
    required this.chordTimings,
  });
}

class ChordTiming {
  final String chord;
  final int beat;
  final int duration;

  ChordTiming({
    required this.chord,
    required this.beat,
    required this.duration,
  });
}
