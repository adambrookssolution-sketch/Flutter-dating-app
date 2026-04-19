import 'package:flutter/material.dart';

class SelectOption<T> {
  final T value;
  final String label;

  const SelectOption({required this.value, required this.label});
}

class CustomSelect<T> extends StatefulWidget {
  final String? label;
  final String? hintText;
  final double marginBottom;
  final List<SelectOption<T>> options;
  final T? value;
  final void Function(T)? onChanged;
  final String? errorText;

  const CustomSelect({
    super.key,
    this.label,
    this.hintText,
    this.marginBottom = 13.0,
    required this.options,
    this.value,
    this.onChanged,
    this.errorText,
  });

  @override
  State<CustomSelect<T>> createState() => _CustomSelectState<T>();
}

class _CustomSelectState<T> extends State<CustomSelect<T>> {
  T? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  void didUpdateWidget(CustomSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selected = widget.value;
    }
  }

  String? get _selectedLabel => widget.options
      .where((o) => o.value == _selected)
      .map((o) => o.label)
      .firstOrNull;

  Future<void> _openSheet() async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFA4A4AA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final option = widget.options[i];
                final isSelected = option.value == _selected;
                return ListTile(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected
                          ? const Color(0xFFB31637)
                          : const Color(0xFF333333),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFFB31637))
                      : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: SizedBox(height: 8),
          ),
        ],
      ),
    );

    if (picked != null) {
      setState(() => _selected = picked);
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _selectedLabel != null;

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
        GestureDetector(
          onTap: _openSheet,
          child: Container(
            margin: EdgeInsets.only(top: 2, bottom: widget.errorText != null ? 4 : widget.marginBottom),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: widget.errorText != null ? Colors.red : const Color(0xFFA4A4AA),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? _selectedLabel! : (widget.hintText ?? 'Select'),
                    style: TextStyle(
                      fontSize: 14,
                      color: hasValue
                          ? const Color(0xFF333333)
                          : const Color(0xFFA4A4AA),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFA4A4AA),
                ),
              ],
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
