import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_router.dart';
import 'pages/locked_page.dart';
import 'pages/onboarding_page.dart';
import 'services/notification_service.dart';
import 'state/cycle_state.dart';
import 'state/theme_notifier.dart';
import 'widgets/privacy_shield.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PrivacyShield.enablePrivacyScreen();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CycleState()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const RootApp(),
    ),
  );
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _unlocked = false;
  bool _onboarded = false;
  bool _authChecked = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    NotificationService.init(context);
    if (kIsWeb) {
      setState(() {
        _unlocked = true;
        _authChecked = true;
      });
    } else {
      _checkBiometric();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboarded = prefs.getBool('onboarded') ?? false;
      _prefsLoaded = true;
    });
  }

  Future<void> _checkBiometric() async {
    final ok = await PrivacyShield.authenticate(context);
    setState(() {
      _unlocked = ok;
      _authChecked = true;
    });
  }

  void _onUnlocked() {
    setState(() => _unlocked = true);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    setState(() => _onboarded = true);
    await NotificationService.scheduleDailyReminder(
      hour: 8,
      minute: 0,
      title: 'Daily Check-in',
      body: "Don't forget to check in with Bloom today!",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        final lightScheme = ColorScheme.fromSeed(
          seedColor: themeNotifier.seedColor,
          brightness: Brightness.light,
        );
        final darkScheme = ColorScheme.fromSeed(
          seedColor: themeNotifier.seedColor,
          brightness: Brightness.dark,
        );

        const pageTransitions = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        );

        final theme = ThemeData(
          useMaterial3: true,
          colorScheme: lightScheme,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
          pageTransitionsTheme: pageTransitions,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );
        final darkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: darkScheme,
          textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme),
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
          pageTransitionsTheme: pageTransitions,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );

        if (!_authChecked || !_prefsLoaded) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (!_onboarded) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: OnboardingPage(onFinish: _completeOnboarding),
          );
        }

        if (!_unlocked) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: LockedPage(onUnlocked: _onUnlocked),
          );
        }

        return MaterialApp.router(
          title: 'Bloom',
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
