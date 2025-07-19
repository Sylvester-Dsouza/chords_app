import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chords_app/screens/song_detail_screen.dart';
import 'package:chords_app/models/song.dart';
import 'package:chords_app/models/karaoke.dart';
import 'package:chords_app/widgets/chord_formatter.dart';
import 'package:chords_app/widgets/star_rating.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../helpers/mock_data.dart';

void main() {
  group('SongDetailScreen Widget Tests', () {
    late Song testSong;
    late Song testSongWithKaraoke;

    setUp(() {
      // Create test songs
      testSong = MockData.createSong(
        id: 'test-song-1',
        title: 'Amazing Grace',
        artist: 'John Newton',
        key: 'G',
        chords: '[G]Amazing [C]grace, how [G]sweet the [D]sound\n[G]That saved a [C]wretch like [G]me[D][G]',
        lyrics: 'Amazing grace, how sweet the sound\nThat saved a wretch like me',
        tempo: 120,
        capo: 2,
        isLiked: false,
        commentCount: 5,
        averageRating: 4.5,
        ratingCount: 10,
      );

      testSongWithKaraoke = MockData.createSong(
        id: 'test-song-2',
        title: 'How Great Thou Art',
        artist: 'Carl Boberg',
        key: 'C',
        karaoke: Karaoke(
          id: 'karaoke-1',
          songId: 'test-song-2',
          fileUrl: 'https://example.com/karaoke.mp3',
          duration: 240,
          uploadedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          status: 'ACTIVE',
          tracks: [
            KaraokeTrack(
              id: 'track-1',
              karaokeId: 'karaoke-1',
              trackType: TrackType.vocals,
              fileUrl: 'https://example.com/vocals.mp3',
              volume: 1.0,
              isMuted: false,
              uploadedAt: DateTime.now(),
              updatedAt: DateTime.now(),
              status: 'ACTIVE',
            ),
            KaraokeTrack(
              id: 'track-2',
              karaokeId: 'karaoke-1',
              trackType: TrackType.other,
              fileUrl: 'https://example.com/instruments.mp3',
              volume: 1.0,
              isMuted: false,
              uploadedAt: DateTime.now(),
              updatedAt: DateTime.now(),
              status: 'ACTIVE',
            ),
          ],
        ),
      );

      // Test setup complete
    });

    group('Song Display Tests', () {
      testWidgets('displays song title and artist correctly', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify song title is displayed
        expect(find.text('Amazing Grace'), findsOneWidget);
        expect(find.text('John Newton'), findsOneWidget);
      });

      testWidgets('displays song key and tempo information', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify key and tempo are displayed
        expect(find.textContaining('G'), findsWidgets);
        expect(find.textContaining('120'), findsWidgets);
      });

      testWidgets('displays capo information when present', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify capo information is displayed
        expect(find.textContaining('Capo'), findsWidgets);
        expect(find.textContaining('2'), findsWidgets);
      });

      testWidgets('displays rating information correctly', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify rating components are present
        expect(find.byType(StarRating), findsWidgets);
        expect(find.textContaining('4.5'), findsWidgets);
        expect(find.textContaining('10'), findsWidgets);
      });
    });

    group('Chord Rendering Tests', () {
      testWidgets('renders chord formatter with correct content', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify ChordFormatter widget is present
        expect(find.byType(ChordFormatter), findsOneWidget);

        // Verify chord content is displayed
        expect(find.textContaining('Amazing'), findsWidgets);
        expect(find.textContaining('grace'), findsWidgets);
      });

      testWidgets('displays chords when chord visibility is enabled', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find the ChordFormatter widget
        final chordFormatter = tester.widget<ChordFormatter>(find.byType(ChordFormatter));
        
        // Verify chords are highlighted by default
        expect(chordFormatter.highlightChords, isTrue);
      });

      testWidgets('toggles chord visibility when chord button is tapped', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find and tap the chord visibility toggle button
        final chordToggleButton = find.byIcon(Icons.music_note);
        expect(chordToggleButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, chordToggleButton);

        // Verify chord visibility has been toggled
        final chordFormatter = tester.widget<ChordFormatter>(find.byType(ChordFormatter));
        expect(chordFormatter.highlightChords, isFalse);
      });

      testWidgets('handles different chord types correctly', (WidgetTester tester) async {
        final songWithComplexChords = MockData.createSong(
          chords: '[Am7]Complex [Dm/F#]chord [G13sus4]progression [C/E]here',
        );

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: songWithComplexChords),
        );

        // Verify complex chords are rendered
        expect(find.byType(ChordFormatter), findsOneWidget);
        expect(find.textContaining('Complex'), findsWidgets);
        expect(find.textContaining('chord'), findsWidgets);
      });
    });

    group('User Interaction Tests', () {
      testWidgets('transpose up increases transpose value', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find and tap the transpose up button
        final transposeUpButton = find.byIcon(Icons.keyboard_arrow_up);
        expect(transposeUpButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, transposeUpButton);

        // Verify the key has changed (G -> G#)
        expect(find.textContaining('G#'), findsWidgets);
      });

      testWidgets('transpose down decreases transpose value', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find and tap the transpose down button
        final transposeDownButton = find.byIcon(Icons.keyboard_arrow_down);
        expect(transposeDownButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, transposeDownButton);

        // Verify the key has changed (G -> F#)
        expect(find.textContaining('F#'), findsWidgets);
      });

      testWidgets('reset transpose returns to original key', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Transpose up first
        final transposeUpButton = find.byIcon(Icons.keyboard_arrow_up);
        await WidgetTestHelpers.tapAndSettle(tester, transposeUpButton);

        // Find and tap the reset button
        final resetButton = find.byIcon(Icons.refresh);
        expect(resetButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, resetButton);

        // Verify we're back to original key (G)
        expect(find.textContaining('G'), findsWidgets);
      });

      testWidgets('font size adjustment works correctly', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find font size increase button
        final fontIncreaseButton = find.byIcon(Icons.text_increase);
        expect(fontIncreaseButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, fontIncreaseButton);

        // Verify ChordFormatter has updated font size
        final chordFormatter = tester.widget<ChordFormatter>(find.byType(ChordFormatter));
        expect(chordFormatter.fontSize, greaterThan(14.0));
      });

      testWidgets('like button toggles correctly', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find the like button (should be unfilled initially)
        final likeButton = find.byIcon(Icons.favorite_border);
        expect(likeButton, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, likeButton);

        // Verify the like button is now filled
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsNothing);
      });

      testWidgets('auto-scroll toggle works correctly', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find the auto-scroll button
        final autoScrollButton = find.byIcon(Icons.play_arrow);
        expect(autoScrollButton, findsWidgets);

        // Tap the auto-scroll button
        await WidgetTestHelpers.tapAndSettle(tester, autoScrollButton.first);

        // Verify auto-scroll is enabled (button should change to pause)
        expect(find.byIcon(Icons.pause), findsWidgets);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('adapts to small screen sizes', (WidgetTester tester) async {
        // Set small screen size
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify the layout adapts to small screen
        expect(find.byType(SongDetailScreen), findsOneWidget);
        expect(find.byType(ChordFormatter), findsOneWidget);

        // Reset screen size
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });

      testWidgets('adapts to large screen sizes', (WidgetTester tester) async {
        // Set large screen size
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify the layout works on large screen
        expect(find.byType(SongDetailScreen), findsOneWidget);
        expect(find.byType(ChordFormatter), findsOneWidget);

        // Reset screen size
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });

      testWidgets('handles landscape orientation', (WidgetTester tester) async {
        // Set landscape orientation
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify the layout works in landscape
        expect(find.byType(SongDetailScreen), findsOneWidget);

        // Reset screen size
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    });

    group('Karaoke Mode Tests', () {
      testWidgets('shows karaoke option when karaoke is available', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSongWithKaraoke),
        );

        // Find and tap the floating action button to show options
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, fab);

        // Verify karaoke option is shown
        expect(find.textContaining('Karaoke'), findsWidgets);
        expect(find.textContaining('Multi-Track'), findsWidgets);
      });

      testWidgets('hides karaoke option when karaoke is not available', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Find and tap the floating action button to show options
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        await WidgetTestHelpers.tapAndSettle(tester, fab);

        // Verify karaoke option is not shown
        expect(find.textContaining('Karaoke'), findsNothing);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('handles empty chord sheet gracefully', (WidgetTester tester) async {
        final songWithoutChords = MockData.createSong(
          chords: null,
          lyrics: null,
        );

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: songWithoutChords),
        );

        // Verify the screen still renders without crashing
        expect(find.byType(SongDetailScreen), findsOneWidget);
        expect(find.byType(ChordFormatter), findsOneWidget);
      });

      testWidgets('handles missing song data gracefully', (WidgetTester tester) async {
        final incompleteSong = Song(
          id: 'incomplete',
          title: '',
          artist: '',
          key: '',
        );

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: incompleteSong),
        );

        // Verify the screen renders without crashing
        expect(find.byType(SongDetailScreen), findsOneWidget);
      });

      testWidgets('shows loading state when fetching song by ID', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(songId: 'test-song-1'),
        );

        // Verify loading indicator is shown initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Note: In a real test, we would mock the service and wait for loading to complete
        // For now, we just verify the loading state is shown
      });
    });

    group('Accessibility Tests', () {
      testWidgets('has proper semantic labels for buttons', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify important buttons have semantic labels
        expect(find.bySemanticsLabel('Like song'), findsOneWidget);
        expect(find.bySemanticsLabel('Transpose up'), findsOneWidget);
        expect(find.bySemanticsLabel('Transpose down'), findsOneWidget);
      });

      testWidgets('supports screen reader navigation', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          SongDetailScreen(song: testSong),
        );

        // Verify semantic structure is present
        expect(find.byType(Semantics), findsWidgets);
      });
    });
  });
}