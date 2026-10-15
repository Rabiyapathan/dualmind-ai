
import 'package:flutter/material.dart';

void main() {
  runApp(const DualMindApp());
}

class AppColors {
  static const ivory = Color(0xFFFBF8F5);
  static const lavender = Color(0xFFE6DDF7);
  static const lavenderBright = Color(0xFFB49AE8);
  static const purple = Color(0xFF54277D);
  static const purpleDark = Color(0xFF352044);
  static const brown = Color(0xFFC8A486);
  static const brownLight = Color(0xFFF0E1D2);
  static const maroon = Color(0xFF651B32);
  static const text = Color(0xFF342A38);
  static const muted = Color(0xFF897C8C);
  static const white = Colors.white;
}

class DualMindApp extends StatelessWidget {
  const DualMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DualMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.ivory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          primary: AppColors.maroon,
          secondary: AppColors.lavenderBright,
          surface: AppColors.ivory,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.ivory,
          foregroundColor: AppColors.purpleDark,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            _BrandIcon(),
            SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DualMind AI',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  'YOUR PERSONAL KNOWLEDGE SPACE',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: IconButton(
              onPressed: () {},
              tooltip: 'Settings',
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          children: [
            const _WelcomeCard(),
            const SizedBox(height: 27),
            const Text(
              'Your knowledge, connected.',
              style: TextStyle(
                fontSize: 25,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
                color: AppColors.purpleDark,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Upload your documents, ask questions, and discover '
              'answers grounded in your own material.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            _ActionCard(
              icon: Icons.upload_file_rounded,
              iconColor: AppColors.maroon,
              iconBackground: const Color(0xFFF5E4E9),
              title: 'Upload a document',
              description: 'Add a PDF to your knowledge space.',
              buttonText: 'Choose PDF',
              onTap: () {
                _showComingSoon(context, 'PDF upload');
              },
            ),
            const SizedBox(height: 15),
            _ActionCard(
              icon: Icons.forum_rounded,
              iconColor: AppColors.purple,
              iconBackground: AppColors.lavender,
              title: 'Ask DualMind',
              description: 'Explore your documents with AI answers.',
              buttonText: 'Start asking',
              onTap: () {
                _showComingSoon(context, 'AI chat');
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.brown.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.purple,
                    size: 23,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answers with sources',
                          style: TextStyle(
                            color: AppColors.purpleDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Find relevant passages and see which PDF '
                          'pages support your answer.',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'MADE FOR YOUR CURIOSITY',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.purpleDark],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.psychology_alt_rounded,
        color: AppColors.white,
        size: 27,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.purpleDark],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -5,
            top: 0,
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.lavenderBright,
              size: 63,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'YOUR AI COMPANION',
                  style: TextStyle(
                    color: AppColors.lavender,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Think deeper.\nDiscover more.',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 29,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your documents meet the power of AI.',
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE3ED)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDark.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purpleDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature is the next step we will connect!'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.purpleDark,
    ),
  );
}
