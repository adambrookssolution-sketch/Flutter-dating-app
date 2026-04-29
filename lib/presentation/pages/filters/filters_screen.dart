import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/interests/interest_groups.dart';
import 'package:app/data/datasource/destinations_datasource.dart';
import 'package:app/data/models/destination.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/providers/filters_provider.dart';

/// Filters panel — matches the client's design mockup with the
/// 2026-04-23 updates applied:
///   • Distance slider (km) — geolocation-based, no country/city
///   • Age range slider (21–99; 21 hard floor because app is 21+)
///   • Dynamics chips           — strict match (any overlap passes)
///   • Experience Preferences   — strict match
///   • Interests                — 50% threshold (configurable)
///   • Travel Match section     — inline in the panel
///   • "Apply filters" returns user to the feed
///
/// Written on Riverpod — first screen to use the new state container. See
/// PROJECT_OVERVIEW §5 for the progressive-adoption policy.
class FiltersScreen extends ConsumerStatefulWidget {
  /// When hosted inside a DraggableScrollableSheet the parent passes its
  /// controller so the inner [ListView] shares the drag-to-expand gesture.
  /// When opened as a full page (legacy), leave null.
  final ScrollController? scrollController;

  const FiltersScreen({super.key, this.scrollController});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  static const double _minAge = 21; // hard floor per client rule
  static const double _maxAge = 99;

  RangeValues _ageRange = const RangeValues(_minAge, 65);
  bool _ageRangeInitialised = false;

