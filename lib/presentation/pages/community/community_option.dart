import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:app/l10n/app_localizations.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class CommentModel {
  final String name1;
  final String name2;
  final DateTime time;
  final String text;
  final int gradientIndex;

  const CommentModel({
    required this.name1,
    required this.name2,
    required this.time,
    required this.text,
    required this.gradientIndex,
  });
}

class PostModel {
  final String name1;
  final String name2;
  final DateTime postedAt;
  final String text;
  final bool hasImage;
  final String? imageFilePath;
  final int gradientIndex;
  final int imageGradientIndex;
  int likes;
  bool likedByMe;
  final List<CommentModel> comments;
  final bool isOwn;

  PostModel({
    required this.name1,
    required this.name2,
    required this.postedAt,
    required this.text,
    required this.hasImage,
    this.imageFilePath,
    required this.gradientIndex,
    this.imageGradientIndex = 0,
    required this.likes,
    required this.likedByMe,
    required this.comments,
    this.isOwn = false,
  });
}

// ── Option ────────────────────────────────────────────────────────────────────

class CommunityOption extends StatefulWidget {
  const CommunityOption({super.key});

  @override
  State<CommunityOption> createState() => _CommunityOptionState();
}

class _CommunityOptionState extends State<CommunityOption> {
  static const List<List<Color>> _gradients = [
    [Color(0xFFFF6B9D), Color(0xFFC44CFF)],
    [Color(0xFF4ECAFF), Color(0xFF3B82F6)],
    [Color(0xFF66BB6A), Color(0xFF26A69A)],
    [Color(0xFFFF8A65), Color(0xFFE91E63)],
    [Color(0xFFFFB74D), Color(0xFFE64A19)],
    [Color(0xFF9C27B0), Color(0xFF3F51B5)],
  ];

