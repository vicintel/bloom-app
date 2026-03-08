import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/checkin_page.dart';
import 'pages/security_settings.dart';
import 'pages/signup_page.dart';
import 'pages/profile_page.dart';
import 'pages/nutrition_page.dart';
import 'pages/fitness_page.dart';
import 'pages/history_page.dart';
import 'pages/insights_page.dart';
import 'pages/ovulation_tracker_page.dart';
import 'pages/messages_page.dart';


class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _routes = ['/dashboard', '/checkin', '/insights', '/profile'];

  int _locationToIndex(String location) {
    if (location.startsWith('/checkin')) return 1;
    if (location.startsWith('/insights')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Check-in',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
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
    GoRoute(
      path: '/nutrition',
      builder: (context, state) => const NutritionPage(),
    ),
    GoRoute(
      path: '/fitness',
      builder: (context, state) => const FitnessPage(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/security',
      builder: (context, state) => const SecuritySettingsPage(),
    ),
    GoRoute(
      path: '/ovulation',
      builder: (context, state) => const OvulationTrackerPage(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesPage(),
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
          path: '/insights',
          builder: (context, state) => const InsightsPage(),
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
