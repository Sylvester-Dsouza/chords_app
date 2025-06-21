import 'package:flutter/foundation.dart';
import 'package:guitar_chord_library/guitar_chord_library.dart';

/// Comprehensive chord testing utility to verify all supported chord types
class ComprehensiveChordTest {
  
  /// Test all chord types that should be supported by the app
  static Future<Map<String, dynamic>> testAllChordTypes() async {
    final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);
    
    // All 12 chromatic notes
    final notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final flatNotes = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
    
    // All chord types that should be supported
    final chordTypes = [
      // Basic triads
      'major', 'minor', 'dim', 'aug',
      
      // Suspended chords
      'sus2', 'sus4', 'sus2sus4',
      
      // Seventh chords
      '7', 'maj7', 'm7', 'dim7', 'aug7', '7b5', '7sus4', 'm7b5', 'mmaj7', 'mmaj7b5',
      
      // Ninth chords
      '9', 'maj9', 'm9', '9b5', 'aug9', '7b9', '7#9', 'mmaj9',
      
      // Extended chords
      '11', '9#11', '13', 'maj11', 'maj13', 'm11', 'mmaj11',
      
      // Sixth chords
      '6', 'm6', '69', 'm69',
      
      // Add chords
      'add9', 'madd9',
      
      // Power chords
      '5',
      
      // Altered chords
      'alt', 'maj7#5',
      
      // Slash chords (limited support)
      '/E', '/F', '/G',
    ];
    
    final results = <String, dynamic>{
      'totalTests': 0,
      'successfulTests': 0,
      'failedTests': <String>[],
      'supportedChords': <String>[],
      'unsupportedChords': <String>[],
      'chordTypeResults': <String, dynamic>{},
    };
    
    // Test each note with each chord type
    for (final note in notes) {
      for (final chordType in chordTypes) {
        results['totalTests']++;
        
        try {
          final chordPositions = instrument.getChordPositions(note, chordType);
          
          if (chordPositions != null && chordPositions.isNotEmpty) {
            results['successfulTests']++;
            results['supportedChords'].add('$note$chordType');
            
            if (kDebugMode) {
              debugPrint('✅ $note$chordType: ${chordPositions.length} positions');
            }
          } else {
            results['failedTests'].add('$note$chordType');
            results['unsupportedChords'].add('$note$chordType');
            
            if (kDebugMode) {
              debugPrint('❌ $note$chordType: Not found');
            }
          }
        } catch (e) {
          results['failedTests'].add('$note$chordType (Error: $e)');
          results['unsupportedChords'].add('$note$chordType');
          
          if (kDebugMode) {
            debugPrint('💥 $note$chordType: Error - $e');
          }
        }
      }
    }
    
    // Test flat notes for enharmonic equivalents
    for (final note in flatNotes) {
      if (note.contains('b')) {
        for (final chordType in ['major', 'minor', '7', 'maj7']) {
          results['totalTests']++;
          
          try {
            final chordPositions = instrument.getChordPositions(note, chordType);
            
            if (chordPositions != null && chordPositions.isNotEmpty) {
              results['successfulTests']++;
              results['supportedChords'].add('$note$chordType');
            } else {
              results['failedTests'].add('$note$chordType');
              results['unsupportedChords'].add('$note$chordType');
            }
          } catch (e) {
            results['failedTests'].add('$note$chordType (Error: $e)');
            results['unsupportedChords'].add('$note$chordType');
          }
        }
      }
    }
    
    // Calculate success rate
    final successRate = (results['successfulTests'] / results['totalTests'] * 100).toStringAsFixed(1);
    results['successRate'] = '$successRate%';
    
    if (kDebugMode) {
      debugPrint('\n🎸 COMPREHENSIVE CHORD TEST RESULTS:');
      debugPrint('Total Tests: ${results['totalTests']}');
      debugPrint('Successful: ${results['successfulTests']}');
      debugPrint('Failed: ${results['failedTests'].length}');
      debugPrint('Success Rate: ${results['successRate']}');
      debugPrint('\n✅ Supported Chords: ${results['supportedChords'].length}');
      debugPrint('❌ Unsupported Chords: ${results['unsupportedChords'].length}');
    }
    