  List<Destination>? _destinations;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final list = await DestinationsDatasource.getAll();
    if (!mounted) return;
    setState(() => _destinations = list);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(filtersProvider);
    final notifier = ref.read(filtersProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    // One-shot init of the slider UI from persisted state
    if (!_ageRangeInitialised &&
        (filters.minAge != null || filters.maxAge != null)) {
      _ageRange = RangeValues(
        filters.minAge?.toDouble() ?? _minAge,
        filters.maxAge?.toDouble() ?? 65.0,
      );
      _ageRangeInitialised = true;
    }

    final isSheet = widget.scrollController != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decorative top: matches the reference mock — a small burgundy
        // handle on the left side of the sheet header plus a centred
        // "Filters" title. Only rendered in bottom-sheet mode so the
        // legacy full-page flow keeps its AppBar.
        if (isSheet)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEDEDED)),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB01030).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 48), // balance Reset button width
                    Expanded(
                      child: Center(
                        child: Text(
                          l10n.filtersTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        notifier.reset();
                        setState(() {
                          _ageRange = const RangeValues(_minAge, 65);
                          _ageRangeInitialised = false;
                        });
                      },
                      child: Text(l10n.filtersReset,
                          style: const TextStyle(color: Color(0xFFB01030))),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          AppBar(
            title: Text(l10n.filtersTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: () {
                  notifier.reset();
                  setState(() {
                    _ageRange = const RangeValues(_minAge, 65);
                    _ageRangeInitialised = false;
                  });
                },
                child: Text(l10n.filtersReset,
                    style: const TextStyle(color: Color(0xFFB01030))),
              ),
            ],
          ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
          // Distance slider (2026-04-23 update) — country/city fields were
          // removed in favour of pure geolocation by radius. The centre is
          // the user's current device location (resolved by the feed
          // screen before opening the filters sheet); here we only expose
          // the radius knob.
          _sectionTitle('Distance'),
          _DistanceSlider(
            valueKm: filters.radiusKm,
            onChanged: (v) => notifier.setRadiusKm(v),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filtersDistanceMin5km,
                  style: const TextStyle(color: Color(0xFFA4A4AA))),
              Text('${filters.radiusKm.round()} km',
                  style: const TextStyle(
                      color: Color(0xFFB01030),
                      fontWeight: FontWeight.w600)),
            ],
          ),
          _sectionTitle('Age'),
          // Red→purple gradient track (2026-04-20 mock). The gradient is
          // rendered as a solid background, then the RangeSlider is laid
          // on top with a transparent active colour so only the thumbs
          // and value labels from the material widget show through.
          _GradientAgeSlider(
            range: _ageRange,
            min: _minAge,
            max: _maxAge,
            onChanged: (v) => setState(() => _ageRange = v),
            onChangeEnd: (v) {
              notifier.setAgeRange(v.start.round(), v.end.round());
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filtersAgeMin(_ageRange.start.round()),
                  style: const TextStyle(color: Color(0xFFA4A4AA))),
              Text(l10n.filtersAgeMax(_ageRange.end.round()),
                  style: const TextStyle(color: Color(0xFFA4A4AA))),
            ],
          ),
          // Three visual blocks, one shared `interests` set.
          _sectionTitle('Tipo de interacción'),
          _chipSection(
            chips: InterestGroups.tipoDeInteraccion,
            selected: filters.interests,
            onToggle: notifier.toggleInterest,
          ),
          _sectionTitle('Forma de experiencia'),
          _chipSection(
            chips: InterestGroups.formaDeExperiencia,
            selected: filters.interests,
            onToggle: notifier.toggleInterest,
          ),
          _sectionTitle('Intereses'),
          _chipSection(
            chips: InterestGroups.intereses,
            selected: filters.interests,
            onToggle: notifier.toggleInterest,
          ),
          const SizedBox(height: 22),

          _sectionTitle('Apertura de la pareja'),
          _hintLine(
              'Indiquen si están abiertos a interactuar individualmente con terceros.'),
          _OpennessToggle(
            label: 'Open to Unicorn',
            sublabel: 'ella',
            value: filters.openToUnicorn == true,
            onChanged: notifier.setOpenToUnicorn,
          ),
          const SizedBox(height: 8),
          _OpennessToggle(
            label: 'Open to Bull',
            sublabel: 'él',
            value: filters.openToBull == true,
            onChanged: notifier.setOpenToBull,
          ),
          const SizedBox(height: 16),
          // Travel Match block (client 2026-04-20 mock): lives inside the
          // filters panel so users can constrain the feed to couples who
          // have an overlapping trip in the same resort or cruise.
          _TravelMatchSection(
            destinations: _destinations,
            selectedDestinationId: filters.travelDestinationId,
            from: filters.travelFrom,
            to: filters.travelTo,
            onChanged: notifier.setTravelMatch,
            onClear: notifier.clearTravelMatch,
          ),
          const SizedBox(height: 100), // room for sticky Apply button
            ],
          ),
        ),
        // Apply Filters — red-to-purple gradient pill, pinned at the very
        // bottom of the sheet so it stays visible while the list scrolls.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () => Navigator.pop(context, true),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB01030), Color(0xFF5B1280)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Center(
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _hintLine(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
        ),
      );

  /// Renders a wrap of FilterChips for one of the three interest blocks.
  /// All three blocks share the same selected set + the same toggle
  /// handler — visual grouping is decided here, not in the data layer.
  Widget _chipSection({
    required List<String> chips,
    required Set<String> selected,
    required void Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((label) {
        final isSelected = selected.contains(label);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onToggle(label),
          selectedColor: const Color(0xFFB01030),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF555555),
          ),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFB01030)
                : const Color(0xFFA4A4AA),
          ),
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }
}

// ── Openness toggle ──────────────────────────────────────────────────────────

