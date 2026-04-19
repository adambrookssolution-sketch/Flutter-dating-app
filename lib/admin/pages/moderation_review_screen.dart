import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:app/data/models/couple.dart';

/// Per-couple review card: profile summary, video playback, approve / reject
/// buttons. Rejection requires picking one of the predefined reasons so the
/// Cloud Function can validate and return a normalised value to the client.
class ModerationReviewScreen extends StatefulWidget {
  final Couple couple;

  const ModerationReviewScreen({super.key, required this.couple});

  @override
  State<ModerationReviewScreen> createState() =>
      _ModerationReviewScreenState();
}

class _ModerationReviewScreenState extends State<ModerationReviewScreen> {
  VideoPlayerController? _player;
  bool _submitting = false;

  static const _reasons = {
    'inappropriate': 'Inappropriate content',
    'fake': 'Appears fake / scripted',
    'single_person': 'Only one partner visible',
    'minor_suspected': 'Minor suspected',
    'quality_low': 'Video quality too low',
    'other': 'Other (see guidelines)',
  };

  @override
  void initState() {
    super.initState();
    final url = widget.couple.verification?.videoUrl;
    if (url != null && url.isNotEmpty) {
      final p = VideoPlayerController.networkUrl(Uri.parse(url));
      p.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
      _player = p;
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _moderate({
    required String decision,
    String? reason,
  }) async {
    setState(() => _submitting = true);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('moderateVerification');
      await callable.call<Map<String, dynamic>>({
        'coupleId': widget.couple.id,
        'decision': decision,
        if (reason != null) 'reason': reason,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.code}: ${e.message}')),
      );
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  Future<void> _openRejectSheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Rejection reason',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'The couple sees this on their rejected screen.',
              style: TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
            ),
            const Divider(),
            ..._reasons.entries.map(
              (e) => ListTile(
                title: Text(e.value),
                onTap: () => Navigator.pop(context, e.key),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await _moderate(decision: 'reject', reason: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.couple;
    final player = _player;
    return Scaffold(
      appBar: AppBar(
        title: Text('${c.partnerA.name} & ${c.partnerB.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('City', c.city),
            _row('Country', c.country),
            _row('Age range',
                '${c.ageRange.min} – ${c.ageRange.max}'),
            _row('Attempts used',
                '${c.verification?.attempts ?? 0} / 2'),
            const SizedBox(height: 16),
            if (player != null && player.value.isInitialized)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AspectRatio(
                    aspectRatio: player.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(player),
                        IconButton(
                          icon: Icon(
                            player.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 64,
                          ),
                          onPressed: () {
                            setState(() {
                              player.value.isPlaying
                                  ? player.pause()
                                  : player.play();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const SizedBox(
                height: 240,
                child:
                    Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 16),
            const Text('Photos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.photos
                  .map(
                    (url) => Image.network(
                      url,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _submitting
                        ? null
                        : () => _moderate(decision: 'approve'),
                    child: const Text(
                      'Approve',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _submitting ? null : _openRejectSheet,
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFA4A4AA), fontSize: 13),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
