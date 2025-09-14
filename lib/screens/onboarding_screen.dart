import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const route = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController(viewportFraction: 0.86);
  int _page = 0;

  final _pages = const [
    _ObPage(
      assetBase: 'assets/book',           // book.svg (or .png)
      title: 'Book',
      description: 'Book snow removal for your driveway, sidewalk, or roof',
      tint: Color(0xFFE6F0FF),
    ),
    _ObPage(
      assetBase: 'assets/tracking',          // track.svg (or .png)
      title: 'Track',
      description: 'Live updates from your SnowGo provider',
      tint: Color(0xFFEFF7FF),
    )
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Top logo + wordmark (full-color like the mock)
            Column(
              children: [
                Image.asset('assets/logo.png', height: 64, fit: BoxFit.contain),
                const SizedBox(height: 8),
                const Text('SnowGo',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: blue)),
              ],
            ),
            const SizedBox(height: 16),

            // Pager with peeking next card (like the mock)
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (ctx, i) => _OnboardCard(page: _pages[i]),
              ),
            ),

            // Dots
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 10 : 6,
                  height: active ? 10 : 6,
                  decoration: BoxDecoration(
                    color: active ? blue : const Color(0xFFD7DEEA),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            // Primary CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _next,
                  child: const Text('Next',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardCard extends StatelessWidget {
  final _ObPage page;
  const _OnboardCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        // Card that matches the mock: rounded, white, soft border, colored top half
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Top illustration area
            Expanded(
              flex: 5,
              child: Container(
                color: page.tint,
                alignment: Alignment.center,
                child: _SmartAsset(assetBase: page.assetBase, height: 120),
              ),
            ),
            // Bottom text area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(page.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black)),
                    const SizedBox(height: 8),
                    Text(page.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.35)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObPage {
  final String assetBase; // 'assets/illustrations/book'
  final String title;
  final String description;
  final Color tint;
  const _ObPage({required this.assetBase, required this.title, required this.description, required this.tint});
}

/// Tries to load SVG first; if not found, falls back to PNG.
class _SmartAsset extends StatelessWidget {
  final String assetBase;
  final double height;
  const _SmartAsset({required this.assetBase, required this.height});

  @override
  Widget build(BuildContext context) {
    final svgPath = '$assetBase.svg';
    final pngPath = '$assetBase.png';

    return FutureBuilder<bool>(
      future: _assetExists(context, svgPath),
      builder: (ctx, snap) {
        final useSvg = snap.data == true;
        if (useSvg) {
          return SvgPicture.asset(svgPath, height: height);
        } else {
          return Image.asset(pngPath, height: height, fit: BoxFit.contain);
        }
      },
    );
  }

  // Simple asset existence check (works for bundled assets).
  Future<bool> _assetExists(BuildContext context, String asset) async {
    try {
      await DefaultAssetBundle.of(context).load(asset);
      return true;
    } catch (_) {
      return false;
    }
  }
}
