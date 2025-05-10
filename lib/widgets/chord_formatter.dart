import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class ChordFormatter extends StatelessWidget {
  final String chordSheet;
  final double fontSize;
  final bool highlightChords;
  final int transposeValue;
  final Function(String)? onChordTap;
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
          style: TextStyle(color: Colors.grey),
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

    for (final line in lines) {
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
              style: TextStyle(
                color: Colors.grey, // Changed from yellow to grey as requested
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                // Use a monospace font for consistent spacing if enabled
                fontFamily: useMonospaceFont ? 'monospace' : null,
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
              style: TextStyle(
                color: Colors.grey, // Changed from yellow to grey for consistency
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                // Use a monospace font for consistent spacing if enabled
                fontFamily: useMonospaceFont ? 'monospace' : null,
              ),
            ),
          ),
        );
        continue;
      }

      // Check if line contains chord patterns [Chord]
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
              // Use a monospace font to ensure consistent spacing if enabled
              fontFamily: useMonospaceFont ? 'monospace' : null,
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
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              height: 1.3,
              // Use a monospace font to ensure consistent spacing if enabled
              fontFamily: useMonospaceFont ? 'monospace' : null,
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
            style: TextStyle(
              // Use provided chord color, or theme's primary color instead of hardcoded yellow
              color: chordColor ?? Theme.of(context).colorScheme.primary,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              decoration: onChordTap != null ? TextDecoration.underline : null,
              decorationStyle: TextDecorationStyle.dotted,
              // Use a monospace font to ensure consistent spacing if enabled
              fontFamily: useMonospaceFont ? 'monospace' : null,
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
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            height: 1.3,
            // Use a monospace font to ensure consistent spacing if enabled
            fontFamily: useMonospaceFont ? 'monospace' : null,
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

  // Transpose a chord by the given number of semitones
  String _transposeChord(String chord) {
    // Define the standard notes in western music
    const List<String> notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

    // Extract the root note and the chord type
    final match = RegExp(r'^([A-G][#b]?)(.*)$').firstMatch(chord);
    if (match == null) return chord; // Not a valid chord

    final rootNote = match.group(1)!;
    final chordType = match.group(2) ?? '';

    // Find the index of the root note
    int noteIndex = notes.indexOf(rootNote);
    if (noteIndex == -1) {
      // Try to convert flat to sharp for processing
      if (rootNote.endsWith('b')) {
        final flatNote = rootNote[0];
        final flatIndex = "ABCDEFG".indexOf(flatNote);
        if (flatIndex > 0) {
          final sharpEquivalent = "${"ABCDEFG"[flatIndex - 1]}#";
          noteIndex = notes.indexOf(sharpEquivalent);
        }
      }

      if (noteIndex == -1) return chord; // Still not found
    }

    // Calculate the new index after transposition
    final newIndex = (noteIndex + transposeValue + 12) % 12;

    // Get the new root note
    final newRootNote = notes[newIndex];

    // Return the transposed chord
    return newRootNote + chordType;
  }
}
