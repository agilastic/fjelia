import '../theme/fjelia_style.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../db/database.dart';
import '../l10n/l10n_ext.dart';
import '../providers/media_provider.dart';
import '../utils/log.dart';
import 'app_widgets.dart';
import 'media_share_card.dart';

/// Photos and videos of an activity, race goal or planned session: a strip
/// of thumbnails, an add button, and a full-screen viewer.
class MediaGallery extends ConsumerStatefulWidget {
  const MediaGallery({super.key, required this.owner, this.shareInfo});

  final MediaOwner owner;

  /// For an activity: the facts a photo can be shared with as a card.
  final ActivityShareInfo? shareInfo;

  @override
  ConsumerState<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends ConsumerState<MediaGallery> {
  /// (done, total) while files are being copied and converted.
  (int, int)? progress;

  Future<void> _add() async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: duo(0xFF1A1A1A, 0xFFF7F8FA),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.mediaFromLibrary),
              onTap: () => Navigator.pop(context, 'library'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.mediaTakePhoto),
              onTap: () => Navigator.pop(context, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l10n.mediaRecordVideo),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    // On iOS the originals come through and are scaled down natively, which
    // keeps when and where a photo was taken; elsewhere the picker scales.
    final side = Platform.isIOS ? null : 2560.0;
    final quality = Platform.isIOS ? null : 85;
    final List<XFile> files;
    try {
      files = switch (choice) {
        'library' => await picker.pickMultipleMedia(
          maxWidth: side,
          maxHeight: side,
          imageQuality: quality,
        ),
        'photo' => [
          ?await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: side,
            maxHeight: side,
            imageQuality: quality,
          ),
        ],
        _ => [?await picker.pickVideo(source: ImageSource.camera)],
      };
    } catch (e) {
      log('[Media] picker failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.mediaAddFailed)));
      }
      return;
    }
    if (files.isEmpty || !mounted) return;
    setState(() => progress = (0, files.length));
    final added = await ref
        .read(mediaServiceProvider)
        .add(
          widget.owner,
          [for (final f in files) f.path],
          onProgress: (done, total) {
            if (mounted) setState(() => progress = (done, total));
          },
        );
    if (!mounted) return;
    setState(() => progress = null);
    if (added < files.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mediaAddFailed)));
    }
  }

  Future<void> _actions(MediaItem item, int index, int count) async {
    final l10n = context.l10n;
    final service = ref.read(mediaServiceProvider);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: duo(0xFF1A1A1A, 0xFFF7F8FA),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.chevron_left),
                title: Text(l10n.mediaMoveEarlier),
                onTap: () => Navigator.pop(context, 'earlier'),
              ),
            if (index < count - 1)
              ListTile(
                leading: const Icon(Icons.chevron_right),
                title: Text(l10n.mediaMoveLater),
                onTap: () => Navigator.pop(context, 'later'),
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.redAccent),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'earlier':
        await service.move(item, -1);
      case 'later':
        await service.move(item, 1);
      case 'delete':
        if (await confirmAction(
          context,
          l10n.mediaDeleteTitle,
          l10n.mediaDeleteMessage,
        )) {
          await service.delete(item);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items =
        ref.watch(mediaItemsProvider(widget.owner)).valueOrNull ?? const [];
    final busy = progress;
    return SectionCard(
      title: l10n.mediaTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return _AddTile(onTap: busy == null ? _add : null);
                }
                final item = items[index];
                return _Thumbnail(
                  item: item,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => MediaViewer(
                        items: items,
                        initialIndex: index,
                        shareInfo: widget.shareInfo,
                      ),
                    ),
                  ),
                  onLongPress: () => _actions(item, index, items.length),
                );
              },
            ),
          ),
          if (busy != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: busy.$2 == 0 ? null : busy.$1 / busy.$2,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mediaAdding(
                busy.$1 + 1 > busy.$2 ? busy.$2 : busy.$1 + 1,
                busy.$2,
              ),
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ] else if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.mediaHint,
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fjInk24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: onTap == null ? fjInk24 : mint,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.mediaAdd,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    ),
  );
}

