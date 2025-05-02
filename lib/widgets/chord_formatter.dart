import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

class ChordFormatter extends StatelessWidget {
  final String chordSheet;
  final double fontSize;
  final bool highlightChords;
  final int transposeValue;
  final Function(String)? onChordTap;

  const ChordFormatter({
    super.key,
    required this.chordSheet,
    this.fontSize = 16.0,
    this.highlightChords = true,
    this.transposeValue = 0,
    this.onChordTap,
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
      children: _parseChordSheet(),
    );
  }

  List<Widget> _parseChordSheet() {
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
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 20, bottom: 10, left: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFC701).withAlpha(50), width: 1),
            ),
            child: Text(
              sectionName.toUpperCase(),
              style: GoogleFonts.lexend(
                color: const Color(0xFFFFC701),
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 20, bottom: 10, left: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFC701).withAlpha(50), width: 1),
            ),
            child: Text(
              line.trim(),
              style: GoogleFonts.lexend(
                color: const Color(0xFFFFC701),
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
            padding: const EdgeInsets.only(top: 3.0, bottom: 3.0, left: 8.0),
            child: _buildFormattedLine(line),
          ),
        );
        continue;
      }

      // Regular text line (no chords)
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 2.0, left: 8.0),
          child: Text(
            line,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: fontSize,
              height: 1.3,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFormattedLine(String line) {
    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    // Regular expression to find chord patterns [Chord]
    final chordPattern = RegExp(r'\[([^\]]+)\]');
    final matches = chordPattern.allMatches(line);

    for (final match in matches) {
      // Add text before the chord
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: line.substring(currentIndex, match.start),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              height: 1.3,
            ),
          ),
        );
      }

      // Get the chord and transpose it if needed
      final chord = match.group(1)!;
      final transposedChord = transposeValue != 0 ? _transposeChord(chord) : chord;

      // Add the chord with tap recognition if onChordTap is provided and chords are visible
      if (highlightChords) {
        spans.add(
          TextSpan(
            text: transposedChord,
            style: GoogleFonts.lexend(
              color: const Color(0xFFFFC701),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
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
      spans.add(
        TextSpan(
          text: line.substring(currentIndex),
          style: GoogleFonts.lexend(
            color: Colors.white,
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
