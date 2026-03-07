import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:privacy_screen/privacy_screen.dart';

class PrivacyShield {
  static Future<bool> authenticate(BuildContext context) async {
    final auth = LocalAuthentication();
    final available = await auth.canCheckBiometrics;
    if (!available) return true;
    try {
      final didAuth = await auth.authenticate(
        localizedReason: 'Please authenticate to access Bloom',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      return didAuth;
    } catch (_) {
      return false;
    }
  }

  static void enablePrivacyScreen() {
    // PrivacyScreen().enable(); // Disabled for web compatibility
  }

  static void disablePrivacyScreen() {
    // PrivacyScreen().disable(); // Disabled for web compatibility
  }
}