/// The small picture of a photo or video (its thumbnail, else the photo).
class MediaThumb extends StatelessWidget {
  const MediaThumb({super.key, required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) =>
      item.thumbName == null && item.kind == 'video'
      ? ColoredBox(color: duo(0xFF282828, 0xFFEEF1F5))
      : _MediaFile(
          name: item.thumbName ?? item.fileName,
          builder: (file) => Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 264,
            errorBuilder: (_, _, _) =>
                ColoredBox(color: duo(0xFF282828, 0xFFEEF1F5)),
          ),
        );
}

/// The file of [name] in the media folder, resolved once per widget.
class _MediaFile extends ConsumerWidget {
  const _MediaFile({required this.name, required this.builder});
  final String name;
  final Widget Function(File file) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<File>(
    future: ref.read(mediaServiceProvider).file(name),
    builder: (context, snapshot) => snapshot.data == null
        ? ColoredBox(color: duo(0xFF282828, 0xFFEEF1F5))
        : builder(snapshot.data!),
  );
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });
  final MediaItem item;
  final VoidCallback onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final video = item.kind == 'video';
    final seconds = (item.durationMs ?? 0) ~/ 1000;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaThumb(item: item),
              if (video)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow, size: 12),
                        if (seconds > 0)
                          Text(
                            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen: swipe through photos and videos; zoom photos, play videos.
class MediaViewer extends ConsumerStatefulWidget {
  const MediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.shareInfo,
  });
  final List<MediaItem> items;
  final int initialIndex;

  /// Offers "Share as card" for photos of an activity.
  final ActivityShareInfo? shareInfo;

  @override
  ConsumerState<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends ConsumerState<MediaViewer> {
  late final controller = PageController(initialPage: widget.initialIndex);
  late int index = widget.initialIndex;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _share(BuildContext buttonContext) async {
    final item = widget.items[index];
    final file = await ref.read(mediaServiceProvider).file(item.fileName);
    if (!buttonContext.mounted) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      title: Text('${index + 1} / ${widget.items.length}'),
      actions: [
        if (widget.shareInfo != null && widget.items[index].kind == 'photo')
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: context.l10n.mediaShareCard,
            onPressed: () async {
              final item = widget.items[index];
              final file = await ref
                  .read(mediaServiceProvider)
                  .file(item.fileName);
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MediaShareCardPage(
                    info: widget.shareInfo!,
                    photos: [file],
                    initialPhoto: 0,
                  ),
                ),
              );
            },
          ),
        Builder(
          builder: (buttonContext) => IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: MaterialLocalizations.of(context).shareButtonLabel,
            onPressed: () => _share(buttonContext),
          ),
        ),
      ],
    ),
    body: PageView.builder(
      controller: controller,
      itemCount: widget.items.length,
      onPageChanged: (i) => setState(() => index = i),
      itemBuilder: (context, i) {
        final item = widget.items[i];
        return _MediaFile(
          name: item.fileName,
          builder: (file) => item.kind == 'video'
              ? _VideoPage(file: file, active: i == index)
              : InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: Image.file(file)),
                ),
        );
      },
    ),
  );
}

class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.file, required this.active});
  final File file;

  /// Plays only while its page is shown.
  final bool active;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final VideoPlayerController video = VideoPlayerController.file(
    widget.file,
  );
  bool ready = false;

  @override
  void initState() {
    super.initState();
    video.initialize().then((_) {
      if (!mounted) return;
      setState(() => ready = true);
      if (widget.active) video.play();
    });
    video.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_VideoPage old) {
    super.didUpdateWidget(old);
    if (!widget.active && video.value.isPlaying) video.pause();
  }

  @override
  void dispose() {
    video.removeListener(_changed);
    video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: () => video.value.isPlaying ? video.pause() : video.play(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
          if (!video.value.isPlaying)
            Icon(Icons.play_circle_outline, size: 72, color: fjInk70),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: VideoProgressIndicator(video, allowScrubbing: true),
          ),
        ],
      ),
    );
  }
}
