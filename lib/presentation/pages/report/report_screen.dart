import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/reports_datasource.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/data/models/report.dart';
import 'package:app/l10n/app_localizations.dart';

/// Report submission form. Reached from the ⋮ menu on another couple's
/// profile card or chat header. Per DECISIONS_LOG Point 5:
/// - Category dropdown (6 predefined entries — closed list).
/// - Description free-text, required only for "Otro".
/// - "Block this couple too" checkbox, PRE-CHECKED by default.
///
/// Submission is atomic: the report insert and (when alsoBlock is true) the
/// block insert go in the same Firestore batch. See ReportsDatasource.
class ReportScreen extends StatefulWidget {
  final Couple reported;

  const ReportScreen({super.key, required this.reported});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportCategory _category = ReportCategory.perfilFalso;
  final _descController = TextEditingController();
  bool _alsoBlock = true; // pre-checked per DECISIONS_LOG Point 5
  bool _submitting = false;
  String? _error;

  String _categoryLabel(AppLocalizations l10n, ReportCategory c) {
    switch (c) {
      case ReportCategory.perfilFalso:
        return l10n.reportCategoryFakeProfile;
      case ReportCategory.acoso:
        return l10n.reportCategoryHarassment;
      case ReportCategory.contenidoNoConsensuado:
        return l10n.reportCategoryNonConsensual;
      case ReportCategory.menorEdad:
        return l10n.reportCategoryMinor;
      case ReportCategory.spam:
        return l10n.reportCategorySpam;
      case ReportCategory.otro:
        return l10n.reportCategoryOther;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _descriptionRequired => _category == ReportCategory.otro;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_descriptionRequired && _descController.text.trim().isEmpty) {
      setState(() => _error = l10n.reportDescribeOther);
      return;
    }
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ReportsDatasource.submitReport(
        reporterCoupleId: me,
        reportedCoupleId: widget.reported.id,
        categoria: _category,
        descripcion: _descController.text.trim(),
        alsoBlock: _alsoBlock,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      // Client feedback 2026-05-17 #2: the success snackbar should
      // promise a follow-up so the user knows their report won't fall
      // into a black hole. Bumped to 5s so they actually get to read
      // it (the default 3s is too short for the longer message).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reportSubmittedWithFollowup),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.reportCouldNotSubmit(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final names =
        '${widget.reported.partnerA.name} & ${widget.reported.partnerB.name}';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportCoupleTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportingCouple(names),
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.reportCategoryLabel,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFA4A4AA)),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ReportCategory>(
                  value: _category,
                  isExpanded: true,
                  items: [
                    for (final c in ReportCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Text(_categoryLabel(l10n, c)),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (v) {
                          if (v != null) setState(() => _category = v);
                        },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _descriptionRequired
                  ? l10n.reportDescriptionRequired
                  : l10n.reportDescriptionOptional,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.reportDescriptionHint,
              ),
            ),
            CheckboxListTile(
              value: _alsoBlock,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _alsoBlock = v ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.blockThisCoupleToo),
              subtitle: Text(
                l10n.reportAlsoBlockSubtitle,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB01030),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(250),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: Text(
                  _submitting ? l10n.reportSubmitting : l10n.reportSubmit,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.reportFooterConfidential,
              style: const TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
