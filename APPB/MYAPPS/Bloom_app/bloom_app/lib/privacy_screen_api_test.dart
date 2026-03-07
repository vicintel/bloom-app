// Quick test for privacy_screen API
import 'package:privacy_screen/privacy_screen.dart';

void main() {
  // Try to call enable/disable as static
  PrivacyScreen.enable();
  PrivacyScreen.disable();
  // Try to call as instance
  PrivacyScreen().enable();
  PrivacyScreen().disable();
}
