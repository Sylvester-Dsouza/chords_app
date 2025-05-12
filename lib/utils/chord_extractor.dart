import 'package:flutter/material.dart';

/// Utility class to extract unique chords from a chord sheet
class ChordExtractor {
  /// Regular expression to match chord patterns in a chord sheet
  /// This matches common chord patterns like:
  /// - Basic chords: A, Bm, C#, D7
  /// - Complex chords: Asus4, Bm7b5, C#maj7, Dsus2
  /// - Slash chords: G/B, Am/C, D/F#
  static final RegExp _chordRegex = RegExp(
    r'\b([A-G][b#]?)(maj|min|m|sus|aug|dim|add|maj7|m7|7|6|9|11|13|sus2|sus4)?(\d)?(/[A-G][b#]?)?\b',
    caseSensitive: true,
  );

  /// Additional regex to match chord patterns in brackets
  static final RegExp _bracketedChordRegex = RegExp(
    r'\[([A-G][b#]?(?:maj|min|m|sus|aug|dim|add|maj7|m7|7|6|9|11|13|sus2|sus4)?(?:\d)?(?:/[A-G][b#]?)?)\]',
    caseSensitive: true,
  );

  /// Extracts unique chords from a chord sheet
  ///
  /// Returns a sorted list of unique chord names
  static List<String> extractChords(String chordSheet) {
    if (chordSheet.isEmpty) {
      return [];
    }

    // Extract chord names and add to a set to ensure uniqueness
    final Set<String> uniqueChords = {};

    // First, find all bracketed chords [C] [Am] [G/B] etc.
    final bracketedMatches = _bracketedChordRegex.allMatches(chordSheet);
    for (final match in bracketedMatches) {
      final chord = match.group(1); // Group 1 is the chord inside brackets
      if (chord != null && chord.isNotEmpty) {
        uniqueChords.add(chord);
      }
    }

    // Then find all regular chord patterns
    final matches = _chordRegex.allMatches(chordSheet);
    for (final match in matches) {
      final chord = match.group(0);
      if (chord != null && chord.isNotEmpty) {
        // Skip single letters that might not be chords (like lyrics)
        if (chord.length == 1 && RegExp(r'[A-G]').hasMatch(chord)) {
          // Check if it's surrounded by brackets or at the beginning of a line
          final start = match.start;
          final end = match.end;

          final isBracketed = (start > 0 && chordSheet[start - 1] == '[' &&
                              end < chordSheet.length && chordSheet[end] == ']');

          final isLineStart = start == 0 || chordSheet[start - 1] == '\n';

          if (!isBracketed && !isLineStart) {
            continue; // Skip this match as it's likely not a chord
          }
        }

        uniqueChords.add(chord);
      }
    }

    // Convert to list and sort
    final List<String> sortedChords = uniqueChords.toList();

    // Sort chords in a musically logical order
    sortedChords.sort((a, b) {
      // Extract root note
      final rootA = a.substring(0, a.length > 1 && (a[1] == '#' || a[1] == 'b') ? 2 : 1);
      final rootB = b.substring(0, b.length > 1 && (b[1] == '#' || b[1] == 'b') ? 2 : 1);

      // Define order of root notes
      const rootOrder = ['C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B'];

      final indexA = rootOrder.indexOf(rootA);
      final indexB = rootOrder.indexOf(rootB);

      if (indexA != indexB) {
        return indexA - indexB;
      }

      // If same root, sort by complexity (length of chord name)
      return a.length - b.length;
    });

    return sortedChords;
  }

  /// Logs extracted chords for debugging
  static void logExtractedChords(String chordSheet) {
    final chords = extractChords(chordSheet);
    debugPrint('Extracted ${chords.length} unique chords: $chords');
  }
}