class _OpennessToggle extends StatelessWidget {
  const _OpennessToggle({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value
                ? const Color(0xFFB01030)
                : const Color(0xFFE6E6EA),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1B1F),
                    ),
                  ),
                  Text(
                    '($sublabel)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8A93),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFFB01030),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient age slider ──────────────────────────────────────────────────────

/// Range slider rendered over a red-to-purple gradient track, matching
/// the 2026-04-20 filters mock. The slider itself uses the standard
/// Material RangeSlider with a custom SliderTheme — thumbs, divisions,
/// and haptics all come for free.
class _GradientAgeSlider extends StatelessWidget {
  const _GradientAgeSlider({
    required this.range,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final RangeValues range;
  final double min;
  final double max;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gradient track background — inset by 16 px on each side to
          // approximately line up with the slider's own track padding.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB01030), Color(0xFF5B1280)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Transparent slider — visually contributes only the thumbs.
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              trackHeight: 10,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 2,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              rangeValueIndicatorShape:
                  const PaddleRangeSliderValueIndicatorShape(),
              valueIndicatorColor: const Color(0xFFB01030),
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: RangeSlider(
              values: range,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              labels: RangeLabels(
                range.start.round().toString(),
                range.end.round().toString(),
              ),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Distance slider ──────────────────────────────────────────────────────────

/// Single-value slider for the geolocation radius.
///
/// Client decision on 2026-04-23: location filtering is by kilometres
/// using the device's current location — no country/city dropdowns. The
/// minimum enforced by [FiltersState.minRadiusKm] is 5 km so rural users
/// never get an empty feed; the ceiling at 500 km covers
/// metropolitan-area travel without flipping into cross-country noise.
class _DistanceSlider extends StatelessWidget {
  const _DistanceSlider({
    required this.valueKm,
    required this.onChanged,
  });

  final double valueKm;
  final ValueChanged<double> onChanged;

  static const double _min = FiltersState.minRadiusKm;
  static const double _max = 500;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFFB01030),
        inactiveTrackColor: const Color(0xFFB01030).withValues(alpha: 0.2),
        thumbColor: const Color(0xFFB01030),
        overlayColor: const Color(0xFFB01030).withValues(alpha: 0.1),
        valueIndicatorColor: const Color(0xFFB01030),
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
      child: Slider(
        value: valueKm.clamp(_min, _max),
        min: _min,
        max: _max,
        divisions: ((_max - _min) / 5).round(),
        label: '${valueKm.round()} km',
        onChanged: onChanged,
      ),
    );
  }
}

// ── Travel Match section ─────────────────────────────────────────────────────

/// Resort / cruise picker + date range pickers, rendered inside the
/// filters screen per the client's 2026-04-20 mock. When all three fields
/// (destination + from + to) are set the discovery feed narrows to
/// couples whose trips overlap the selected window.
class _TravelMatchSection extends StatelessWidget {
  const _TravelMatchSection({
    required this.destinations,
    required this.selectedDestinationId,
    required this.from,
    required this.to,
    required this.onChanged,
    required this.onClear,
  });

  final List<Destination>? destinations;
  final String? selectedDestinationId;
  final DateTime? from;
  final DateTime? to;
  final void Function({
    String? destinationId,
    DateTime? from,
    DateTime? to,
  }) onChanged;
  final VoidCallback onClear;

  static const _burgundy = Color(0xFFB01030);

  @override
  Widget build(BuildContext context) {
    final isActive = selectedDestinationId != null || from != null || to != null;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _burgundy, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff_rounded,
                  color: _burgundy, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Travel Match',
                style: TextStyle(
                  color: _burgundy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isActive)
                InkWell(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child:
                        Icon(Icons.close_rounded, color: _burgundy, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _destinationDropdown(context),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _datePickerField(
                  context: context,
                  label: 'From',
                  value: from,
                  onPick: (picked) => onChanged(
                    destinationId: selectedDestinationId,
                    from: picked,
                    to: to,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _datePickerField(
                  context: context,
                  label: 'To',
                  value: to,
                  onPick: (picked) => onChanged(
                    destinationId: selectedDestinationId,
                    from: from,
                    to: picked,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _destinationDropdown(BuildContext context) {
    final items = destinations ?? const <Destination>[];
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      initialValue: selectedDestinationId,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      hint: Text(l10n.selectResortOrCruise),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(l10n.anyDestination),
        ),
        ...items.map(
          (d) => DropdownMenuItem<String>(value: d.id, child: Text(d.name)),
        ),
      ],
      onChanged: (id) => onChanged(
        destinationId: id,
        from: from,
        to: to,
      ),
    );
  }

  Widget _datePickerField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onPick,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          value == null
              ? ''
              : '${value.day.toString().padLeft(2, '0')}/'
                  '${value.month.toString().padLeft(2, '0')}/'
                  '${value.year}',
          style: TextStyle(
            color: value == null ? const Color(0xFFA4A4AA) : Colors.black,
          ),
        ),
      ),
    );
  }
}