    return results;
  }
  
  /// Test specific add9 chords to debug the Cadd9 issue
  static Future<Map<String, dynamic>> testAdd9Chords() async {
    final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);

    final add9Tests = [
      'C + add9',
      'C + maj9',
      'C + 9',
      'C + sus2',
      'C + major',
    ];

    final results = <String, dynamic>{
      'add9Tests': <String, dynamic>{},
    };

    for (final test in add9Tests) {
      final parts = test.split(' + ');
      final rootNote = parts[0];
      final chordType = parts[1];

      try {
        final chordPositions = instrument.getChordPositions(rootNote, chordType);
        results['add9Tests']['$rootNote$chordType'] = {
          'found': chordPositions != null && chordPositions.isNotEmpty,
          'positions': chordPositions?.length ?? 0,
          'data': chordPositions?.map((p) => {
            'baseFret': p.baseFret,
            'frets': p.frets,
            'fingers': p.fingers,
          }).toList(),
        };

        if (kDebugMode) {
          debugPrint('🎸 $rootNote$chordType: ${chordPositions?.length ?? 0} positions');
          if (chordPositions != null && chordPositions.isNotEmpty) {
            debugPrint('   First position: baseFret=${chordPositions.first.baseFret}, frets=${chordPositions.first.frets}');
          }
        }
      } catch (e) {
        results['add9Tests']['$rootNote$chordType'] = {
          'found': false,
          'error': e.toString(),
        };

        if (kDebugMode) {
          debugPrint('💥 $rootNote$chordType: Error - $e');
        }
      }
    }

    return results;
  }

  /// Test specific slash chords that are commonly used
  static Future<Map<String, dynamic>> testSlashChords() async {
    final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);
    
    // Common slash chords
    final slashChords = [
      'C/E', 'C/F', 'C/G',
      'D/F#', 'D/A',
      'F/A', 'F/C',
      'G/B', 'G/D',
      'Am/C', 'Am/E',
      'Em/B', 'Em/G',
    ];
    
    final results = <String, dynamic>{
      'totalTests': 0,
      'successfulTests': 0,
      'supportedSlashChords': <String>[],
      'unsupportedSlashChords': <String>[],
    };
    
    for (final slashChord in slashChords) {
      results['totalTests']++;
      
      final parts = slashChord.split('/');
      if (parts.length == 2) {
        final rootNote = parts[0].substring(0, 1);
        final chordType = parts[0].substring(1);
        final bassNote = parts[1];
        
        try {
          // Try to find the slash chord in the library
          final chordPositions = instrument.getChordPositions(rootNote, '$chordType/$bassNote');
          
          if (chordPositions != null && chordPositions.isNotEmpty) {
            results['successfulTests']++;
            results['supportedSlashChords'].add(slashChord);
            
            if (kDebugMode) {
              debugPrint('✅ Slash chord $slashChord: ${chordPositions.length} positions');
            }
          } else {
            results['unsupportedSlashChords'].add(slashChord);
            
            if (kDebugMode) {
              debugPrint('❌ Slash chord $slashChord: Not found');
            }
          }
        } catch (e) {
          results['unsupportedSlashChords'].add(slashChord);
          
          if (kDebugMode) {
            debugPrint('💥 Slash chord $slashChord: Error - $e');
          }
        }
      }
    }
    
    if (kDebugMode) {
      debugPrint('\n🎸 SLASH CHORD TEST RESULTS:');
      debugPrint('Total Tests: ${results['totalTests']}');
      debugPrint('Successful: ${results['successfulTests']}');
      debugPrint('✅ Supported: ${results['supportedSlashChords']}');
      debugPrint('❌ Unsupported: ${results['unsupportedSlashChords']}');
    }
    
    return results;
  }
  
  /// Test specific Cadd9 issue
  static Future<void> testCadd9Issue() async {
    final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);

    if (kDebugMode) {
      debugPrint('\n🎸 TESTING CADD9 ISSUE:');

      // Test exact library calls
      final tests = [
        {'root': 'C', 'type': 'add9'},
        {'root': 'C', 'type': 'major'},
        {'root': 'C', 'type': 'maj9'},
        {'root': 'C', 'type': '9'},
        {'root': 'C', 'type': 'sus2'},
      ];

      for (final test in tests) {
        final root = test['root']!;
        final type = test['type']!;

        try {
          final positions = instrument.getChordPositions(root, type);
          debugPrint('$root$type: ${positions?.length ?? 0} positions found');

          if (positions != null && positions.isNotEmpty) {
            final first = positions.first;
            debugPrint('  First position: baseFret=${first.baseFret}, frets=${first.frets}, fingers=${first.fingers}');
          }
        } catch (e) {
          debugPrint('$root$type: ERROR - $e');
        }
      }
    }
  }

  /// Test the chord parsing logic with various input formats
  static void testChordParsing() {
    final testChords = [
      // Basic chords
      'C', 'Cm', 'C7', 'Cmaj7',
      
      // Slash chords
      'C/E', 'Am/C', 'G7/B', 'Ab/C',
      
      // Complex chords
      'C7#9', 'Dm7b5', 'F#dim7', 'Asus4',
      
      // Alternative notations
      'C△', 'Cm-7', 'C+', 'C°',
      
      // Extended chords
      'C13', 'Dm11', 'G7alt', 'Fmaj9',
    ];
    
    if (kDebugMode) {
      debugPrint('\n🎸 CHORD PARSING TEST:');
      
      for (final chord in testChords) {
        debugPrint('Testing: $chord');
        // This would call the actual parsing method from the widget
        // For now, just log the chord
      }
    }
  }
}
