import 'package:app/presentation/constants/app_dimensions.dart';
import 'package:app/presentation/pages/forgot_password/step_code.dart';
import 'package:app/presentation/pages/forgot_password/step_success.dart';
import 'package:app/presentation/pages/forgot_password/step_verify.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0;
  String _email = '';

  static const List<String> _stepImages = [
    'assets/images/forgot_password_image.png',
    'assets/images/forgot_password_code.png',
    'assets/images/forgot_password_success.png',
  ];

  void _goToStep(int step, {String? email}) {
    setState(() {
      _currentStep = step;
      if (email != null) _email = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget stepWidget = switch (_currentStep) {
      0 => StepVerify(onNext: (email) => _goToStep(1, email: email)),
      1 => StepCode(
          email: _email,
          onNext: () => _goToStep(2),
        ),
      _ => const StepSuccess(),
    };

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.systemMargin),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 55.0),
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, .5],
                    colors: [Colors.transparent, Colors.white],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    _stepImages[_currentStep],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              stepWidget,
            ],
          ),
        ),
      ),
    );
  }
}
