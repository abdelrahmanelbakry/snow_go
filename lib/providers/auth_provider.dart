import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/aws_http_client_service.dart';

enum UserRole { customer, provider }

class AuthProvider extends ChangeNotifier {
  final AWSHttpClientService _httpClient = AWSHttpClientService();

  User? _user;
  UserRole? _userRole;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isCustomer => _userRole == UserRole.customer;
  bool get isProvider => _userRole == UserRole.provider;

  AuthProvider() {
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    try {
      // Load user from preferences (replacing Firebase auth state changes)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');

      if (userId != null && userRole != null) {
        _user = User(id: userId, email: '', name: '');
        _userRole = UserRole.values.firstWhere(
          (role) => role.name == userRole,
          orElse: () => UserRole.customer,
        );
      } else {
        _user = null;
        _userRole = null;
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);

      final result = await _httpClient.login(email, password);

      if (result.isSuccess && result.data != null) {
        final userData = result.data!;
        _user = User(
          id: userData['user']['id'],
          email: userData['user']['email'],
          name: userData['user']['name'],
        );

        // Get user role from response
        _userRole = UserRole.values.firstWhere(
          (role) => role.name == userData['user']['role'],
          orElse: () => UserRole.customer,
        );

        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_role', _userRole!.name);

        // Set auth token in HTTP client
        _httpClient.setAuthToken(userData['token']);

        _error = null;
      } else {
        _error = result.error ?? 'Login failed';
      }

      _setLoading(false);
      return result.isSuccess;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);

      // TODO: Implement Google Sign-In with AWS Cognito or similar
      // For now, return false
      _setError('Google Sign-In not yet implemented');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);

      final result = await _httpClient.register(
        email: email,
        password: password,
        name: name,
        role: role.name,
      );

      if (result.isSuccess && result.data != null) {
        final userData = result.data!;
        _user = User(
          id: userData['user']['id'],
          email: userData['user']['email'],
          name: userData['user']['name'],
        );

        _userRole = role;

        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_role', _userRole!.name);

        // Set auth token in HTTP client
        _httpClient.setAuthToken(userData['token']);

        _error = null;
      } else {
        _error = result.error ?? 'Sign up failed';
      }

      _setLoading(false);
      return result.isSuccess;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_role');

      _user = null;
      _userRole = null;
      _error = null;

      // Clear auth token
      _httpClient.clearAuthToken();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> updateUserRole(UserRole newRole) async {
    try {
      _userRole = newRole;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', newRole.name);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}

class User {
  final String id;
  final String email;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });
}
