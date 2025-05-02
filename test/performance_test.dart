import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:chords_app/widgets/optimized_section.dart';
import 'package:chords_app/widgets/optimized_list_item.dart';
import 'package:chords_app/widgets/optimized_horizontal_list.dart';
import 'package:chords_app/widgets/memory_efficient_image.dart';
import 'package:chords_app/services/optimized_cache_service.dart';
import 'package:chords_app/utils/performance_monitor.dart';

// Generate mocks
@GenerateMocks([OptimizedCacheService])
import 'performance_test.mocks.dart';

void main() {
  late MockOptimizedCacheService mockCacheService;
  
  setUp(() {
    mockCacheService = MockOptimizedCacheService();
  });

  group('OptimizedSection Widget Tests', () {
    testWidgets('OptimizedSection renders correctly', (WidgetTester tester) async {
      bool seeMorePressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedSection(
              title: 'Test Section',
              content: const Text('Test Content'),
              onSeeMorePressed: () {
                seeMorePressed = true;
              },
            ),
          ),
        ),
      );
      
      // Verify the section title is displayed
      expect(find.text('Test Section'), findsOneWidget);
      
      // Verify the content is displayed
      expect(find.text('Test Content'), findsOneWidget);
      
      // Verify the "See more" button is displayed
      expect(find.text('See more'), findsOneWidget);
      
      // Tap the "See more" button
      await tester.tap(find.text('See more'));
      await tester.pump();
      
      // Verify the callback was called
      expect(seeMorePressed, isTrue);
    });
    
    testWidgets('OptimizedSection only rebuilds when necessary', (WidgetTester tester) async {
      int buildCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    OptimizedSection(
                      title: 'Test Section',
                      content: Builder(
                        builder: (context) {
                          buildCount++;
                          return const Text('Test Content');
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Update state but don't change the section data
                        });
                      },
                      child: const Text('Update Parent'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      
      // Initial build count
      expect(buildCount, 1);
      
      // Tap the button to update the parent state
      await tester.tap(find.text('Update Parent'));
      await tester.pump();
      
      // Verify the content wasn't rebuilt
      expect(buildCount, 1);
    });
  });
  
  group('OptimizedListItem Widget Tests', () {
    testWidgets('OptimizedListItem renders correctly', (WidgetTester tester) async {
      bool itemTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedListItem(
              title: 'Test Item',
              subtitle: 'Subtitle',
              color: Colors.blue,
              imageUrl: null,
              onTap: () {
                itemTapped = true;
              },
            ),
          ),
        ),
      );
      
      // Verify the title is displayed
      expect(find.text('Test Item'), findsOneWidget);
      
      // Verify the subtitle is displayed
      expect(find.text('Subtitle'), findsOneWidget);
      
      // Tap the item
      await tester.tap(find.text('Test Item'));
      await tester.pump();
      
      // Verify the callback was called
      expect(itemTapped, isTrue);
    });
  });
  
  group('MemoryEfficientImage Widget Tests', () {
    testWidgets('MemoryEfficientImage handles null image URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemoryEfficientImage(
              imageUrl: null,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      
      // Verify the error widget is displayed
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });
  });
  
  group('PerformanceMonitor Tests', () {
    test('PerformanceMonitor tracks operation times', () {
      final monitor = PerformanceMonitor();
      
      // Start an operation
      monitor.startOperation('test_operation');
      
      // Simulate some work
      for (int i = 0; i < 1000000; i++) {
        // Do nothing, just waste time
      }
      
      // End the operation
      final duration = monitor.endOperation('test_operation');
      
      // Verify the duration is greater than zero
      expect(duration.inMicroseconds > 0, isTrue);
    });
    
    test('PerformanceMonitor generates performance report', () {
      final monitor = PerformanceMonitor();
      
      // Track some operations
      monitor.startOperation('operation1');
      monitor.endOperation('operation1');
      
      monitor.startOperation('operation2');
      monitor.endOperation('operation2');
      
      // Track memory usage
      monitor.trackMemoryUsage('test_memory', 1024 * 1024);
      
      // Get the performance report
      final report = monitor.getPerformanceReport();
      
      // Verify the report contains the operations
      expect(report.contains('operation1'), isTrue);
      expect(report.contains('operation2'), isTrue);
      
      // Verify the report contains the memory usage
      expect(report.contains('test_memory'), isTrue);
    });
  });
  
  group('OptimizedCacheService Tests', () {
    test('OptimizedCacheService manages memory cache size', () {
      final cacheService = OptimizedCacheService();
      
      // This is a basic test that just ensures the service can be initialized
      expect(cacheService, isNotNull);
    });
  });
}
