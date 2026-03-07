import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import local_auth with platform guard
import 'package:local_auth/local_auth.dart' as local_auth;

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _secureStorage = const FlutterSecureStorage();

  static const _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isBiometricAvailable() async {
    // Biometrics not available on web
    if (kIsWeb) return false;
    try {
      final auth = local_auth.LocalAuthentication();
      return await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (e) {
      if (kDebugMode) print('Biometric check failed: $e');
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Please authenticate to unlock Bloom'}) async {
    // On web, automatically "unlock"
    if (kIsWeb) return true;
    try {
      final auth = local_auth.LocalAuthentication();
      final didAuthenticate = await auth.authenticate(
        localizedReason: reason,
        options: const local_auth.AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      if (kDebugMode) print('Authentication error: $e');
      // If local_auth fails, allow access
      return true;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled ? '1' : '0');
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _secureStorage.read(key: _biometricEnabledKey);
    return v == '1';
  }

  Future<void> clearAllAppData() async {
    // Clear secure storage
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}

    // Clear shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }
}
