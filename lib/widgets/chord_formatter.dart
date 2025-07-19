import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../config/theme.dart';

class ChordFormatter extends StatelessWidget {
  final String chordSheet;
  final double fontSize;
  final bool highlightChords;
  final int transposeValue;
  final void Function(String)? onChordTap;
  final bool useMonospaceFont;
  final Color? chordColor; // Added parameter for chord color

  const ChordFormatter({
    super.key,
    required this.chordSheet,
    this.fontSize = 14.0, // Reduced default font size from 16.0 to 14.0
    this.highlightChords = true,
    this.transposeValue = 0,
    this.onChordTap,
    this.useMonospaceFont = true, // Default to true to preserve spacing
    this.chordColor, // If null, will use theme's primary color
  });

  @override
  Widget build(BuildContext context) {
    if (chordSheet.isEmpty) {
      return const Center(
        child: Text(
          'No chord sheet available',
          style: TextStyle(
            color: Colors.grey,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _parseChordSheet(context),
    );
  }

  List<Widget> _parseChordSheet(BuildContext context) {
    final List<Widget> widgets = [];
    final lines = chordSheet.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Check if this is a section header in {Section} format
      if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
        final sectionName = line.trim().substring(1, line.trim().length - 1);
        debugPrint('Processing section header: {$sectionName}');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              '[${sectionName.toUpperCase()}]', // Added square brackets around section name
              style: AppTheme.sectionHeaderStyle.copyWith(
                fontSize: fontSize,
              ),
            ),
          ),
        );
        continue;
      }

