import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'job_form_screen.dart';
import 'jobs_list_screen.dart';

class HomeScreen extends StatelessWidget {
  static const route = '/';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Logo + wordmark
            Column(
              children: [
                Image.asset('assets/logo.png',
                    height: 100, fit: BoxFit.contain),
                const SizedBox(height: 8)]//,
              //   const Text('SnowGo',
              //       style: TextStyle(
              //           fontSize: 32,
              //           fontWeight: FontWeight.w800,
              //           color: blue)),
              // ],
            ),
            const SizedBox(height: 24),

            // Main cards
            Expanded(
              child: PageView(
                controller: PageController(viewportFraction: 0.8),
                children: const [
                  _FeatureCard(
                    asset: 'assets/book.svg',
                    title: 'Book',
                    description:
                    'Book snow removal for your driveway, sidewalk, or roof',
                    route: JobFormScreen.route,
                  ),
                  _FeatureCard(
                    asset: 'assets/track.svg',
                    title: 'Track',
                    description: 'See all your active and past jobs',
                    route: JobsListScreen.route,
                  )
                ],
              ),
            )

            // Bottom CTA button (optional, can remove)
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            //   child: SizedBox(
            //     width: double.infinity,
            //     height: 56,
            //     child: ElevatedButton(
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: blue,
            //         shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(14)),
            //       ),
            //       onPressed: () =>
            //           Navigator.pushNamed(context, JobFormScreen.route),
            //       child: const Text('Next',
            //           style: TextStyle(
            //               fontSize: 18,
            //               fontWeight: FontWeight.w800,
            //               color: Colors.white)),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String asset;
  final String title;
  final String description;
  final String? route;

  const _FeatureCard(
      {required this.asset,
        required this.title,
        required this.description,
        this.route});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: InkWell(
        onTap: route == null ? null : () => Navigator.pushNamed(context, route!),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  color: const Color(0xFFE6F0FF),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(asset, height: 120),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.35)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
