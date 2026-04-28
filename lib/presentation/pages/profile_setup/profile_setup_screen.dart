import 'dart:io';

import 'package:app/core/interests/interest_groups.dart';
import 'package:app/data/datasource/auth_datasource.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/datasource/profile_datasource.dart';
import 'package:app/data/models/age_range.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/data/models/couple_status.dart';
import 'package:app/data/models/partner.dart';
import 'package:app/data/models/place_result.dart';
import 'package:app/data/models/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/auth/auth_screen.dart';
import 'package:app/presentation/pages/verification/verification_intro_screen.dart';
import 'package:app/presentation/widgets/custom_button.dart';
import 'package:app/presentation/widgets/custom_input.dart';
import 'package:app/presentation/widgets/places_autocomplete_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ── Photo item ────────────────────────────────────────────────────────────────

class _Photo {
  final String? url;
  final XFile? file;

  _Photo.fromUrl(String u) : url = u, file = null;
  _Photo.fromFile(XFile f) : file = f, url = null;

  bool get isLocal => file != null;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final UserProfile? existingProfile;

  const ProfileSetupScreen({super.key, required this.uid, this.existingProfile});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Text controllers
  final _herNameController = TextEditingController();
  final _hisNameController = TextEditingController();
  final _herBirthController = TextEditingController();
  final _hisBirthController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Height controllers
  final _herHeightCmController = TextEditingController();
  final _herFeetController = TextEditingController();
  final _herInchesController = TextEditingController();
  final _hisHeightCmController = TextEditingController();
  final _hisFeetController = TextEditingController();
  final _hisInchesController = TextEditingController();

  bool _herHeightIsCm = true;
  bool _hisHeightIsCm = true;

  String? _selectedCity;
  PlaceResult? _selectedPlace; // populated when chosen via Places Autocomplete
  List<_Photo> _photos = [];
  String? _photoError;

  // Single flat tag pool; visual blocks come from [InterestGroups].
  Set<String> _selectedTags = {};

  bool _openToUnicorn = false;
  bool _openToBull = false;

  bool _isLoading = false;

  Map<String, String?> _errors = {};

  bool get _isEditing => widget.existingProfile != null;

  String? _errorFor(String key) => _errors[key];

  @override
  void initState() {
    super.initState();
    if (_isEditing) _populate(widget.existingProfile!);
  }

  @override
  void dispose() {
    _herNameController.dispose();
    _hisNameController.dispose();
    _herBirthController.dispose();
    _hisBirthController.dispose();
    _descriptionController.dispose();
    _herHeightCmController.dispose();
    _herFeetController.dispose();
    _herInchesController.dispose();
    _hisHeightCmController.dispose();
    _hisFeetController.dispose();
    _hisInchesController.dispose();
    super.dispose();
  }

  // ── Interests ────────────────────────────────────────────────────────────────

  void _toggleInterest(String chip) {
    setState(() {
      if (_selectedTags.contains(chip)) {
        _selectedTags.remove(chip);
      } else {
        _selectedTags.add(chip);
      }
      if (_selectedTags.isNotEmpty) _errors['tags'] = null;
    });
  }