      // Legacy support for section headers in [Section] format
      if (line.trim().startsWith('[') &&
          line.trim().endsWith(']') &&
          RegExp(r'^\[(verse|chorus|bridge|intro|outro|pre-chorus|interlude)\s*\d*\]$', caseSensitive: false).hasMatch(line.trim())) {
        debugPrint('Processing legacy section header: ${line.trim()}');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              line.trim(),
              style: AppTheme.sectionHeaderStyle.copyWith(
                fontSize: fontSize,
              ),
            ),
          ),
        );
        continue;
      }

      // Check if this line contains only chords and the next line contains lyrics
      if (_isChordOnlyLine(line) && i + 1 < lines.length && _hasLyrics(lines[i + 1])) {
        // This is a chord line followed by a lyric line - handle them together
        final chordLine = line;
        final lyricLine = lines[i + 1];
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: _buildChordLyricPair(context, chordLine, lyricLine),
          ),
        );
        
        // Skip the next line since we processed it as part of this pair
        i++;
        continue;
      }

      // Check if line contains chord patterns [Chord] (inline chords)
      if (line.contains('[') && line.contains(']')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
            child: _buildFormattedLine(context, line),
          ),
        );
        continue;
      }

      // Regular text line (no chords)
      // Preserve all spaces exactly as they are in the original text
      debugPrint('Processing regular text line: "${line.replaceAll('\n', '\\n')}"');
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0, top: 2.0),
          child: Text(
            line,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              height: 1.3,
              // Always use monospace font for chord sheets to ensure proper alignment
              fontFamily: AppTheme.monospaceFontFamily,
            ),
            // Ensure the text is rendered exactly as it is, preserving all spaces
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFormattedLine(BuildContext context, String line) {
    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    // Regular expression to find chord patterns [Chord]
    // Using a non-greedy match to ensure we don't accidentally combine multiple chords
    final chordPattern = RegExp(r'\[([^\]]+?)\]');
    final matches = chordPattern.allMatches(line);

    debugPrint('Processing line with ${matches.length} chords: "${line.replaceAll('\n', '\\n')}"');

    for (final match in matches) {
      // Add text before the chord
      if (match.start > currentIndex) {
        final textBefore = line.substring(currentIndex, match.start);
        debugPrint('  Adding text before chord: "${textBefore.replaceAll('\n', '\\n')}"');

        // Preserve all spaces exactly as they are in the original text
        spans.add(
          TextSpan(
            text: textBefore,
            style: AppTheme.chordSheetStyle.copyWith(
              fontSize: fontSize,
              height: 1.3,
              fontFamily: AppTheme.monospaceFontFamily,
            ),
          ),
        );
      }

      // Get the chord and transpose it if needed
      final chord = match.group(1)!;
      final transposedChord = transposeValue != 0 ? _transposeChord(chord) : chord;
      debugPrint('  Processing chord: "$chord" -> "$transposedChord"');

      // Add the chord with tap recognition if onChordTap is provided and chords are visible
      if (highlightChords) {
        spans.add(
          TextSpan(
            text: transposedChord,
            style: AppTheme.chordStyle.copyWith(
              // Use provided chord color, or theme's primary color
              color: chordColor ?? Theme.of(context).colorScheme.primary,
              fontSize: fontSize,
              fontFamily: AppTheme.monospaceFontFamily, // Ensure chords also use monospace
              decoration: onChordTap != null ? TextDecoration.underline : null,
              decorationStyle: TextDecorationStyle.dotted,
            ),
            recognizer: onChordTap != null ? (TapGestureRecognizer()..onTap = () {
              onChordTap!(transposedChord);
            }) : null,
          ),
        );
      }

      currentIndex = match.end;
    }

    // Add any remaining text after the last chord
    if (currentIndex < line.length) {
      final remainingText = line.substring(currentIndex);
      debugPrint('  Adding remaining text: "${remainingText.replaceAll('\n', '\\n')}"');

      spans.add(
        TextSpan(
          text: remainingText,
          style: AppTheme.chordSheetStyle.copyWith(
            fontSize: fontSize,
            height: 1.3,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.left,
      softWrap: true,
      // Ensure the text is rendered exactly as it is, preserving all spaces
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }

  // Check if a line contains only chords (and spaces)
  bool _isChordOnlyLine(String line) {
    if (line.trim().isEmpty) return false;
    
    // Remove all chord patterns and see if anything meaningful remains
    final withoutChords = line.replaceAll(RegExp(r'\[[^\]]+\]'), '').trim();
    
    // If after removing chords, only spaces remain, it's a chord-only line
    return withoutChords.isEmpty || withoutChords.replaceAll(' ', '').isEmpty;
  }

  // Check if a line contains lyrics (not just chords or empty)
  bool _hasLyrics(String line) {
    if (line.trim().isEmpty) return false;
    
    // Remove all chord patterns and see if meaningful text remains
    final withoutChords = line.replaceAll(RegExp(r'\[[^\]]+\]'), '').trim();
    
    // If there's meaningful text after removing chords, it has lyrics
    return withoutChords.isNotEmpty && withoutChords.replaceAll(' ', '').isNotEmpty;
  }

  // Build a chord-lyric pair where chords are on one line and lyrics on the next
  Widget _buildChordLyricPair(BuildContext context, String chordLine, String lyricLine) {
    // Calculate spacing based on font size to maintain proportional spacing
    final spacingHeight = (fontSize * 0.15).clamp(2.0, 6.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chord line
        if (highlightChords)
          _buildFormattedLine(context, chordLine),
        
        // Proportional spacing between chord and lyric based on font size
        SizedBox(height: spacingHeight),
        
        // Lyric line
        Text(
          lyricLine,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            height: 1.3,
            fontFamily: AppTheme.monospaceFontFamily,
          ),
          textWidthBasis: TextWidthBasis.longestLine,
        ),
      ],
    );
  }

  // Transpose a chord by the given number of semitones
  String _transposeChord(String chord) {
    // Define the standard notes in western music (using sharps)
    const List<String> notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

    // Map flat notes to their sharp equivalents
    const Map<String, String> flatToSharp = {
      'Db': 'C#',
      'Eb': 'D#',
      'Gb': 'F#',
      'Ab': 'G#',
      'Bb': 'A#',
    };

    // Extract the root note and the chord type
    final match = RegExp(r'^([A-G][#b]?)(.*)$').firstMatch(chord);
    if (match == null) return chord; // Not a valid chord

    final rootNote = match.group(1)!;
    final chordType = match.group(2) ?? '';

    // Find the index of the root note
    int noteIndex = notes.indexOf(rootNote);

    // If not found, try to convert flat to sharp
    if (noteIndex == -1 && rootNote.endsWith('b')) {
      final sharpEquivalent = flatToSharp[rootNote];
      if (sharpEquivalent != null) {
        noteIndex = notes.indexOf(sharpEquivalent);
      }
    }

    // If still not found, return original chord
    if (noteIndex == -1) return chord;

    // Calculate the new index after transposition
    final newIndex = (noteIndex + transposeValue + 12) % 12;

    // Get the new root note
    final newRootNote = notes[newIndex];

    // Return the transposed chord
    return newRootNote + chordType;
  }
}
