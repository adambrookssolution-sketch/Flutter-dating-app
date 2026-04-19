import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_colors.dart';
import 'package:app/presentation/widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _logoAlignment;
  late Animation<double> _logoSize;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoAlignment = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(0, -0.38),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _logoSize = Tween<double>(begin: 1.0, end: 0.78).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Align(
                alignment: _logoAlignment.value,
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: width * 0.45 * _logoSize.value,
                ),
              ),
            ),
            SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _contentOpacity,
                child: Align(
                  alignment: const Alignment(0, 0.6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomButton(buttonText: l10n.signIn),
                        const SizedBox(height: 13),
                        CustomButton(
                          buttonText: l10n.signUp,
                          type: ButtonType.secondaryLogin,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Text(
                            l10n.signInAccounts,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        CustomButton(
                          buttonText: l10n.signInWithGoogle,
                          prefixIcon: SvgPicture.asset(
                            'assets/images/google.svg',
                            height: 18,
                          ),
                        ),
                        const SizedBox(height: 13),
                        CustomButton(
                          buttonText: l10n.signInWithApple,
                          prefixIcon: SvgPicture.asset(
                            'assets/images/apple.svg',
                            height: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