  Widget _buildInterestsSection() {
    final hasError = _errors['tags'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intereses de la pareja',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: hasError ? Colors.red : const Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Seleccionen los intereses que mejor los representan y cómo prefieren interactuar con otras parejas.',
          style: TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.4),
        ),
        const SizedBox(height: 14),
        Container(
          padding: hasError ? const EdgeInsets.all(8) : null,
          decoration: hasError
              ? BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _interestGroupBlock(
                title: 'Tipo de interacción',
                chips: InterestGroups.tipoDeInteraccion,
              ),
              const SizedBox(height: 14),
              _interestGroupBlock(
                title: 'Forma de experiencia',
                chips: InterestGroups.formaDeExperiencia,
              ),
              const SizedBox(height: 14),
              _interestGroupBlock(
                title: 'Intereses',
                chips: InterestGroups.intereses,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _interestGroupBlock({
    required String title,
    required List<String> chips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips
              .map(
                (chip) => _TagChip(
                  label: chip,
                  selected: _selectedTags.contains(chip),
                  onTap: () => _toggleInterest(chip),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildOpennessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apertura de la pareja',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Indiquen si están abiertos a interactuar individualmente con terceros.',
          style: TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.4),
        ),
        const SizedBox(height: 14),
        _opennessRow(
          label: 'Open to Unicorn',
          sublabel: 'ella',
          value: _openToUnicorn,
          onChanged: (v) => setState(() => _openToUnicorn = v),
        ),
        const SizedBox(height: 8),
        _opennessRow(
          label: 'Open to Bull',
          sublabel: 'él',
          value: _openToBull,
          onChanged: (v) => setState(() => _openToBull = v),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _opennessRow({
    required String label,
    required String sublabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value
                ? const Color(0xFFB31637)
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
              activeTrackColor: const Color(0xFFB31637),
            ),
          ],
        ),
      ),
    );
  }

  // ── Populate from existing profile ──────────────────────────────────────────

  void _populate(UserProfile p) {
    _herNameController.text = p.herName;
    _hisNameController.text = p.hisName;
    _herBirthController.text = p.herBirth;
    _hisBirthController.text = p.hisBirth;
    _selectedCity = p.city.isEmpty ? null : p.city;
    if (p.city.isNotEmpty) {
      // Display-only fallback: legacy profiles only stored a city string,
      // so country / lat / lng / geohash will stay empty until the user
      // re-edits via the new Places-backed picker.
      _selectedPlace = PlaceResult(
        city: p.city,
        country: '',
        countryCode: '',
        lat: 0,
        lng: 0,
      );
    }
    _descriptionController.text = p.description;
    _photos = p.photos.map(_Photo.fromUrl).toList();
    _selectedTags = p.interests.isNotEmpty
        ? p.interests.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet()
        : {};
    // Openness flags live on the couple doc, not on UserProfile.
    _loadOpennessFromCouple();
    _parseHeight(
      p.herHeight,
      cmCtrl: _herHeightCmController,
      feetCtrl: _herFeetController,
      inchesCtrl: _herInchesController,
      setIsCm: (v) => _herHeightIsCm = v,
    );
    _parseHeight(
      p.hisHeight,
      cmCtrl: _hisHeightCmController,
      feetCtrl: _hisFeetController,
      inchesCtrl: _hisInchesController,
      setIsCm: (v) => _hisHeightIsCm = v,
    );
  }

  Future<void> _loadOpennessFromCouple() async {
    try {
      final couple = await CouplesDatasource.getCouple(widget.uid);
      if (!mounted || couple == null) return;
      setState(() {
        _openToUnicorn = couple.openToUnicorn;
        _openToBull = couple.openToBull;
      });
    } catch (_) {
      // Defaults stay false; user can re-toggle.
    }
  }

  void _parseHeight(
    String h, {
    required TextEditingController cmCtrl,
    required TextEditingController feetCtrl,
    required TextEditingController inchesCtrl,
    required void Function(bool) setIsCm,
  }) {
    if (h.contains('cm')) {
      setIsCm(true);
      cmCtrl.text = h.replaceAll('cm', '').trim();
    } else if (h.contains("'")) {
      setIsCm(false);
      final m = RegExp(r"(\d+)'(\d*)").firstMatch(h);
      if (m != null) {
        feetCtrl.text = m.group(1) ?? '';
        inchesCtrl.text = m.group(2) ?? '';
      }
    }
  }

  // ── Photos ───────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() {
      if (_photos.length < 6) {
        _photos.add(_Photo.fromFile(file));
        _photoError = null;
      }
    });
  }

  void _swapPhotos(int from, int to) {
    if (from == to) return;
    setState(() {
      final tmp = _photos[from];
      _photos[from] = _photos[to];
      _photos[to] = tmp;
    });
  }

  Widget _photoImage(_Photo p) => p.isLocal
      ? Image.file(File(p.file!.path), fit: BoxFit.cover)
      : Image.network(p.url!, fit: BoxFit.cover);

  Widget _emptySlot({bool isAdd = false, bool isDragTarget = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDragTarget ? const Color(0xFFB31637) : const Color(0xFFDDDDDD),
          width: isDragTarget ? 2 : 1,
        ),
        color: isDragTarget
            ? const Color(0xFFB31637).withValues(alpha: 0.06)
            : const Color(0xFFF5F5F5),
      ),
      child: isAdd
          ? const Center(
              child: Icon(Icons.add_photo_alternate_outlined,
                  color: Color(0xFFB31637), size: 30),
            )
          : null,
    );
  }

  Widget _buildPhotoCell(int index) {
    final hasPhoto = index < _photos.length;
    final isAddSlot = !hasPhoto && index == _photos.length && _photos.length < 6;

    if (!hasPhoto) {
      return isAddSlot
          ? GestureDetector(onTap: _pickPhoto, child: _emptySlot(isAdd: true))
          : _emptySlot();
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => _swapPhotos(d.data, index),
      builder: (context, candidates, _) {
        final isTargeted = candidates.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          hapticFeedbackOnStart: true,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _photoImage(_photos[index]),
              ),
            ),
          ),
          childWhenDragging: _emptySlot(isDragTarget: true),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTargeted ? const Color(0xFFB31637) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _photoImage(_photos[index]),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _photos.removeAt(index)),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB31637),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(AppLocalizations.of(context)!.photoMain,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.photos,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFA4A4AA))),
        if (!_isEditing) ...[
          const SizedBox(height: 4),
          Text(
            l10n.photosCoupleTogetherHint,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A7A80),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: 6,
          itemBuilder: (_, i) => _buildPhotoCell(i),
        ),
        if (_photoError != null) ...[
          const SizedBox(height: 6),
          Text(_photoError!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Height ───────────────────────────────────────────────────────────────────

  String _formatHeight({
    required bool isCm,
    required TextEditingController cmCtrl,
    required TextEditingController feetCtrl,
    required TextEditingController inchesCtrl,
  }) {
    // Height is optional — return an empty string when nothing was entered
    // so downstream consumers can render "—" or hide the field instead of
    // showing a stray unit suffix.
    if (isCm) {
      final cm = cmCtrl.text.trim();
      return cm.isEmpty ? '' : '$cm cm';
    }
    final feet = feetCtrl.text.trim();
    final inches = inchesCtrl.text.trim();
    if (feet.isEmpty && inches.isEmpty) return '';
    return "$feet'$inches\"";
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Parses a "DD/MM/YYYY" string and returns the current age in years.
  /// Returns -1 on malformed input so callers can treat it as "invalid".
  int _ageFromBirth(String birth) {
    final parts = birth.split('/');
    if (parts.length != 3) return -1;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return -1;
    final now = DateTime.now();
    int age = now.year - y;
    if (now.month < m || (now.month == m && now.day < d)) age--;
    return age < 0 ? -1 : age;
  }

  bool _validate(AppLocalizations l10n) {
    setState(() {
      _errors = {};
      _photoError = null;
    });

    bool isValid = true;

    // Client spec (2026-04-21): registration requires a minimum of 3 photos,
    // all showing the couple together. Applies only on initial profile
    // setup — after that the user can freely edit/add/remove photos. The
    // "couple together" part is communicated via on-screen guidance since
    // we cannot validate image content client-side.
    if (!_isEditing && _photos.length < 3) {
      setState(() => _photoError = l10n.photoMinError);
      isValid = false;
    }

    final herName = _herNameController.text.trim();
    final hisName = _hisNameController.text.trim();
    final herBirth = _herBirthController.text.trim();
    final hisBirth = _hisBirthController.text.trim();
    final description = _descriptionController.text.trim();

    // Check each field individually to show red borders
    if (herName.isEmpty) {
      _errors['herName'] = '';
      isValid = false;
    } else if (herName.length < 2) {
      _errors['herName'] = l10n.errorNameTooShort;
      isValid = false;
    }

    if (hisName.isEmpty) {
      _errors['hisName'] = '';
      isValid = false;
    } else if (hisName.length < 2) {
      _errors['hisName'] = l10n.errorNameTooShort;
      isValid = false;
    }

    if (herBirth.isEmpty) {
      _errors['herBirth'] = '';
      isValid = false;
    }

    if (hisBirth.isEmpty) {
      _errors['hisBirth'] = '';
      isValid = false;
    }

    // +21 age gate — DECISIONS_LOG Point 5 + Apple App Store requirement for
    // adult/dating categories. Both partners must be >= 21.
    if (herBirth.isNotEmpty) {
      final herAge = _ageFromBirth(herBirth);
      if (herAge < 21) {
        _errors['herBirth'] = 'Must be 21 or older';
        isValid = false;
      }
    }
    if (hisBirth.isNotEmpty) {
      final hisAge = _ageFromBirth(hisBirth);
      if (hisAge < 21) {
        _errors['hisBirth'] = 'Must be 21 or older';
        isValid = false;
      }
    }

    if (_selectedCity == null) {
      _errors['city'] = '';
      isValid = false;
    }

    if (description.isEmpty) {
      _errors['description'] = '';
      isValid = false;
    }

    if (_selectedTags.isEmpty) {
      _errors['tags'] = '';
      isValid = false;
    }

    // Height is optional per client spec (2026-04-21). If the user leaves
    // it blank the profile still saves; _formatHeight() returns an empty
    // string in that case, which the model treats as "not provided".

    if (!isValid) {
      // Legacy code surfaced `errorSignIn` ("Sign-in failed") whenever any
      // specific field had a red border, which confused users because the
      // screen is profile setup, not sign-in. Showing the generic
      // "All fields are required" text is closer to the user's actual
      // situation; individual red borders already pinpoint what's wrong.
      _showError(l10n.errorAllFieldsRequired);
    }

    setState(() {}); // Refresh UI to show red borders
    return isValid;
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_validate(l10n)) return;

    setState(() => _isLoading = true);
    try {
      final photoUrls = <String>[];
      for (int i = 0; i < _photos.length; i++) {
        final p = _photos[i];
        if (p.isLocal) {
          // Storage upload is best-effort in dev: if the bucket is not yet
          // provisioned (404 / object-not-found) we skip the photo so the
          // rest of the profile still saves and the rest of the app stays
          // demo-able. Real uploads will start succeeding the moment the
          // bucket is enabled — no further code changes required.
          try {
            photoUrls.add(
              await ProfileDatasource.uploadPhoto(widget.uid, p.file!, i),
            );
          } catch (e) {
            // ignore: avoid_print
            print('PHOTO_UPLOAD_SKIPPED (#$i): $e');
          }
        } else {
          photoUrls.add(p.url!);
        }
      }

      final profile = UserProfile(
        uid: widget.uid,
        herName: _herNameController.text.trim(),
        hisName: _hisNameController.text.trim(),
        herBirth: _herBirthController.text.trim(),
        hisBirth: _hisBirthController.text.trim(),
        city: _selectedCity ?? '',
        herHeight: _formatHeight(
          isCm: _herHeightIsCm,
          cmCtrl: _herHeightCmController,
          feetCtrl: _herFeetController,
          inchesCtrl: _herInchesController,
        ),
        hisHeight: _formatHeight(
          isCm: _hisHeightIsCm,
          cmCtrl: _hisHeightCmController,
          feetCtrl: _hisFeetController,
          inchesCtrl: _hisInchesController,
        ),
        description: _descriptionController.text.trim(),
        interests: _selectedTags.join(', '),
        photos: photoUrls,
      );

      await ProfileDatasource.createProfile(profile);

      // Client spec (2026-04-21): on initial registration the couple doc
      // must exist with status=pending_review so the user lands on the
      // Verification Pending gate until a moderator approves the video.
      // When editing an existing profile we never touch status here; the
      // `updateCouple` patch below only carries geo fields.
      if (!_isEditing) {
        try {
          await CouplesDatasource.createCouple(
            Couple(
              id: widget.uid,
              partnerA: Partner(
                name: profile.herName,
                birth: profile.herBirth,
                height: profile.herHeight,
              ),
              partnerB: Partner(
                name: profile.hisName,
                birth: profile.hisBirth,
                height: profile.hisHeight,
              ),
              city: _selectedPlace?.city ?? profile.city,
              country: _selectedPlace?.country ?? '',
              countryCode: _selectedPlace?.countryCode ?? '',
              lat: _selectedPlace?.lat,
              lng: _selectedPlace?.lng,
              geohash: _selectedPlace?.geohash,
              description: profile.description,
              photos: profile.photos,
              interests: _selectedTags.toList(),
              openToUnicorn: _openToUnicorn,
              openToBull: _openToBull,
              status: CoupleStatus.pendingReview,
              ageRange: AgeRange.fromBirths(profile.herBirth, profile.hisBirth),
            ),
          );
        } catch (e) {
          // ignore: avoid_print
          print('COUPLE_CREATE_SKIPPED: $e');
        }
      } else {
        // Edit mode: patch interests, openness, and any new geo fields.
        final patch = <String, dynamic>{
          'interests': _selectedTags.toList(),
          'open_to_unicorn': _openToUnicorn,
          'open_to_bull': _openToBull,
        };
        if (_selectedPlace != null && _selectedPlace!.lat != 0) {
          patch.addAll(_selectedPlace!.toCoupleFields());
        }
        try {
          await CouplesDatasource.updateCouple(widget.uid, patch);
        } catch (_) {
          // Non-fatal — the legacy write already succeeded.
        }
      }
      if (!mounted) return;

      if (_isEditing) {
        Navigator.pop(context, true);
      } else {
        // New account → head to verification video capture, not the feed.
        // The couple doc is pending_review, so the feed would be blocked
        // anyway; routing straight to VerificationIntroScreen makes the
        // single-register-then-verify flow feel continuous.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VerificationIntroScreen()),
          (route) => false,
        );
      }
    } catch (e, st) {
      // Surface the real failure in the snackbar (and logcat) so we can
      // diagnose Firestore/Storage/permission errors during dev.
      // ignore: avoid_print
      print('PROFILE_SAVE_ERROR: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorSaveProfile}\n$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logOut() async {
    await AuthDatasource.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.completeProfile),
        automaticallyImplyLeading: _isEditing,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          16 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(l10n),
            Row(
              children: [
                Expanded(
                  child: CustomInput(
                    label: l10n.name,
                    hintText: l10n.her,
                    controller: _herNameController,
                    errorText: _errorFor('herName'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInput(
                    label: l10n.name,
                    hintText: l10n.his,
                    controller: _hisNameController,
                    errorText: _errorFor('hisName'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CustomInput(
                    label: l10n.dateOfBirth,
                    type: InputType.date,
                    controller: _herBirthController,
                    errorText: _errorFor('herBirth'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInput(
                    label: l10n.dateOfBirth,
                    type: InputType.date,
                    controller: _hisBirthController,
                    errorText: _errorFor('hisBirth'),
                  ),
                ),
              ],
            ),
            PlacesAutocompleteField(
              label: l10n.selectCity,
              hintText: l10n.selectCity,
              initialValue: _selectedPlace,
              onSelected: (place) => setState(() {
                _selectedPlace = place;
                _selectedCity = place.city;
                _errors['city'] = null;
              }),
              errorText: _errorFor('city'),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HeightInput(
                    label: l10n.herHeight,
                    isCm: _herHeightIsCm,
                    onUnitChanged: (v) => setState(() => _herHeightIsCm = v),
                    cmController: _herHeightCmController,
                    feetController: _herFeetController,
                    inchesController: _herInchesController,
                    errorText: _errorFor('herHeight'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeightInput(
                    label: l10n.hisHeight,
                    isCm: _hisHeightIsCm,
                    onUnitChanged: (v) => setState(() => _hisHeightIsCm = v),
                    cmController: _hisHeightCmController,
                    feetController: _hisFeetController,
                    inchesController: _hisInchesController,
                    errorText: _errorFor('hisHeight'),
                  ),
                ),
              ],
            ),
            CustomInput(
              label: l10n.description,
              hintText: l10n.tellUsAboutYourself,
              type: InputType.textarea,
              controller: _descriptionController,
              errorText: _errorFor('description'),
            ),
            const SizedBox(height: 4),
            _buildInterestsSection(),
            _buildOpennessSection(),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  l10n.updateInterestsNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            CustomButton(
              buttonText: _isLoading
                  ? '...'
                  : (_isEditing
                      ? l10n.saveProfile
                      : l10n.goToVerificationVideo),
              type: ButtonType.mainSystem,
              onTap: _isLoading ? null : () => _save(l10n),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 12),
              CustomButton(
                buttonText: l10n.logOut,
                type: ButtonType.link,
                onTap: _isLoading ? null : _logOut,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB31637) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFB31637) : const Color(0xFFDDDDDD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 13, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF555555),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Height input ──────────────────────────────────────────────────────────────

class _HeightInput extends StatelessWidget {
  final String label;
  final bool isCm;
  final ValueChanged<bool> onUnitChanged;
  final TextEditingController cmController;
  final TextEditingController feetController;
  final TextEditingController inchesController;
  final String? errorText;

  const _HeightInput({
    required this.label,
    required this.isCm,
    required this.onUnitChanged,
    required this.cmController,
    required this.feetController,
    required this.inchesController,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFA4A4AA))),
        const SizedBox(height: 4),
        Row(
          children: [
            _Toggle(label: 'cm', selected: isCm, onTap: () => onUnitChanged(true)),
            const SizedBox(width: 6),
            _Toggle(label: 'ft/in', selected: !isCm, onTap: () => onUnitChanged(false)),
          ],
        ),
        const SizedBox(height: 4),
        if (isCm)
          _box(
            error: errorText != null,
            child: TextField(
              controller: cmController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '170',
                hintStyle: TextStyle(color: Color(0xFFA4A4AA)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _box(
                  error: errorText != null,
                  child: TextField(
                    controller: feetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '5',
                      hintStyle: TextStyle(color: Color(0xFFA4A4AA)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      suffixText: 'ft',
                      suffixStyle: TextStyle(color: Color(0xFFA4A4AA)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _box(
                  error: errorText != null,
                  child: TextField(
                    controller: inchesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '7',
                      hintStyle: TextStyle(color: Color(0xFFA4A4AA)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      suffixText: 'in',
                      suffixStyle: TextStyle(color: Color(0xFFA4A4AA)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 13),
      ],
    );
  }

  Widget _box({required Widget child, bool error = false}) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: error ? Colors.red : const Color(0xFFA4A4AA)),
        ),
        child: child,
      );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Toggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB31637) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFB31637) : const Color(0xFFA4A4AA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : const Color(0xFFA4A4AA),
          ),
        ),
      ),
    );
  }
}
