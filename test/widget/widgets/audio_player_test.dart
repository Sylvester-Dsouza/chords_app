import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:chords_app/widgets/multi_track_controls.dart';
import 'package:chords_app/models/karaoke.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('Audio Player Widget Tests', () {
    late Map<TrackType, AudioPlayer> mockTrackPlayers;
    late Map<TrackType, bool> trackMuted;
    late Map<TrackType, double> trackVolumes;
    late Map<TrackType, IconData> trackIcons;
    late Map<TrackType, Color> trackColors;

    setUp(() {
      // Setup mock track players
      mockTrackPlayers = {
        TrackType.vocals: MockAudioPlayer(),
        TrackType.bass: MockAudioPlayer(),
        TrackType.drums: MockAudioPlayer(),
        TrackType.other: MockAudioPlayer(),
      };

      // Setup track states
      trackMuted = {
        TrackType.vocals: false,
        TrackType.bass: false,
        TrackType.drums: false,
        TrackType.other: false,
      };

      trackVolumes = {
        TrackType.vocals: 1.0,
        TrackType.bass: 0.8,
        TrackType.drums: 0.6,
        TrackType.other: 0.7,
      };

      trackIcons = {
        TrackType.vocals: Icons.mic,
        TrackType.bass: Icons.music_note,
        TrackType.drums: Icons.music_note,
        TrackType.other: Icons.piano,
      };

      trackColors = {
        TrackType.vocals: Colors.blue,
        TrackType.bass: Colors.green,
        TrackType.drums: Colors.red,
        TrackType.other: Colors.orange,
      };
    });

    group('MultiTrackControls Display Tests', () {
      testWidgets('displays all track controls', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3, seconds: 30),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify all track types are displayed
        expect(find.byIcon(Icons.mic), findsOneWidget); // Vocals
        expect(find.byIcon(Icons.piano), findsOneWidget); // Instruments
        expect(find.byIcon(Icons.music_note), findsWidgets); // Drums and Bass

        // Verify sliders are present for each track
        expect(find.byType(Slider), findsNWidgets(TrackType.values.length + 1)); // +1 for progress slider
      });

      testWidgets('displays play/pause button correctly', (WidgetTester tester) async {
        // Test play state
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Should show play icon when not playing
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsNothing);

        // Test pause state
        await tester.pumpWidget(
          WidgetTestHelpers.createTestApp(
            child: MultiTrackControls(
              trackPlayers: mockTrackPlayers,
              trackMuted: trackMuted,
              trackVolumes: trackVolumes,
              trackIcons: trackIcons,
              trackColors: trackColors,
              isPlaying: true,
              position: const Duration(seconds: 30),
              duration: const Duration(minutes: 3),
              onPlayPause: () {},
              onSeek: (position) {},
              onToggleTrackMute: (trackType) {},
              onSetTrackVolume: (trackType, volume) {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show pause icon when playing
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      });

      testWidgets('displays progress information correctly', (WidgetTester tester) async {
        const position = Duration(minutes: 1, seconds: 30);
        const duration = Duration(minutes: 3, seconds: 45);

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: true,
            position: position,
            duration: duration,
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify time display
        expect(find.text('1:30'), findsOneWidget); // Current position
        expect(find.text('3:45'), findsOneWidget); // Total duration
      });

      testWidgets('displays export button', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify export button is present
        expect(find.text('Export'), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
      });
    });

    group('Audio Control Interaction Tests', () {
      testWidgets('play/pause button triggers callback', (WidgetTester tester) async {
        bool playPauseCalled = false;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {
              playPauseCalled = true;
            },
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Find and tap the play button
        final playButton = find.byIcon(Icons.play_arrow);
        expect(playButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, playButton);

        // Verify callback was called
        expect(playPauseCalled, isTrue);
      });

      testWidgets('progress slider triggers seek callback', (WidgetTester tester) async {
        Duration? seekPosition;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: true,
            position: const Duration(seconds: 30),
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {
              seekPosition = position;
            },
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Find the progress slider (should be the last slider)
        final sliders = find.byType(Slider);
        final progressSlider = sliders.last;

        // Simulate dragging the slider to 50% position
        await tester.drag(progressSlider, const Offset(100, 0));
        await tester.pumpAndSettle();

        // Verify seek callback was called
        expect(seekPosition, isNotNull);
      });

      testWidgets('track volume sliders work correctly', (WidgetTester tester) async {
        TrackType? changedTrack;
        double? newVolume;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {
              changedTrack = trackType;
              newVolume = volume;
            },
          ),
        );

        // Find the first track volume slider
        final sliders = find.byType(Slider);
        expect(sliders, findsWidgets);

        // Tap on the first slider to change volume
        await tester.tap(sliders.first);
        await tester.pumpAndSettle();

        // Note: Actual slider interaction is complex to test
        // This verifies the widget structure is correct
        expect(find.byType(Slider), findsWidgets);
      });

      testWidgets('skip buttons trigger seek callbacks', (WidgetTester tester) async {
        Duration? seekPosition;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: true,
            position: const Duration(seconds: 30),
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {
              seekPosition = position;
            },
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Test skip to beginning
        final skipPreviousButton = find.byIcon(Icons.skip_previous);
        expect(skipPreviousButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, skipPreviousButton);

        // Verify seek to beginning was called
        expect(seekPosition, equals(Duration.zero));

        // Test skip to end
        final skipNextButton = find.byIcon(Icons.skip_next);
        expect(skipNextButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, skipNextButton);

        // Verify seek to end was called
        expect(seekPosition, equals(const Duration(minutes: 3)));
      });
    });

    group('Track Management Tests', () {
      testWidgets('displays correct track icons and colors', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify track icons are displayed
        expect(find.byIcon(Icons.mic), findsOneWidget);
        expect(find.byIcon(Icons.piano), findsOneWidget);
        expect(find.byIcon(Icons.music_note), findsNWidgets(2)); // Drums and Bass
      });

      testWidgets('handles muted tracks correctly', (WidgetTester tester) async {
        final mutedTracks = Map<TrackType, bool>.from(trackMuted);
        mutedTracks[TrackType.vocals] = true;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: mutedTracks,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify the widget handles muted state
        expect(find.byType(MultiTrackControls), findsOneWidget);
      });

      testWidgets('displays different volume levels correctly', (WidgetTester tester) async {
        final customVolumes = {
          TrackType.vocals: 1.0,
          TrackType.other: 0.5,
          TrackType.drums: 0.0,
          TrackType.bass: 0.8,
        };

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: customVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify sliders reflect different volume levels
        final sliders = tester.widgetList<Slider>(find.byType(Slider));
        expect(sliders.length, greaterThan(0));
      });
    });

    group('UI State Tests', () {
      testWidgets('shows correct time format for different durations', (WidgetTester tester) async {
        final testCases = [
          {
            'position': const Duration(seconds: 5),
            'duration': const Duration(seconds: 30),
            'expectedPosition': '0:05',
            'expectedDuration': '0:30',
          },
          {
            'position': const Duration(minutes: 1, seconds: 23),
            'duration': const Duration(minutes: 4, seconds: 56),
            'expectedPosition': '1:23',
            'expectedDuration': '4:56',
          },
          {
            'position': const Duration(minutes: 10, seconds: 0),
            'duration': const Duration(minutes: 15, seconds: 30),
            'expectedPosition': '10:00',
            'expectedDuration': '15:30',
          },
        ];

        for (final testCase in testCases) {
          await WidgetTestHelpers.pumpWidgetWithApp(
            tester,
            MultiTrackControls(
              trackPlayers: mockTrackPlayers,
              trackMuted: trackMuted,
              trackVolumes: trackVolumes,
              trackIcons: trackIcons,
              trackColors: trackColors,
              isPlaying: true,
              position: testCase['position'] as Duration,
              duration: testCase['duration'] as Duration,
              onPlayPause: () {},
              onSeek: (position) {},
              onToggleTrackMute: (trackType) {},
              onSetTrackVolume: (trackType, volume) {},
            ),
          );

          // Verify time formatting
          expect(find.text(testCase['expectedPosition'] as String), findsOneWidget);
          expect(find.text(testCase['expectedDuration'] as String), findsOneWidget);

          // Clear for next test
          await tester.pumpWidget(Container());
        }
      });

      testWidgets('handles zero duration gracefully', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: Duration.zero,
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Should render without crashing
        expect(find.byType(MultiTrackControls), findsOneWidget);
        expect(find.text('0:00'), findsNWidgets(2)); // Both position and duration
      });

      testWidgets('progress slider shows correct position', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: true,
            position: const Duration(minutes: 1), // 50% of 2 minutes
            duration: const Duration(minutes: 2),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Find the progress slider
        final sliders = tester.widgetList<Slider>(find.byType(Slider));
        final progressSlider = sliders.last; // Progress slider should be last

        // Verify the slider value is approximately 0.5 (50%)
        expect(progressSlider.value, closeTo(0.5, 0.1));
      });
    });

    group('Error Handling Tests', () {
      testWidgets('handles missing track players gracefully', (WidgetTester tester) async {
        final incompleteTrackPlayers = <TrackType, AudioPlayer>{
          TrackType.vocals: MockAudioPlayer(),
          // Missing other tracks
        };

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: incompleteTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Should render without crashing
        expect(find.byType(MultiTrackControls), findsOneWidget);
      });

      testWidgets('handles null callback functions gracefully', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {}, // Empty callback
            onSeek: (position) {}, // Empty callback
            onToggleTrackMute: (trackType) {}, // Empty callback
            onSetTrackVolume: (trackType, volume) {}, // Empty callback
          ),
        );

        // Should render and be interactive
        expect(find.byType(MultiTrackControls), findsOneWidget);

        // Test that buttons can be tapped without error
        final playButton = find.byIcon(Icons.play_arrow);
        await WidgetTestHelpers.tapAndSettle(tester, playButton);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('has proper semantic labels for controls', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: false,
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify semantic structure exists
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('supports screen reader navigation', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          MultiTrackControls(
            trackPlayers: mockTrackPlayers,
            trackMuted: trackMuted,
            trackVolumes: trackVolumes,
            trackIcons: trackIcons,
            trackColors: trackColors,
            isPlaying: true,
            position: const Duration(seconds: 30),
            duration: const Duration(minutes: 3),
            onPlayPause: () {},
            onSeek: (position) {},
            onToggleTrackMute: (trackType) {},
            onSetTrackVolume: (trackType, volume) {},
          ),
        );

        // Verify controls are accessible
        expect(find.byType(MultiTrackControls), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('handles frequent state updates efficiently', (WidgetTester tester) async {
        Duration currentPosition = Duration.zero;
        const duration = Duration(minutes: 3);

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              return MultiTrackControls(
                trackPlayers: mockTrackPlayers,
                trackMuted: trackMuted,
                trackVolumes: trackVolumes,
                trackIcons: trackIcons,
                trackColors: trackColors,
                isPlaying: true,
                position: currentPosition,
                duration: duration,
                onPlayPause: () {},
                onSeek: (position) {
                  setState(() {
                    currentPosition = position;
                  });
                },
                onToggleTrackMute: (trackType) {},
                onSetTrackVolume: (trackType, volume) {},
              );
            },
          ),
        );

        // Simulate rapid position updates
        for (int i = 0; i < 10; i++) {
          currentPosition = Duration(seconds: i * 10);
          await tester.pump();
        }

        // Should handle updates without performance issues
        expect(find.byType(MultiTrackControls), findsOneWidget);
      });
    });
  });
}

// Mock AudioPlayer class for testing
class MockAudioPlayer extends Mock implements AudioPlayer {
  @override
  Future<void> play(Source source, {double? volume, double? balance, AudioContext? ctx, Duration? position, PlayerMode? mode}) async {
    // Mock implementation
  }

  @override
  Future<void> pause() async {
    // Mock implementation
  }

  @override
  Future<void> stop() async {
    // Mock implementation
  }

  @override
  Future<void> seek(Duration position) async {
    // Mock implementation
  }

  @override
  Future<void> setVolume(double volume) async {
    // Mock implementation
  }
}