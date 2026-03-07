import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/checkin_page.dart';
import 'pages/security_settings.dart';
import 'pages/signup_page.dart';
import 'pages/profile_page.dart';
import 'state/theme_notifier.dart';
import 'widgets/theme_settings_sheet.dart';
import 'package:flutter/material.dart';


class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _routes = ['/dashboard', '/checkin', '/security', '/profile'];

  int _locationToIndex(String location) {
    if (location.startsWith('/checkin')) return 1;
    if (location.startsWith('/security')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _openThemeSettings(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ThemeSettingsSheet(
        isDarkMode: themeNotifier.isDarkMode,
        seedColor: themeNotifier.seedColor,
        onThemeModeChanged: (val) => themeNotifier.setDarkMode(val),
        onSeedColorChanged: (color) => themeNotifier.setSeedColor(color),
      ),
      showDragHandle: true,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          if (currentIndex != idx) {
            GoRouter.of(context).go(_routes[idx]);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Check-in',
          ),
          const NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Security',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: 'Profile',
            // theme shortcut on long-press via GestureDetector wrapping is
            // not possible on NavigationDestination; put it in profile page.
            // Expose it via an icon in the profile app bar instead.
          ),
        ],
      ),
    );
  }
}

final appRouter = GoRouter(
  redirect: (context, state) {
    final auth = AuthService();
    final isLoggedIn = auth.isLoggedIn;
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSignup = state.matchedLocation == '/signup';

    if (!isLoggedIn && !isGoingToLogin && !isGoingToSignup) {
      return '/login';
    }

    if (isLoggedIn && (isGoingToLogin || isGoingToSignup)) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/checkin',
          builder: (context, state) => const CheckinPage(),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const SecuritySettingsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
  initialLocation: '/login',
);