  late final List<PostModel> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _buildMockPosts()..shuffle();
  }

  List<PostModel> _buildMockPosts() => [
        PostModel(
          name1: 'Ana',
          name2: 'Carlos',
          postedAt: DateTime.now().subtract(const Duration(hours: 2)),
          text:
              '¡Menudo planazo el de ayer en el Born! Definitivamente tenemos que volver 🥂✨',
          hasImage: true,
          gradientIndex: 0,
          imageGradientIndex: 2,
          likes: 24,
          likedByMe: false,
          comments: [
            CommentModel(
              name1: 'Sofia',
              name2: 'Mateo',
              time: DateTime.now().subtract(const Duration(minutes: 45)),
              text: '¡Qué envidia! Tenemos que ir juntos la próxima vez 😍',
              gradientIndex: 1,
            ),
            CommentModel(
              name1: 'Laura',
              name2: 'Javi',
              time: DateTime.now().subtract(const Duration(hours: 1)),
              text: 'Nosotros también fuimos el mes pasado, ¡es increíble! 🙌',
              gradientIndex: 2,
            ),
          ],
        ),
        PostModel(
          name1: 'Sofia',
          name2: 'Mateo',
          postedAt: DateTime.now().subtract(const Duration(hours: 5)),
          text:
              'Primer aniversario juntos como pareja 🎉❤️ Ha sido el año más bonito de nuestras vidas',
          hasImage: false,
          gradientIndex: 1,
          likes: 87,
          likedByMe: true,
          comments: [
            CommentModel(
              name1: 'Ana',
              name2: 'Carlos',
              time: DateTime.now().subtract(const Duration(minutes: 10)),
              text: '¡Felicidades! Sois la pareja más adorable 💕',
              gradientIndex: 0,
            ),
            CommentModel(
              name1: 'Marta',
              name2: 'Pablo',
              time: DateTime.now().subtract(const Duration(hours: 3)),
              text: '¡Muchísimas felicidades! Que sean muchos más 🥳',
              gradientIndex: 3,
            ),
            CommentModel(
              name1: 'Rita',
              name2: 'Leo',
              time: DateTime.now().subtract(const Duration(hours: 4)),
              text: '¡Os queremos! 🎊',
              gradientIndex: 4,
            ),
          ],
        ),
        PostModel(
          name1: 'Laura',
          name2: 'Javi',
          postedAt: DateTime.now().subtract(const Duration(days: 1)),
          text:
              'Senderismo en Montserrat 🏔️ Nada como un domingo de naturaleza para recargar pilas',
          hasImage: true,
          gradientIndex: 2,
          imageGradientIndex: 4,
          likes: 41,
          likedByMe: false,
          comments: [
            CommentModel(
              name1: 'Noa',
              name2: 'Erik',
              time: DateTime.now()
                  .subtract(const Duration(days: 1, hours: 2)),
              text:
                  'Nosotros fuimos la semana pasada, está precioso ahora 🌿',
              gradientIndex: 5,
            ),
          ],
        ),
        PostModel(
          name1: 'Marta',
          name2: 'Pablo',
          postedAt: DateTime.now().subtract(const Duration(days: 2)),
          text:
              'Acabamos de hacer match con una pareja superchula 🎉 ¡Esta app es increíble!',
          hasImage: false,
          gradientIndex: 3,
          likes: 15,
          likedByMe: false,
          comments: [],
        ),
        PostModel(
          name1: 'Noa',
          name2: 'Erik',
          postedAt: DateTime.now().subtract(const Duration(days: 3)),
          text:
              'Tarde de cocina en casa 🍝 ¿Alguien más es fan de cocinar en pareja?',
          hasImage: true,
          gradientIndex: 5,
          imageGradientIndex: 1,
          likes: 32,
          likedByMe: true,
          comments: [
            CommentModel(
              name1: 'Sofia',
              name2: 'Mateo',
              time: DateTime.now()
                  .subtract(const Duration(days: 2, hours: 18)),
              text: '¡A nosotros nos encanta! Es nuestra actividad favorita ❤️',
              gradientIndex: 1,
            ),
            CommentModel(
              name1: 'Laura',
              name2: 'Javi',
              time: DateTime.now().subtract(const Duration(days: 3)),
              text: 'Siempre cocinamos juntos los domingos 🍕',
              gradientIndex: 2,
            ),
          ],
        ),
      ];

  void _onPost(String text, String? imageFilePath) {
    setState(() {
      _posts.insert(
        0,
        PostModel(
          name1: 'You',
          name2: '',
          postedAt: DateTime.now(),
          text: text,
          hasImage: imageFilePath != null,
          imageFilePath: imageFilePath,
          gradientIndex: 0,
          likes: 0,
          likedByMe: false,
          comments: [],
          isOwn: true,
        ),
      );
    });
  }

  void _deletePost(int index) {
    setState(() => _posts.removeAt(index));
  }

  void _toggleLike(int index) {
    setState(() {
      final p = _posts[index];
      p.likedByMe ? p.likes-- : p.likes++;
      p.likedByMe = !p.likedByMe;
    });
  }

  void _openComments(int index) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
        post: _posts[index],
        gradients: _gradients,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _FloatingComposer(onPost: _onPost),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _posts.length,
            separatorBuilder: (_, __) => const SizedBox(
              height: 10,
              child: ColoredBox(color: Color(0xFFF5F5F5)),
            ),
            itemBuilder: (context, i) => _PostCard(
              post: _posts[i],
              gradients: _gradients,
              onLike: () => _toggleLike(i),
              onComment: () => _openComments(i),
              onDelete: _posts[i].isOwn ? () => _deletePost(i) : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final PostModel post;
  final List<List<Color>> gradients;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onDelete;

  const _PostCard({
    required this.post,
    required this.gradients,
    required this.onLike,
    required this.onComment,
    this.onDelete,
  });

  static const Color _grey = Color(0xFFB9B9B9);
  static const Color _red = Color(0xFFB31637);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          Text(
            post.text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.45,
            ),
          ),
          if (post.hasImage) ...[
            const SizedBox(height: 10),
            _buildImage(),
          ],
          const SizedBox(height: 12),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colors = gradients[post.gradientIndex % gradients.length];
    final date = DateFormat('dd/MM/yyyy hh:mm a')
        .format(post.postedAt)
        .toLowerCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _AvatarCircle(size: 44, colors: colors),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.name2.isEmpty
                    ? post.name1
                    : '${post.name1} & ${post.name2}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFFB9B9B9)),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: Color(0xFFB9B9B9), size: 20),
            onSelected: (value) {
              if (value == 'delete') onDelete!();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: Color(0xFFB31637), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Delete post',
                      style: TextStyle(color: Color(0xFFB31637)),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (post.imageFilePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(post.imageFilePath!),
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradients[post.imageGradientIndex % gradients.length],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, color: Colors.white38, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        GestureDetector(
          onTap: onLike,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(
                post.likedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.likedByMe ? _red : _grey,
                size: 22,
              ),
              const SizedBox(width: 5),
              Text(
                '${post.likes}',
                style: TextStyle(
                  fontSize: 13,
                  color: post.likedByMe ? _red : _grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 22),
        GestureDetector(
          onTap: onComment,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Icon(
                Icons.mode_comment_outlined,
                color: _grey,
                size: 22,
              ),
              const SizedBox(width: 5),
              Text(
                '${post.comments.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: _grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Comments Sheet ────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final PostModel post;
  final List<List<Color>> gradients;
  final VoidCallback onChanged;

  const _CommentsSheet({
    required this.post,
    required this.gradients,
    required this.onChanged,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    if (d.inDays < 28) return '${d.inDays ~/ 7}w';
    if (d.inDays < 365) return '${d.inDays ~/ 30}mo';
    return '${d.inDays ~/ 365}y';
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.post.comments.add(CommentModel(
        name1: 'Vosotros',
        name2: '',
        time: DateTime.now(),
        text: text,
        gradientIndex: 0,
      ));
      _ctrl.clear();
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardH = mq.viewInsets.bottom;
    final safeBottom = mq.padding.bottom;
    final screenH = mq.size.height;

    // List shrinks as the keyboard rises to prevent overflow.
    final listMaxH =
        (screenH * 0.40 - keyboardH).clamp(80.0, screenH * 0.40);

    return Padding(
      padding: EdgeInsets.only(
        bottom: keyboardH > 0 ? keyboardH : safeBottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Comments',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),

            const Divider(height: 1),

            // Comment list — height adapts to keyboard
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: listMaxH),
              child: widget.post.comments.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No comments yet.\nBe the first! 💬',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.black38, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      shrinkWrap: true,
                      itemCount: widget.post.comments.length,
                      itemBuilder: (_, i) {
                        final c = widget.post.comments[i];
                        return _CommentRow(
                          comment: c,
                          gradients: widget.gradients,
                          relTime: _relTime(c.time),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            // Input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle:
                              TextStyle(color: Colors.black38, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB31637),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Comment Row ───────────────────────────────────────────────────────────────

class _CommentRow extends StatelessWidget {
  final CommentModel comment;
  final List<List<Color>> gradients;
  final String relTime;

  const _CommentRow({
    required this.comment,
    required this.gradients,
    required this.relTime,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradients[comment.gradientIndex % gradients.length];
    final name = comment.name2.isEmpty
        ? comment.name1
        : '${comment.name1} & ${comment.name2}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarCircle(size: 36, colors: colors),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      relTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Composer ─────────────────────────────────────────────────────────

class _FloatingComposer extends StatefulWidget {
  final void Function(String text, String? imageFilePath) onPost;

  const _FloatingComposer({required this.onPost});

  @override
  State<_FloatingComposer> createState() => _FloatingComposerState();
}

class _FloatingComposerState extends State<_FloatingComposer> {
  bool _expanded = false;
  XFile? _pickedImage;
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _collapse() {
    setState(() {
      _expanded = false;
      _pickedImage = null;
      _ctrl.clear();
    });
    _focus.unfocus();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onPost(text, _pickedImage?.path);
    _collapse();
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.imagePickerGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.imagePickerCamera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: _expanded ? null : _expand,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFB31637),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _expanded ? _buildExpanded() : _buildCollapsed(),
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Share with the community',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.edit, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'What do you have in mind',
                    hintStyle: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Image preview or add-image button
          if (_pickedImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _pickedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Add image',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          const SizedBox(height: 10),

          // Share button
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send, size: 17, color: Colors.black87),
            label: const Text(
              'Share with the community',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared avatar ─────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _AvatarCircle({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.favorite,
          color: Colors.white30,
          size: size * 0.4,
        ),
      ),
    );
  }
}
