import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:app/data/datasource/blocks_datasource.dart';
import 'package:app/data/datasource/couples_datasource.dart';
import 'package:app/data/models/block.dart';
import 'package:app/data/models/couple.dart';

/// Blocked-couples management screen. Apple App Store requires dating apps
/// to expose this — DECISIONS_LOG Point 6 also mandates it.
///
/// Per block doc we display the blocked couple's names (from couples/{id}
/// lookup) and the block date. Tapping "Unblock" removes the block doc; the
/// other couple reappears in discovery on the next feed refresh.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Block>>(
        stream: BlocksDatasource.streamMyBlocks(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text('Could not load: ${snap.error}'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final blocks = snap.data!;
          if (blocks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'You have not blocked anyone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA4A4AA)),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: blocks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _BlockRow(
              block: blocks[i],
              myId: uid,
            ),
          );
        },
      ),
    );
  }
}

class _BlockRow extends StatefulWidget {
  final Block block;
  final String myId;

  const _BlockRow({required this.block, required this.myId});

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  Future<Couple?>? _couple;
  bool _unblocking = false;

  @override
  void initState() {
    super.initState();
    _couple = CouplesDatasource.getCouple(widget.block.parejaBloqueada);
  }

  Future<void> _unblock() async {
    setState(() => _unblocking = true);
    try {
      await BlocksDatasource.unblock(widget.myId, widget.block.parejaBloqueada);
      // Stream will drop the row automatically.
    } catch (e) {
      if (!mounted) return;
      setState(() => _unblocking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unblock failed: $e')),
      );
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Couple?>(
      future: _couple,
      builder: (context, snap) {
        final label = snap.data != null
            ? '${snap.data!.partnerA.name} & ${snap.data!.partnerB.name}'
            : widget.block.parejaBloqueada;
        final photo = (snap.data?.photos.isNotEmpty ?? false)
            ? snap.data!.photos.first
            : null;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Blocked on ${_formatDate(widget.block.fecha)}'
            '${widget.block.origen == BlockOrigin.viaReporte ? " (via report)" : ""}'
            '${widget.block.origen == BlockOrigin.autoPorSuspension ? " (auto)" : ""}',
            style:
                const TextStyle(fontSize: 12, color: Color(0xFFA4A4AA)),
          ),
          trailing: _unblocking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton(
                  onPressed: _unblock,
                  child: const Text('Unblock'),
                ),
        );
      },
    );
  }
}
