import 'package:app/presentation/constants/app_colors.dart';
import 'package:flutter/material.dart';

enum ButtonType { mainLogin, secondaryLogin, mainSystem, secondarySystem, link }

class CustomButton extends StatefulWidget {
  final ButtonType type;
  final String buttonText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;

  const CustomButton({
    super.key,
    required this.buttonText,
    this.type = ButtonType.mainLogin,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    switch (widget.type) {
      case ButtonType.mainLogin:
        backgroundColor = Colors.white;
        borderColor = Colors.transparent;
        textColor = AppColors.buttonTextColor;
      case ButtonType.secondaryLogin:
        backgroundColor = Colors.transparent;
        borderColor = Colors.white;
        textColor = Colors.white;
      case ButtonType.mainSystem:
        backgroundColor = const Color(0xFFB01030);
        borderColor = Colors.transparent;
        textColor = Colors.white;
      case ButtonType.secondarySystem:
        backgroundColor = Colors.transparent;
        borderColor = const Color(0xFFB01030);
        textColor = const Color(0xFFB01030);
      case ButtonType.link:
        backgroundColor = Colors.transparent;
        borderColor = Colors.transparent;
        textColor = const Color(0xFFB01030);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(250),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.prefixIcon != null) ...[
                widget.prefixIcon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.buttonText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.suffixIcon != null) ...[
                const SizedBox(width: 8),
                widget.suffixIcon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
