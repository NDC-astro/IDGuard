import 'package:flutter/foundation.dart';


/// Provider for authentication state
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void setBiometricAvailable(bool value) {
    _isBiometricAvailable = value;
    notifyListeners();
  }

  void setBiometricEnabled(bool value) {
    _isBiometricEnabled = value;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
