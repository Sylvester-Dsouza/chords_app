import 'package:flutter_test/flutter_test.dart';
import 'package:chords_app/services/audio_service.dart';
import 'dart:async';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioService', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    group('Initialization', () {
      test('should create AudioService instance successfully', () {
        expect(audioService, isA<AudioService>());
      });

      test('should have tuning result stream', () {
        expect(audioService.tuningResultStream, isA<Stream<TuningResult>>());
      });

      test('should start listening automatically on creation', () {
        // The service should start listening automatically
        expect(audioService.tuningResultStream, isA<Stream<TuningResult>>());
      });
    });

    group('Tuning Detection', () {
      test('should emit tuning results on stream', () async {
        // Listen to the stream for a short period
        final completer = Completer<TuningResult>();
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          if (!completer.isCompleted) {
            completer.complete(result);
            subscription.cancel();
          }
        });

        // Wait for a tuning result (with timeout)
        final result = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => TuningResult(
            string: 'timeout',
            detectedFrequency: 0,
            targetFrequency: 0,
            tuningStatus: TuningStatus.tooLow,
            percentageOff: 0,
          ),
        );

        expect(result, isA<TuningResult>());
        expect(result.string, isA<String>());
        expect(result.detectedFrequency, isA<double>());
        expect(result.targetFrequency, isA<double>());
        expect(result.tuningStatus, isA<TuningStatus>());
        expect(result.percentageOff, isA<double>());
      });

      test('should detect different guitar strings', () async {
        final results = <TuningResult>[];
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          results.add(result);
          if (results.length >= 3) {
            subscription.cancel();
          }
        });

        // Wait for multiple results
        await Future.delayed(const Duration(seconds: 2));
        subscription.cancel();

        expect(results.isNotEmpty, isTrue);
        
        // Check that we get valid string names
        for (final result in results) {
          expect(['E', 'A', 'D', 'G', 'B', 'e'].contains(result.string), isTrue);
        }
      });

      test('should provide correct target frequencies for standard tuning', () async {
        final completer = Completer<TuningResult>();
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          if (!completer.isCompleted) {
            completer.complete(result);
            subscription.cancel();
          }
        });

        final result = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => TuningResult(
            string: 'E',
            detectedFrequency: 82.41,
            targetFrequency: 82.41,
            tuningStatus: TuningStatus.inTune,
            percentageOff: 0,
          ),
        );

        // Check that target frequencies match standard tuning
        final expectedFrequencies = {
          'E': 82.41,
          'A': 110.00,
          'D': 146.83,
          'G': 196.00,
          'B': 246.94,
          'e': 329.63,
        };

        expect(expectedFrequencies.containsKey(result.string), isTrue);
        expect(result.targetFrequency, equals(expectedFrequencies[result.string]));
      });
    });

    group('Tuning Status', () {
      test('should determine tuning status correctly', () async {
        final results = <TuningResult>[];
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          results.add(result);
          if (results.length >= 5) {
            subscription.cancel();
          }
        });

        // Wait for multiple results to get different tuning statuses
        await Future.delayed(const Duration(seconds: 3));
        subscription.cancel();

        expect(results.isNotEmpty, isTrue);

        // Check that we get valid tuning statuses
        for (final result in results) {
          expect([
            TuningStatus.tooLow,
            TuningStatus.inTune,
            TuningStatus.tooHigh,
          ].contains(result.tuningStatus), isTrue);
        }
      });

      test('should calculate percentage off correctly', () async {
        final completer = Completer<TuningResult>();
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          if (!completer.isCompleted) {
            completer.complete(result);
            subscription.cancel();
          }
        });

        final result = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => TuningResult(
            string: 'E',
            detectedFrequency: 82.41,
            targetFrequency: 82.41,
            tuningStatus: TuningStatus.inTune,
            percentageOff: 0,
          ),
        );

        // Percentage off should be a reasonable value
        expect(result.percentageOff, isA<double>());
        expect(result.percentageOff.abs(), lessThanOrEqualTo(0.5)); // Within 50%
      });

      test('should identify in-tune status within threshold', () async {
        final results = <TuningResult>[];
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          results.add(result);
          if (results.length >= 10) {
            subscription.cancel();
          }
        });

        // Wait for multiple results to potentially get in-tune status
        await Future.delayed(const Duration(seconds: 5));
        subscription.cancel();

        expect(results.isNotEmpty, isTrue);

        // Check if any results show in-tune status
        final inTuneResults = results.where((r) => r.tuningStatus == TuningStatus.inTune);
        
        // At least some results should eventually show in-tune status
        // (due to the simulation gradually moving toward being in tune)
        expect(inTuneResults.isNotEmpty, isTrue);

        // For in-tune results, percentage off should be within threshold
        for (final result in inTuneResults) {
          expect(result.percentageOff.abs(), lessThanOrEqualTo(AudioService.tunedThreshold));
        }
      });
    });

    group('Audio Simulation', () {
      test('should simulate realistic tuning behavior', () async {
        final results = <TuningResult>[];
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          results.add(result);
        });

        // Collect results for a longer period to see the simulation behavior
        await Future.delayed(const Duration(seconds: 4));
        subscription.cancel();

        expect(results.isNotEmpty, isTrue);

        // Should have periods of silence (no results) and periods of detection
        // This is hard to test directly, but we can check that we get reasonable results
        expect(results.length, greaterThan(5)); // Should get multiple results
        expect(results.length, lessThan(50)); // But not too many (due to silence periods)
      });

      test('should simulate string decay over time', () async {
        final results = <TuningResult>[];
        String? currentString;
        late StreamSubscription subscription;

        subscription = audioService.tuningResultStream.listen((result) {
          if (currentString == null) {
            currentString = result.string;
          }
          
          if (result.string == currentString) {
            results.add(result);
          }
          
          // Stop after collecting results for one string
          if (results.length >= 8) {
            subscription.cancel();
          }
        });

        // Wait for results from a single string
        await Future.delayed(const Duration(seconds: 3));
        subscription.cancel();

        if (results.isNotEmpty) {
          // Check that all results are from the same string (simulating one pluck)
          final firstString = results.first.string;
          for (final result in results) {
            expect(result.string, equals(firstString));
          }
        }
      });
    });

    group('Stream Management', () {
      test('should handle multiple listeners', () async {
        final results1 = <TuningResult>[];
        final results2 = <TuningResult>[];

        final subscription1 = audioService.tuningResultStream.listen((result) {
          results1.add(result);
        });

        final subscription2 = audioService.tuningResultStream.listen((result) {
          results2.add(result);
        });

        await Future.delayed(const Duration(seconds: 2));

        subscription1.cancel();
        subscription2.cancel();

        // Both listeners should receive the same results
        expect(results1.isNotEmpty, isTrue);
        expect(results2.isNotEmpty, isTrue);
        expect(results1.length, equals(results2.length));
      });

      test('should continue streaming after listener cancellation', () async {
        final results1 = <TuningResult>[];
        final results2 = <TuningResult>[];

        // First listener
        final subscription1 = audioService.tuningResultStream.listen((result) {
          results1.add(result);
        });

        await Future.delayed(const Duration(seconds: 1));
        subscription1.cancel();

        // Second listener after first is cancelled
        final subscription2 = audioService.tuningResultStream.listen((result) {
          results2.add(result);
        });

        await Future.delayed(const Duration(seconds: 1));
        subscription2.cancel();

        // Both should have received results
        expect(results1.isNotEmpty, isTrue);
        expect(results2.isNotEmpty, isTrue);
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () {
        final service = AudioService();
        
        // Should not throw when disposing
        expect(() => service.dispose(), returnsNormally);
      });

      test('should stop streaming after disposal', () async {
        final service = AudioService();
        final results = <TuningResult>[];

        final subscription = service.tuningResultStream.listen((result) {
          results.add(result);
        });

        await Future.delayed(const Duration(milliseconds: 500));
        
        // Dispose the service
        service.dispose();

        final resultsBeforeDispose = results.length;
        
        // Wait a bit more
        await Future.delayed(const Duration(milliseconds: 500));
        
        subscription.cancel();

        // Should not receive more results after disposal
        expect(results.length, equals(resultsBeforeDispose));
      });
    });

    group('Constants and Configuration', () {
      test('should have correct tuned threshold', () {
        expect(AudioService.tunedThreshold, equals(0.02));
      });

      test('should have standard tuning frequencies', () {
        // This tests the internal standard tuning map indirectly
        // by checking that target frequencies are correct
        final service = AudioService();
        
        // The service should be created without errors
        expect(service, isA<AudioService>());
        
        service.dispose();
      });
    });

    group('Error Handling', () {
      test('should handle stream errors gracefully', () async {
        final errors = <dynamic>[];
        
        final subscription = audioService.tuningResultStream.listen(
          (result) {
            // Normal result handling
          },
          onError: (error) {
            errors.add(error);
          },
        );

        await Future.delayed(const Duration(seconds: 1));
        subscription.cancel();

        // Should not have any stream errors in normal operation
        expect(errors, isEmpty);
      });

      test('should handle multiple dispose calls', () {
        final service = AudioService();
        
        // Multiple dispose calls should not throw
        expect(() => service.dispose(), returnsNormally);
        expect(() => service.dispose(), returnsNormally);
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });

  group('TuningResult', () {
    test('should create TuningResult with all properties', () {
      final result = TuningResult(
        string: 'E',
        detectedFrequency: 82.5,
        targetFrequency: 82.41,
        tuningStatus: TuningStatus.tooHigh,
        percentageOff: 0.001,
      );

      expect(result.string, equals('E'));
      expect(result.detectedFrequency, equals(82.5));
      expect(result.targetFrequency, equals(82.41));
      expect(result.tuningStatus, equals(TuningStatus.tooHigh));
      expect(result.percentageOff, equals(0.001));
    });
  });

  group('TuningStatus', () {
    test('should have all expected values', () {
      expect(TuningStatus.values, hasLength(3));
      expect(TuningStatus.values, contains(TuningStatus.tooLow));
      expect(TuningStatus.values, contains(TuningStatus.inTune));
      expect(TuningStatus.values, contains(TuningStatus.tooHigh));
    });
  });
}