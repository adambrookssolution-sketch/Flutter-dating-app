import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/datasource/tags_datasource.dart';
import 'package:app/data/models/place_result.dart';
import 'package:app/data/models/tag.dart';
import 'package:app/presentation/widgets/places_autocomplete_field.dart';
import 'package:app/providers/filters_provider.dart';

/// Filters panel — matches the client's design mockup:
///   • Country / City fields (Places autocomplete)
///   • Age range slider (21–99; 21 hard floor because app is 21+)
///   • Dynamics chips           — strict match (any overlap passes)
///   • Experience Preferences   — strict match
///   • Interests                — 50% threshold (configurable)
///   • "Apply filters" returns user to the feed
///
/// Written on Riverpod — first screen to use the new state container. See
/// PROJECT_OVERVIEW §5 for the progressive-adoption policy.
class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  static const double _minAge = 21; // hard floor per client rule
  static const double _maxAge = 99;

  RangeValues _ageRange = const RangeValues(_minAge, 65);
  bool _ageRangeInitialised = false;

  List<Tag>? _dynamicTags;
  List<Tag>? _experienceTags;
  List<Tag>? _interestTags;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final results = await Future.wait([
      TagsDatasource.getByCategory(TagCategory.dynamics),
      TagsDatasource.getByCategory(TagCategory.experience),
      TagsDatasource.getByCategory(TagCategory.interests),
    ]);
    if (!mounted) return;
    setState(() {
      _dynamicTags = results[0];
      _experienceTags = results[1];
      _interestTags = results[2];
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(filtersProvider);
    final notifier = ref.read(filtersProvider.notifier);

    // One-shot init of the slider UI from persisted state
    if (!_ageRangeInitialised &&
        (filters.minAge != null || filters.maxAge != null)) {
      _ageRange = RangeValues(
        filters.minAge?.toDouble() ?? _minAge,
        filters.maxAge?.toDouble() ?? 65.0,
      );
      _ageRangeInitialised = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Filters'),
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
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFB31637))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          PlacesAutocompleteField(
            label: 'Location',
            hintText: 'City, country',
            initialValue: filters.city == null
                ? null
                : PlaceResult(
                    city: filters.city ?? '',
                    country: filters.country ?? '',
                    countryCode: '',
                    lat: filters.centerLat ?? 0,
                    lng: filters.centerLng ?? 0,
                  ),
            onSelected: (p) => notifier.setLocation(
              lat: p.lat,
              lng: p.lng,
              city: p.city,
              country: p.country,
            ),
          ),
          const SizedBox(height: 8),
          _sectionTitle('Age range'),
          RangeSlider(
            values: _ageRange,
            min: _minAge,
            max: _maxAge,
            divisions: (_maxAge - _minAge).toInt(),
            activeColor: const Color(0xFFB31637),
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (v) => setState(() => _ageRange = v),
            onChangeEnd: (v) {
              notifier.setAgeRange(
                v.start.round(),
                v.end.round(),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_ageRange.start.round()}',
                  style: const TextStyle(color: Color(0xFFA4A4AA))),
              Text('${_ageRange.end.round()}',
                  style: const TextStyle(color: Color(0xFFA4A4AA))),
            ],
          ),
          _sectionTitle('Dynamics'),
          _chipSection(
            tags: _dynamicTags,
            selected: filters.dynamics,
            onToggle: notifier.toggleDynamic,
          ),
          _sectionTitle('Experience preferences'),
          _chipSection(
            tags: _experienceTags,
            selected: filters.experiencePreferences,
            onToggle: notifier.toggleExperience,
          ),
          _sectionTitle('Interests'),
          _hintLine(
              'Matches when at least 50% of your selections overlap theirs.'),
          _chipSection(
            tags: _interestTags,
            selected: filters.interests,
            onToggle: notifier.toggleInterest,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB31637),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(250),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Apply filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
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

  Widget _chipSection({
    required List<Tag>? tags,
    required Set<String> selected,
    required void Function(String) onToggle,
  }) {
    if (tags == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((t) {
        final isSelected = selected.contains(t.name);
        return FilterChip(
          label: Text(t.name),
          selected: isSelected,
          onSelected: (_) => onToggle(t.name),
          selectedColor: const Color(0xFFB31637),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF555555),
          ),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFB31637)
                : const Color(0xFFA4A4AA),
          ),
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }
}
