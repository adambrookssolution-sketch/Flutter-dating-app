import 'package:flutter/material.dart';

import 'package:app/presentation/pages/verification/video_record_screen.dart';

/// First step of identity verification — explains what the user must record
/// before we open the camera. Keeps the camera off until the user opts in,
/// which is both a UX nicety and an Apple privacy guideline (camera should
/// only activate after explicit user intent).
///
/// Wired by [navigateAfterSignIn] when:
/// - the couple just finished profile setup, or
/// - status was rejected with attempts == 1 and the user tapped "retry".
class VerificationIntroScreen extends StatelessWidget {
  /// Which attempt this is (1 or 2). Used by the next screen to enforce the
  /// 2-attempt cap (DECISIONS_LOG Point 1).
  final int attemptNumber;

  const VerificationIntroScreen({super.key, this.attemptNumber = 1});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Verify your couple',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Attempt $attemptNumber of 2',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFA4A4AA),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'A short video confirms a real couple is behind the account. '
                'Our team reviews every video manually — no AI scoring, no face '
                'matching against external databases.',
                style: TextStyle(fontSize: 15, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 24),
              const Text(
                "Here's what you need to do:",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ..._steps.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFFB31637), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6B800)),
                ),
                child: const Text(
                  'Your video is private. After approval it is auto-deleted '
                  'within 7 days. Only a verification hash and a few low-res '
                  'frames are kept.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B5500)),
                ),
              ),
              const SizedBox(height: 16),
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoRecordScreen(
                        attemptNumber: attemptNumber,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Start recording',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _steps = [
    'Both partners visible together in the same shot',
    'Good lighting on your faces',
    'Say out loud: "Today is [today\'s date], we are joining Affinity"',
    'Recording lasts 10 to 30 seconds',
    'No filters, no edits — straight from the camera',
  ];
}
