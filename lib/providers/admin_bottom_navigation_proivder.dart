import 'package:flutter/material.dart';

class AdminNavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    if (index < 0 || index >= 5) return;
    if (_currentIndex == index) return;

    _currentIndex = index;
    notifyListeners();
  }

  void goToDashboard() => changeTab(0);

  void goToTransactions() => changeTab(1);
}