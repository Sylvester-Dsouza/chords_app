import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  // Getter for current index
  int get currentIndex => _currentIndex;

  // Method to update the current index
  void updateIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Method to get the correct index for a specific route
  int getIndexForRoute(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/playlist':
        return 1;
      case '/search':
        return 2;
      case '/tools':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }

  // Method to get the route for a specific index
  String getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/playlist';
      case 2:
        return '/search';
      case 3:
        return '/tools';
      case 4:
        return '/profile';
      default:
        return '/home';
    }
  }
}
