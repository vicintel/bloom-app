import 'package:flutter/material.dart';

class OnboardScreen extends StatelessWidget {
  final OnboardData data;
  const OnboardScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.image, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.desc,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardData {
  final String title, desc;
  final IconData image;
  const OnboardData({required this.title, required this.desc, required this.image});
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingPage({super.key, required this.onFinish});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<OnboardData> _pages = [
    const OnboardData(
      title: 'Welcome to Bloom',
      desc: 'Track your cycle, moods, and wellness with ease.',
      image: Icons.spa,
    ),
    const OnboardData(
      title: 'Personal Insights',
      desc: 'Get AI-powered advice and daily check-ins.',
      image: Icons.insights,
    ),
    const OnboardData(
      title: 'Stay Secure',
      desc: 'Your data is private and protected.',
      image: Icons.lock_outline,
    ),
  ];

  int _page = 0;
  final PageController _controller = PageController();

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      widget.onFinish();
    }
  }

  void _back() {
    if (_page > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => Semantics(
                  label: _pages[i].title,
                  child: OnboardScreen(data: _pages[i]),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                width: _page == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Back',
                      child: ElevatedButton(
                        onPressed: _page == 0 ? null : _back,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: _page == _pages.length - 1 ? 'Get Started' : 'Next',
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(_page == _pages.length - 1 ? 'Get Started' : 'Next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


