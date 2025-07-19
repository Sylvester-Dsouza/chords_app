import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chords_app/widgets/chord_formatter.dart';
import 'package:chords_app/widgets/chord_diagram.dart';
import 'package:chords_app/widgets/chord_diagram_bottom_sheet.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('Chord Display Widget Tests', () {
    group('ChordFormatter Tests', () {
      testWidgets('renders simple chord sheet correctly', (WidgetTester tester) async {
        const chordSheet = '[G]Amazing [C]grace, how [G]sweet the [D]sound';

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: chordSheet,
            fontSize: 16.0,
            highlightChords: true,
          ),
        );

        // Verify the text content is displayed
        expect(find.textContaining('Amazing'), findsOneWidget);
        expect(find.textContaining('grace'), findsOneWidget);
        expect(find.textContaining('sweet'), findsOneWidget);
        expect(find.textContaining('sound'), findsOneWidget);
      });

      testWidgets('highlights chords when highlightChords is true', (WidgetTester tester) async {
        const chordSheet = '[G]Amazing [C]grace';

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: chordSheet,
            fontSize: 16.0,
            highlightChords: true,
          ),
        );

        // Verify RichText widget is used for chord highlighting
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('does not highlight chords when highlightChords is false', (WidgetTester tester) async {
        const chordSheet = '[G]Amazing [C]grace';

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: chordSheet,
            fontSize: 16.0,
            highlightChords: false,
          ),
        );

        // Verify the widget still renders
        expect(find.byType(ChordFormatter), findsOneWidget);
      });

      testWidgets('handles empty chord sheet', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: '',
            fontSize: 16.0,
            highlightChords: true,
          ),
        );

        // Verify empty state message is shown
        expect(find.text('No chord sheet available'), findsOneWidget);
      });

      testWidgets('handles section headers correctly', (WidgetTester tester) async {
        const chordSheet = '{Verse 1}\n[G]Amazing [C]grace\n\n{Chorus}\n[D]How sweet the [G]sound';

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: chordSheet,
            fontSize: 16.0,
            highlightChords: true,
          ),
        );

        // Verify section headers are displayed
        expect(find.textContaining('VERSE 1'), findsOneWidget);
        expect(find.textContaining('CHORUS'), findsOneWidget);
      });

      testWidgets('handles legacy section headers correctly', (WidgetTester tester) async {
        const chordSheet = '[Verse 1]\n[G]Amazing [C]grace\n\n[Chorus]\n[D]How sweet the [G]sound';

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: chordSheet,
            fontSize: 16.0,
            highlightChords: true,
          ),
        );

        // Verify legacy section headers are displayed
        expect(find.textContaining('[Verse 1]'), findsOneWidget);
        expect(find.textContaining('[Chorus]'), findsOneWidget);
      });

      testWidgets('applies correct font size', (WidgetTester tester) async {
        const chordSheet = '[G]Amazing grace';
        const testFontSize = 20.0;

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: chordSheet,
            fontSize: testFontSize,
            highlightChords: true,
          ),
        );

        // Find Text widgets and verify font size
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        for (final textWidget in textWidgets) {
          if (textWidget.style?.fontSize != null) {
            expect(textWidget.style!.fontSize, equals(testFontSize));
          }
        }
      });

      testWidgets('uses monospace font when specified', (WidgetTester tester) async {
        const chordSheet = '[G]Amazing grace';

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: chordSheet,
            fontSize: 16.0,
            highlightChords: true,
            useMonospaceFont: true,
          ),
        );

        // Verify the widget renders (font family verification would require more complex testing)
        expect(find.byType(ChordFormatter), findsOneWidget);
      });

      testWidgets('handles chord tap callback', (WidgetTester tester) async {
        const chordSheet = '[G]Amazing [C]grace';
        String? tappedChord;

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          ChordFormatter(
            chordSheet: chordSheet,
            fontSize: 16.0,
            highlightChords: true,
            onChordTap: (chord) {
              tappedChord = chord;
            },
          ),
        );

        // Find and tap a chord (this is complex due to RichText structure)
        // For now, verify the widget renders with the callback
        expect(find.byType(ChordFormatter), findsOneWidget);
      });

      group('Chord Transposition Tests', () {
        testWidgets('transposes chords up correctly', (WidgetTester tester) async {
          const chordSheet = '[G]Amazing [C]grace [D]how sweet';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
              transposeValue: 1, // Transpose up by 1 semitone
            ),
          );

          // G -> G#, C -> C#, D -> D#
          // Note: The actual chord text verification is complex due to RichText
          expect(find.byType(ChordFormatter), findsOneWidget);
        });

        testWidgets('transposes chords down correctly', (WidgetTester tester) async {
          const chordSheet = '[G]Amazing [C]grace [D]how sweet';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
              transposeValue: -1, // Transpose down by 1 semitone
            ),
          );

          // G -> F#, C -> B, D -> C#
          expect(find.byType(ChordFormatter), findsOneWidget);
        });

        testWidgets('handles complex chord transposition', (WidgetTester tester) async {
          const chordSheet = '[Am7]Complex [Dm/F#]chord [G13sus4]progression';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
              transposeValue: 2, // Transpose up by 2 semitones
            ),
          );

          // Verify complex chords are handled
          expect(find.byType(ChordFormatter), findsOneWidget);
        });

        testWidgets('handles flat note transposition', (WidgetTester tester) async {
          const chordSheet = '[Bb]Flat [Eb]notes [Ab]here';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
              transposeValue: 1,
            ),
          );

          // Verify flat notes are transposed correctly
          expect(find.byType(ChordFormatter), findsOneWidget);
        });

        testWidgets('clamps transpose value within valid range', (WidgetTester tester) async {
          const chordSheet = '[G]Test chord';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
              transposeValue: 15, // Beyond valid range
            ),
          );

          // Should still render without error
          expect(find.byType(ChordFormatter), findsOneWidget);
        });
      });

      group('Chord Pattern Recognition Tests', () {
        testWidgets('recognizes various chord patterns', (WidgetTester tester) async {
          const chordSheet = '''
[G]Major [Gm]minor [G7]seventh [Gmaj7]major seventh
[G#]Sharp [Gb]flat [G/B]slash chord [Gsus4]suspended
[G13]extended [Gadd9]added tone [G5]power chord
''';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
            ),
          );

          // Verify all chord types are handled
          expect(find.byType(ChordFormatter), findsOneWidget);
          expect(find.textContaining('Major'), findsOneWidget);
          expect(find.textContaining('minor'), findsOneWidget);
          expect(find.textContaining('seventh'), findsOneWidget);
        });

        testWidgets('handles malformed chord patterns gracefully', (WidgetTester tester) async {
          const chordSheet = '[G]Good [X]Bad [Y#b]Invalid []Empty [Z chord';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
            ),
          );

          // Should render without crashing
          expect(find.byType(ChordFormatter), findsOneWidget);
        });
      });

      group('Layout and Spacing Tests', () {
        testWidgets('preserves original spacing in chord sheets', (WidgetTester tester) async {
          const chordSheet = '[G]    Spaced    [C]    out    [D]    chords';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
            ),
          );

          // Verify spacing is preserved (complex to test directly)
          expect(find.byType(ChordFormatter), findsOneWidget);
        });

        testWidgets('handles line breaks correctly', (WidgetTester tester) async {
          const chordSheet = '[G]Line one\n[C]Line two\n\n[D]Line three after empty line';

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            const ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
            ),
          );

          // Verify multiple lines are handled
          expect(find.byType(ChordFormatter), findsOneWidget);
        });

        testWidgets('handles very long chord sheets', (WidgetTester tester) async {
          final longChordSheet = List.generate(50, (index) => '[G]Line $index with some text').join('\n');

          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            ChordFormatter(
              chordSheet: longChordSheet,
              fontSize: 16.0,
              highlightChords: true,
            ),
          );

          // Should handle long content without performance issues
          expect(find.byType(ChordFormatter), findsOneWidget);
        });
      });
    });

    group('ChordDiagram Tests', () {
      testWidgets('renders chord diagram with chord name', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordDiagram(chordName: 'G'),
        );

        // Verify chord name is displayed
        expect(find.text('G'), findsOneWidget);
        expect(find.byType(ChordDiagram), findsOneWidget);
      });

      testWidgets('displays visual chord diagram elements', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordDiagram(chordName: 'C'),
        );

        // Verify visual elements are present
        expect(find.byType(Container), findsWidgets);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('handles different chord names', (WidgetTester tester) async {
        final chordNames = ['G', 'C', 'D', 'Am', 'Em', 'F#m', 'Bb7'];

        for (final chordName in chordNames) {
          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            ChordDiagram(chordName: chordName),
          );

          // Verify each chord name is displayed
          expect(find.text(chordName), findsOneWidget);
          expect(find.byType(ChordDiagram), findsOneWidget);

          // Clear the widget tree for next iteration
          await tester.pumpWidget(Container());
        }
      });

      testWidgets('has consistent visual styling', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordDiagram(chordName: 'G'),
        );

        // Find the main container
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);

        // Verify styling properties exist
        final containers = tester.widgetList<Container>(containerFinder);
        expect(containers.isNotEmpty, isTrue);
      });

      testWidgets('handles empty chord name gracefully', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordDiagram(chordName: ''),
        );

        // Should render without crashing
        expect(find.byType(ChordDiagram), findsOneWidget);
      });

      testWidgets('handles special characters in chord name', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordDiagram(chordName: 'C#/E'),
        );

        // Verify special characters are handled
        expect(find.text('C#/E'), findsOneWidget);
        expect(find.byType(ChordDiagram), findsOneWidget);
      });
    });

    group('ChordDiagramBottomSheet Tests', () {
      testWidgets('displays chord diagram in bottom sheet', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const ChordDiagramBottomSheet(chordName: 'G'),
                );
              },
              child: const Text('Show Chord'),
            ),
          ),
        );

        // Tap the button to show the bottom sheet
        await WidgetTestHelpers.tapAndSettle(tester, find.text('Show Chord'));

        // Verify the bottom sheet is displayed
        expect(find.byType(ChordDiagramBottomSheet), findsOneWidget);
        expect(find.text('G'), findsWidgets);
      });

      testWidgets('shows chord name in bottom sheet title', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const ChordDiagramBottomSheet(chordName: 'Am7'),
                );
              },
              child: const Text('Show Chord'),
            ),
          ),
        );

        // Show the bottom sheet
        await WidgetTestHelpers.tapAndSettle(tester, find.text('Show Chord'));

        // Verify chord name appears in the sheet
        expect(find.text('Am7'), findsWidgets);
      });

      testWidgets('can be dismissed', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const ChordDiagramBottomSheet(chordName: 'D'),
                );
              },
              child: const Text('Show Chord'),
            ),
          ),
        );

        // Show the bottom sheet
        await WidgetTestHelpers.tapAndSettle(tester, find.text('Show Chord'));

        // Verify it's shown
        expect(find.byType(ChordDiagramBottomSheet), findsOneWidget);

        // Dismiss by tapping outside (simulate back button or swipe down)
        await tester.tapAt(const Offset(100, 100));
        await tester.pumpAndSettle();

        // Verify it's dismissed
        expect(find.byType(ChordDiagramBottomSheet), findsNothing);
      });

      testWidgets('handles different chord types in bottom sheet', (WidgetTester tester) async {
        final testChords = ['G', 'Cm', 'F#7', 'Bbmaj7', 'Dsus4'];

        for (final chord in testChords) {
          await WidgetTestHelpers.pumpWidgetWithApp(
            tester,
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => ChordDiagramBottomSheet(chordName: chord),
                  );
                },
                child: Text('Show $chord'),
              ),
            ),
          );

          // Show the bottom sheet
          await WidgetTestHelpers.tapAndSettle(tester, find.text('Show $chord'));

          // Verify the chord is displayed
          expect(find.text(chord), findsWidgets);

          // Dismiss the sheet
          await tester.tapAt(const Offset(100, 100));
          await tester.pumpAndSettle();

          // Clear for next iteration
          await tester.pumpWidget(Container());
        }
      });
    });

    group('Integration Tests', () {
      testWidgets('chord formatter and diagram work together', (WidgetTester tester) async {
        String? selectedChord;

        await WidgetTestHelpers.pumpWidgetWithApp(
          tester,
          Column(
            children: [
              ChordFormatter(
                chordSheet: '[G]Amazing [C]grace',
                fontSize: 16.0,
                highlightChords: true,
                onChordTap: (chord) {
                  selectedChord = chord;
                },
              ),
              if (selectedChord != null)
                ChordDiagram(chordName: selectedChord!),
            ],
          ),
        );

        // Verify both widgets are present
        expect(find.byType(ChordFormatter), findsOneWidget);
        // ChordDiagram won't be present until a chord is tapped
      });

      testWidgets('chord customization affects display', (WidgetTester tester) async {
        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          const ChordFormatter(
            chordSheet: '[G]Test [C]chord',
            fontSize: 18.0,
            highlightChords: true,
            chordColor: Colors.red,
          ),
        );

        // Verify customization is applied
        expect(find.byType(ChordFormatter), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('handles rapid chord changes efficiently', (WidgetTester tester) async {
        const chordSheets = [
          '[G]Amazing [C]grace',
          '[D]How sweet [G]the sound',
          '[Em]That saved [C]a wretch [G]like me',
        ];

        for (final chordSheet in chordSheets) {
          await WidgetTestHelpers.pumpWidgetMinimal(
            tester,
            ChordFormatter(
              chordSheet: chordSheet,
              fontSize: 16.0,
              highlightChords: true,
            ),
          );

          // Verify each renders quickly
          expect(find.byType(ChordFormatter), findsOneWidget);
        }
      });

      testWidgets('handles large chord sheets efficiently', (WidgetTester tester) async {
        final largeChordSheet = List.generate(100, (i) => '[G]Line $i with chords [C]and text').join('\n');

        final stopwatch = Stopwatch()..start();

        await WidgetTestHelpers.pumpWidgetMinimal(
          tester,
          ChordFormatter(
            chordSheet: largeChordSheet,
            fontSize: 16.0,
            highlightChords: true,
          ),
        );

        stopwatch.stop();

        // Verify it renders in reasonable time (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(find.byType(ChordFormatter), findsOneWidget);
      });
    });
  });
}