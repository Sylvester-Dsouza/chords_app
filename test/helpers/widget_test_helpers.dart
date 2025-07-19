import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/providers/app_data_provider.dart';
import '../../lib/providers/user_provider.dart';
import '../../lib/providers/navigation_provider.dart';
import '../../lib/models/song.dart';
import '../../lib/models/artist.dart';
import '../../lib/models/collection.dart';
import 'test_helpers.dart';
import 'mock_data.dart';

/// Widget test helper class providing common testing utilities for widgets
class WidgetTestHelpers {
  /// Creates a test app wrapper with minimal providers for testing
  static Widget createTestApp({
    required Widget child,
    ThemeData? theme,
    Locale? locale,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      darkTheme: ThemeData.dark(),
      locale: locale ?? const Locale('en'),
      home: child,
      // Disable debug banner for cleaner test screenshots
      debugShowCheckedModeBanner: false,
    );
  }

  /// Creates a minimal test app wrapper for simple widget tests
  static Widget createMinimalTestApp({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Creates a test app with navigation for testing screen transitions
  static Widget createNavigationTestApp({
    required Widget home,
    Map<String, WidgetBuilder>? routes,
    String? initialRoute,
  }) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: home,
      routes: routes ?? {},
      initialRoute: initialRoute,
      debugShowCheckedModeBanner: false,
    );
  }

  /// Pumps a widget with the test app wrapper
  static Future<void> pumpWidgetWithApp(
    WidgetTester tester,
    Widget widget, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      createTestApp(
        child: widget,
        theme: theme,
      ),
    );
  }

  /// Pumps a widget with minimal app wrapper
  static Future<void> pumpWidgetMinimal(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(createMinimalTestApp(child: widget));
  }

  /// Finds a widget by its test key
  static Finder findByTestKey(String key) {
    return find.byKey(Key(key));
  }

  /// Finds a widget by its icon
  static Finder findByIcon(IconData icon) {
    return find.byIcon(icon);
  }

  /// Finds a text field by its label
  static Finder findTextFieldByLabel(String label) {
    return find.widgetWithText(TextFormField, label);
  }

  /// Finds a button by its text
  static Finder findButtonByText(String text) {
    return find.widgetWithText(ElevatedButton, text);
  }

  /// Verifies that a snackbar with specific text is shown
  static void expectSnackBar(String text) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(text), findsOneWidget);
  }

  /// Verifies that a dialog with specific text is shown
  static void expectDialog(String text) {
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(text), findsOneWidget);
  }

  /// Verifies that a loading indicator is shown
  static void expectLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Verifies that an error widget is shown
  static void expectErrorWidget([String? errorText]) {
    expect(find.byType(Icon), findsWidgets);
    if (errorText != null) {
      expect(find.text(errorText), findsOneWidget);
    }
  }

  /// Simulates a tap on a widget and waits for animations
  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Simulates entering text and waits for animations
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Simulates a long press on a widget
  static Future<void> longPressAndSettle(WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// Simulates a drag gesture
  static Future<void> dragAndSettle(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// Simulates a scroll gesture
  static Future<void> scrollAndSettle(
    WidgetTester tester,
    Finder finder,
    double delta,
  ) async {
    await tester.drag(finder, Offset(0, delta));
    await tester.pumpAndSettle();
  }

  /// Waits for a specific widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      
      if (tester.any(finder)) {
        return;
      }
    }
    
    throw TimeoutException('Widget not found within timeout', timeout);
  }

  /// Verifies widget properties
  static void verifyWidgetProperty<T extends Widget>(
    WidgetTester tester,
    Finder finder,
    bool Function(T widget) predicate,
  ) {
    final widget = tester.widget<T>(finder);
    expect(predicate(widget), isTrue);
  }

  /// Takes a screenshot of the current widget tree (useful for golden tests)
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/$name.png'),
    );
  }
}

/// Mock AuthProvider for testing
class MockAuthProvider extends AuthProvider {
  bool _isAuthenticated = false;
  String? _userId;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get userId => _userId;

  void setAuthenticated(bool authenticated, [String? userId]) {
    _isAuthenticated = authenticated;
    _userId = userId;
    notifyListeners();
  }

  @override
  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    setAuthenticated(true, 'test-user-id');
    return true;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    setAuthenticated(false);
  }
}

/// Mock AppDataProvider for testing - simplified version
class MockAppDataProvider extends ChangeNotifier {
  List<Song> _songs = MockData.createSongList().cast<Song>();
  List<Artist> _artists = MockData.createArtistList().cast<Artist>();
  List<Collection> _collections = MockData.createCollectionList().cast<Collection>();
  bool _isLoading = false;

  List<Song> get songs => _songs;
  List<Artist> get artists => _artists;
  List<Collection> get collections => _collections;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setSongs(List<Song> songs) {
    _songs = songs;
    notifyListeners();
  }

  void setArtists(List<Artist> artists) {
    _artists = artists;
    notifyListeners();
  }

  void setCollections(List<Collection> collections) {
    _collections = collections;
    notifyListeners();
  }

  Future<void> loadSongs() async {
    setLoading(true);
    await Future.delayed(const Duration(milliseconds: 100));
    setSongs(MockData.createSongList().cast<Song>());
    setLoading(false);
  }
}

/// Mock UserProvider for testing
class MockUserProvider extends UserProvider {
  dynamic _currentUser = MockData.createUser();

  @override
  dynamic get currentUser => _currentUser;

  void setCurrentUser(dynamic user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulate profile update
    notifyListeners();
  }
}

/// Mock NavigationProvider for testing
class MockNavigationProvider extends NavigationProvider {
  int _currentIndex = 0;
  String _currentRoute = '/';

  @override
  int get currentIndex => _currentIndex;

  @override
  String get currentRoute => _currentRoute;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setCurrentRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  @override
  void navigateToIndex(int index) {
    setCurrentIndex(index);
  }

  @override
  void navigateToRoute(String route) {
    setCurrentRoute(route);
  }
}

/// Exception for timeout scenarios in tests
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}