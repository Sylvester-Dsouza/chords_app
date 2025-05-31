import 'package:flutter/foundation.dart';
import 'package:guitar_chord_library/guitar_chord_library.dart';

/// Utility class to test chord coverage for both sharp and flat notations
class ChordCoverageTest {
  
  /// Test all enharmonic equivalents to ensure both sharp and flat notations work
  static Future<Map<String, dynamic>> testEnharmonicCoverage() async {
    final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);
    
    // Define all enharmonic pairs
    final enharmonicPairs = [
      ['C#', 'Db'],
      ['D#', 'Eb'], 
      ['F#', 'Gb'],
      ['G#', 'Ab'],
      ['A#', 'Bb'],
    ];
    
    // Common chord types to test
    final chordTypes = ['major', 'minor', 'dominant7', 'major7', 'minor7'];
    
    final results = <String, dynamic>{
      'totalTests': 0,
      'successfulTests': 0,
      'failedTests': [],
      'enharmonicResults': <String, dynamic>{},
    };
    
    for (final pair in enharmonicPairs) {
      final sharp = pair[0];
      final flat = pair[1];
      
      results['enharmonicResults'][sharp] = <String, dynamic>{};
      results['enharmonicResults'][flat] = <String, dynamic>{};
      
      for (final chordType in chordTypes) {
        results['totalTests'] += 2; // One for sharp, one for flat
        
        // Test sharp notation
        final sharpPositions = instrument.getChordPositions(sharp, chordType);
        final sharpSuccess = sharpPositions != null && sharpPositions.isNotEmpty;
        
        results['enharmonicResults'][sharp][chordType] = {
          'success': sharpSuccess,
          'positionCount': sharpPositions?.length ?? 0,
        };
        
        if (sharpSuccess) {
          results['successfulTests']++;
        } else {
          results['failedTests'].add('$sharp $chordType');
        }
        
        // Test flat notation
        final flatPositions = instrument.getChordPositions(flat, chordType);
        final flatSuccess = flatPositions != null && flatPositions.isNotEmpty;
        
        results['enharmonicResults'][flat][chordType] = {
          'success': flatSuccess,
          'positionCount': flatPositions?.length ?? 0,
        };
        
        if (flatSuccess) {
          results['successfulTests']++;
        } else {
          results['failedTests'].add('$flat $chordType');
        }
        
        // Log results for debugging
        debugPrint('$sharp $chordType: ${sharpSuccess ? 'SUCCESS' : 'FAILED'} (${sharpPositions?.length ?? 0} positions)');
        debugPrint('$flat $chordType: ${flatSuccess ? 'SUCCESS' : 'FAILED'} (${flatPositions?.length ?? 0} positions)');
      }
    }
    
    final successRate = (results['successfulTests'] / results['totalTests'] * 100).toStringAsFixed(1);
    debugPrint('Enharmonic chord coverage test completed: $successRate% success rate');
    debugPrint('Successful: ${results['successfulTests']}/${results['totalTests']}');
    debugPrint('Failed chords: ${results['failedTests']}');
    
    return results;
  }
  
  /// Test all basic major and minor chords in all keys
  static Future<Map<String, dynamic>> testBasicChordCoverage() async {
    final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);
    
    // All 12 chromatic notes (using sharps)
    final notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    
    // All flat equivalents
    final flatNotes = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
    
    final results = <String, dynamic>{
      'majorChords': <String, dynamic>{},
      'minorChords': <String, dynamic>{},
      'totalTested': 0,
      'totalSuccessful': 0,
    };
    
    // Test major chords with sharp notation
    for (final note in notes) {
      results['totalTested']++;
      final positions = instrument.getChordPositions(note, 'major');
      final success = positions != null && positions.isNotEmpty;
      
      results['majorChords'][note] = {
        'success': success,
        'positionCount': positions?.length ?? 0,
      };
      
      if (success) results['totalSuccessful']++;
      debugPrint('$note major: ${success ? 'SUCCESS' : 'FAILED'} (${positions?.length ?? 0} positions)');
    }
    
    // Test major chords with flat notation
    for (final note in flatNotes) {
      if (note.contains('b')) { // Only test actual flat notes
        results['totalTested']++;
        final positions = instrument.getChordPositions(note, 'major');
        final success = positions != null && positions.isNotEmpty;
        
        results['majorChords']['${note}_flat'] = {
          'success': success,
          'positionCount': positions?.length ?? 0,
        };
        
        if (success) results['totalSuccessful']++;
        debugPrint('$note major: ${success ? 'SUCCESS' : 'FAILED'} (${positions?.length ?? 0} positions)');
      }
    }
    
    // Test minor chords with sharp notation
    for (final note in notes) {
      results['totalTested']++;
      final positions = instrument.getChordPositions(note, 'minor');
      final success = positions != null && positions.isNotEmpty;
      
      results['minorChords'][note] = {
        'success': success,
        'positionCount': positions?.length ?? 0,
      };
      
      if (success) results['totalSuccessful']++;
      debugPrint('$note minor: ${success ? 'SUCCESS' : 'FAILED'} (${positions?.length ?? 0} positions)');
    }
    
    // Test minor chords with flat notation
    for (final note in flatNotes) {
      if (note.contains('b')) { // Only test actual flat notes
        results['totalTested']++;
        final positions = instrument.getChordPositions(note, 'minor');
        final success = positions != null && positions.isNotEmpty;
        
        results['minorChords']['${note}_flat'] = {
          'success': success,
          'positionCount': positions?.length ?? 0,
        };
        
        if (success) results['totalSuccessful']++;
        debugPrint('$note minor: ${success ? 'SUCCESS' : 'FAILED'} (${positions?.length ?? 0} positions)');
      }
    }
    
    final successRate = (results['totalSuccessful'] / results['totalTested'] * 100).toStringAsFixed(1);
    debugPrint('Basic chord coverage test completed: $successRate% success rate');
    debugPrint('Successful: ${results['totalSuccessful']}/${results['totalTested']}');
    
    return results;
  }
  
  /// Run all chord coverage tests
  static Future<void> runAllTests() async {
    debugPrint('🎸 Starting comprehensive chord coverage tests...');
    
    debugPrint('\n📊 Testing enharmonic equivalents...');
    await testEnharmonicCoverage();
    
    debugPrint('\n📊 Testing basic major/minor chords...');
    await testBasicChordCoverage();
    
    debugPrint('\n✅ Chord coverage tests completed!');
  }
}
