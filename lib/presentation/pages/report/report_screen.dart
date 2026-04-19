import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/reports_datasource.dart';
import 'package:app/data/models/couple.dart';
import 'package:app/data/models/report.dart';

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

  static const _categoryLabels = {
    ReportCategory.perfilFalso: 'Fake profile',
    ReportCategory.acoso: 'Harassment',
    ReportCategory.contenidoNoConsensuado: 'Non-consensual content',
    ReportCategory.menorEdad: 'Suspected minor',
    ReportCategory.spam: 'Spam',
    ReportCategory.otro: 'Other',
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _descriptionRequired => _category == ReportCategory.otro;

  Future<void> _submit() async {
    if (_descriptionRequired && _descController.text.trim().isEmpty) {
      setState(
          () => _error = 'Please describe the issue when selecting "Other".');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not submit: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report couple'),
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
              'Reporting ${widget.reported.partnerA.name} & ${widget.reported.partnerB.name}',
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
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
                    for (final entry in _categoryLabels.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
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
                  ? 'Description (required)'
                  : 'Description (optional)',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Share any context that would help moderators…',
              ),
            ),
            CheckboxListTile(
              value: _alsoBlock,
              onChanged:
                  _submitting ? null : (v) => setState(() => _alsoBlock = v ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Block this couple too'),
              subtitle: const Text(
                'Both couples stop seeing each other immediately.',
                style: TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
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
                  backgroundColor: const Color(0xFFB31637),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(250),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Submitting…' : 'Submit report'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reports are confidential. The reported couple is never told who '
              'submitted the report.',
              style: TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
