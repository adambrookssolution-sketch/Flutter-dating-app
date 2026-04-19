import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InputType { text, numeric, date, textarea }

enum DateInputFormat { ddmmyyyy, mmddyyyy }

class CustomInput extends StatefulWidget {
  final String? label;
  final String? hintText;
  final bool isObscure;
  final double marginBottom;
  final InputType type;
  final int rows;
  final DateInputFormat dateFormat;
  final TextEditingController? controller;
  final String? errorText;

  const CustomInput({
    super.key,
    this.label,
    this.hintText,
    this.isObscure = false,
    this.marginBottom = 13.0,
    this.type = InputType.text,
    this.rows = 4,
    this.dateFormat = DateInputFormat.ddmmyyyy,
    this.controller,
    this.errorText,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _obscureText;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isObscure;
    // Pre-populate the internal date controller when an existing value is provided.
    if (widget.type == InputType.date &&
        widget.controller?.text.isNotEmpty == true) {
      _dateController.text = widget.controller!.text;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return switch (widget.dateFormat) {
      DateInputFormat.ddmmyyyy => '$dd/$mm/$yyyy',
      DateInputFormat.mmddyyyy => '$mm/$dd/$yyyy',
    };
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted = _formatDate(picked);
      setState(() => _dateController.text = formatted);
      widget.controller?.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDate = widget.type == InputType.date;
    final isTextarea = widget.type == InputType.textarea;
    final isNumeric = widget.type == InputType.numeric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label ?? 'Label',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA4A4AA),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 2, bottom: widget.errorText != null ? 4 : widget.marginBottom),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.errorText != null ? Colors.red : const Color(0xFFA4A4AA),
            ),
          ),
          child: TextField(
            controller: isDate ? _dateController : widget.controller,
            obscureText: _obscureText,
            readOnly: isDate,
            onTap: isDate ? _pickDate : null,
            keyboardType: isNumeric
                ? TextInputType.number
                : isTextarea
                    ? TextInputType.multiline
                    : TextInputType.text,
            inputFormatters: isNumeric
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            maxLines: isTextarea ? widget.rows : 1,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: InputBorder.none,
              hintText: widget.hintText ?? (isDate
                  ? switch (widget.dateFormat) {
                      DateInputFormat.ddmmyyyy => 'DD/MM/YYYY',
                      DateInputFormat.mmddyyyy => 'MM/DD/YYYY',
                    }
                  : 'Enter text'),
              hintStyle: const TextStyle(
                color: Color(0xFFA4A4AA),
                fontSize: 14,
              ),
              suffixIcon: isDate
                  ? const Icon(Icons.calendar_today, color: Color(0xFFA4A4AA))
                  : widget.isObscure
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFFA4A4AA),
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        )
                      : null,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: widget.marginBottom),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
