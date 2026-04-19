import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/constants/app_colors.dart';
import 'package:app/presentation/constants/app_dimensions.dart';
import 'package:flutter_svg/svg.dart';
import 'sign_in_form.dart';
import 'sign_up_form.dart';

class AuthByEmailScreen extends StatefulWidget {
  final bool initialIsSignIn;

  const AuthByEmailScreen({super.key, this.initialIsSignIn = true});

  @override
  State<AuthByEmailScreen> createState() => _AuthByEmailScreenState();
}

class _AuthByEmailScreenState extends State<AuthByEmailScreen>
    with SingleTickerProviderStateMixin {
  late bool isSignIn;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    isSignIn = widget.initialIsSignIn;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.initialIsSignIn ? 0.0 : 1.0,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSwitch(bool newValue) {
    setState(() {
      isSignIn = newValue;
    });
    if (newValue) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(
                  AppDimensions.containerBorderRadius,
                ),
                bottomRight: Radius.circular(
                  AppDimensions.containerBorderRadius,
                ),
              ),
            ),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26.0, bottom: 36.0),
                    child: Center(
                      child: Hero(
                        tag: 'app_logo',
                        child: SvgPicture.asset('assets/images/logo_white.svg'),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Container(
                    height: AppDimensions.switchButtonHeight,
                    decoration: BoxDecoration(
                      color: AppColors.switchButtonBackground,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.switchButtonRadius,
                      ),
                    ),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _slideAnimation,
                          builder: (context, child) {
                            return AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              left: isSignIn
                                  ? AppDimensions.switchButtonMargin
                                  : (MediaQuery.of(context).size.width - 80) /
                                            2 -
                                        AppDimensions.switchButtonMargin,
                              top: AppDimensions.switchButtonMargin,
                              right: isSignIn
                                  ? (MediaQuery.of(context).size.width - 80) /
                                            2 -
                                        AppDimensions.switchButtonMargin
                                  : AppDimensions.switchButtonMargin,
                              bottom: AppDimensions.switchButtonMargin,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.switchButtonSelected,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.switchSelectorRadius,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleSwitch(true),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      style: TextStyle(
                                        color: isSignIn
                                            ? AppColors.switchButtonTextSelected
                                            : AppColors
                                                  .switchButtonTextUnselected,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      child: Text(l10n.signIn),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleSwitch(false),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      style: TextStyle(
                                        color: !isSignIn
                                            ? AppColors.switchButtonTextSelected
                                            : AppColors
                                                  .switchButtonTextUnselected,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      child: Text(l10n.signUp),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Form content area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).padding.bottom;
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppDimensions.systemMargin,
                    right: AppDimensions.systemMargin,
                    top: AppDimensions.systemMargin,
                    bottom: AppDimensions.systemMargin + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          AppDimensions.systemMargin * 2 -
                          bottomInset,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                      child: isSignIn
                          ? SignInForm(
                              key: const ValueKey('sign_in'),
                              onSignUpTap: () => _toggleSwitch(false),
                            )
                          : SignUpForm(
                              key: ValueKey('sign_up'),
                              onSignInTap: () => _toggleSwitch(true),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
