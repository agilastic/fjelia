import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../utils/log.dart';

/// What a photo or video belongs to.
class MediaOwner {
  const MediaOwner(this.kind, this.id, {this.date, this.sport});

  const MediaOwner.activity(String id) : this('activity', id);
  const MediaOwner.raceGoal(String id) : this('race_goal', id);

  /// A planned session; its day and sport let the media follow the session
  /// that replaces it when the plan is generated again.
  MediaOwner.session(TrainingSession s)
    : this('session', s.id, date: s.sessionDate, sport: s.sport);

  final String kind, id;
  final DateTime? date;
  final String? sport;

  @override
  bool operator ==(Object other) =>
      other is MediaOwner && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

const _videoExtensions = {'mov', 'mp4', 'm4v', '3gp', 'avi', 'mkv', 'webm'};

bool isVideoPath(String path) => _videoExtensions.contains(
  p.extension(path).replaceFirst('.', '').toLowerCase(),
);

/// Photos and videos of activities, race goals and planned sessions, copied
/// into the app's own folder. Photos arrive already reduced to 2560 px by the
/// picker; videos are converted to at most 1080p here (iOS).
class MediaService {
  MediaService(this._db, {this.root, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('fjelia/media');

  final AppDatabase _db;

  /// Folder holding `media/`; the app support folder unless given (tests).
  final Directory? root;
  final MethodChannel _channel;

  /// The media folder; created on first use.
  Future<Directory> folder() async {
    final base = root ?? await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> file(String name) async =>
      File(p.join((await folder()).path, name));

  Future<List<MediaItem>> list(MediaOwner owner) =>
      (_db.select(_db.mediaItems)
            ..where(
              (t) =>
                  t.ownerKind.equals(owner.kind) & t.ownerId.equals(owner.id),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();

  /// [list], updated whenever the owner's media change.
  Stream<List<MediaItem>> watch(MediaOwner owner) =>
      (_db.select(_db.mediaItems)
            ..where(
              (t) =>
                  t.ownerKind.equals(owner.kind) & t.ownerId.equals(owner.id),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .watch();

  /// Copies [paths] into the media folder and attaches them to [owner] in
  /// that order, after what is there. Returns how many were added; a file
  /// that can't be read is skipped.
  Future<int> add(
    MediaOwner owner,
    List<String> paths, {
    void Function(int done, int total)? onProgress,
    List<String?>? sourceRefs,
  }) async {
    final dir = await folder();
    var position = (await list(owner)).length;
    var added = 0;
    for (final (index, source) in paths.indexed) {
      onProgress?.call(index, paths.length);
      final video = isVideoPath(source);
      final id = const Uuid().v4();
      String path(String name) => p.join(dir.path, name);
      try {
        var name = video ? '$id.mp4' : '$id.jpg';
        Map<Object?, Object?>? meta;
        if (video) {
          if (!await _transcode(source, path(name))) {
            final ext = p.extension(source).toLowerCase();
            name = '$id${ext.isEmpty ? '.mov' : ext}';
            await File(source).copy(path(name));
          }
        } else {
          // Scaled down natively, keeping when and where it was taken.
          meta = await _native('preparePhoto', {
            'path': source,
            'out': path(name),
            'max': 2560,
          });
          if (meta == null) {
            name = '$id${_photoExtension(source)}';
            await File(source).copy(path(name));
          }
        }
        await _insert(
          owner,
          id,
          video,
          name,
          position,
          dir,
          meta,
          sourceRef: sourceRefs?[index],
        );
        position++;
        added++;
      } catch (e) {
        log('[Media] could not add ${p.basename(source)}: $e');
      }
    }
    onProgress?.call(paths.length, paths.length);
    return added;
  }

  static String _photoExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return const {
          '.jpg',
          '.jpeg',
          '.png',
          '.heic',
          '.heif',
          '.webp',
        }.contains(ext)
        ? ext
        : '.jpg';
  }

  Future<void> _insert(
    MediaOwner owner,
    String id,
    bool video,
    String name,
    int position,
    Directory dir,
    Map<Object?, Object?>? photoMeta, {
    String? sourceRef,
  }) async {
    final file = File(p.join(dir.path, name));
    final thumbName = '${id}_thumb.jpg';
    final thumb = await _native('thumbnail', {
      'path': file.path,
      'out': p.join(dir.path, thumbName),
      'video': video,
      'max': 480,
    });
    // A photo's date and place come from its original, a video's from the
    // file itself (read along with the thumbnail).
    final info = {...?thumb, ...?photoMeta};
    var width = info['width'] as int?, height = info['height'] as int?;
    if (!video && (width == null || height == null)) {
      final size = await _imageSize(file);
      width = size?.$1;
      height = size?.$2;
    }
    await _db
        .into(_db.mediaItems)
        .insert(
          MediaItemsCompanion.insert(
            id: id,
            ownerKind: owner.kind,
            ownerId: owner.id,
            ownerDate: Value(owner.date),
            ownerSport: Value(owner.sport),
            kind: video ? 'video' : 'photo',
            fileName: name,
            thumbName: Value(thumb == null ? null : thumbName),
            bytes: Value(await file.length()),
            width: Value(width),
            height: Value(height),
            durationMs: Value(info['durationMs'] as int?),
            takenAt: Value(switch (info['takenAt']) {
              final int ms => DateTime.fromMillisecondsSinceEpoch(
                ms,
                isUtc: true,
              ),
              _ => null,
            }),
            latitude: Value((info['lat'] as num?)?.toDouble()),
            longitude: Value((info['lng'] as num?)?.toDouble()),
            position: position,
            createdAt: DateTime.now(),
            sourceRef: Value(sourceRef),
          ),
        );
  }

  /// The source references already stored that start with [prefix], e.g.
  /// every `strava:` photo, so an import adds each file once.
  Future<Set<String>> sourceRefs(String prefix) async => {
    for (final m in await (_db.select(
      _db.mediaItems,
    )..where((t) => t.sourceRef.like('$prefix%'))).get())
      ?m.sourceRef,
  };

  Future<bool> _transcode(String source, String target) async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('transcodeVideo', {
            'path': source,
            'out': target,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      log('[Media] video conversion failed: ${e.message}');
      return false;
    }
  }

  /// A native media call (iOS); null elsewhere or when it fails.
  Future<Map<Object?, Object?>?> _native(
    String method,
    Map<String, Object?> args,
  ) async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      log('[Media] $method failed: ${e.message}');
      return null;
    }
  }

  static Future<(int, int)?> _imageSize(File file) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        await file.readAsBytes(),
      );
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  /// Removes the item and its files.
  Future<void> delete(MediaItem item) async {
    await (_db.delete(_db.mediaItems)..where((t) => t.id.equals(item.id))).go();
    await _deleteFiles(item);
    await _renumber(MediaOwner(item.ownerKind, item.ownerId));
  }

  /// Removes all media of [owner], e.g. when its activity is deleted.
  Future<void> deleteAll(MediaOwner owner) async {
    final items = await list(owner);
    await (_db.delete(_db.mediaItems)..where(
          (t) => t.ownerKind.equals(owner.kind) & t.ownerId.equals(owner.id),
        ))
        .go();
    for (final item in items) {
      await _deleteFiles(item);
    }
  }

  Future<void> _deleteFiles(MediaItem item) async {
    for (final name in [item.fileName, ?item.thumbName]) {
      final f = await file(name);
      if (await f.exists()) await f.delete();
    }
  }

  /// Moves [item] by [offset] places among its owner's media.
  Future<void> move(MediaItem item, int offset) async {
    final items = await list(MediaOwner(item.ownerKind, item.ownerId));
    final from = items.indexWhere((i) => i.id == item.id);
    final to = (from + offset).clamp(0, items.length - 1);
    if (from < 0 || from == to) return;
    items.insert(to, items.removeAt(from));
    await _db.transaction(() async {
      for (final (index, i) in items.indexed) {
        await (_db.update(_db.mediaItems)..where((t) => t.id.equals(i.id)))
            .write(MediaItemsCompanion(position: Value(index)));
      }
    });
  }

  Future<void> _renumber(MediaOwner owner) async {
    final items = await list(owner);
    for (final (index, i) in items.indexed) {
      if (i.position == index) continue;
      await (_db.update(_db.mediaItems)..where((t) => t.id.equals(i.id))).write(
        MediaItemsCompanion(position: Value(index)),
      );
    }
  }

  /// Media of planned sessions that a new plan replaced: moved to the session
  /// now planned on the same day (same sport first). Media of a day without
  /// a session stays and moves once one is planned there again.
  Future<int> reattachSessionMedia() async {
    final media = await (_db.select(
      _db.mediaItems,
    )..where((t) => t.ownerKind.equals('session'))).get();
    if (media.isEmpty) return 0;
    final ids = media.map((m) => m.ownerId).toSet();
    final existing = (await (_db.select(
      _db.trainingSessions,
    )..where((t) => t.id.isIn(ids))).get()).map((s) => s.id).toSet();
    var moved = 0;
    for (final item in media) {
      final date = item.ownerDate;
      if (existing.contains(item.ownerId) || date == null) continue;
      final local = date.toLocal();
      final from = DateTime(local.year, local.month, local.day);
      final sessions =
          await (_db.select(_db.trainingSessions)..where(
                (t) =>
                    t.sessionDate.isBiggerOrEqualValue(from) &
                    t.sessionDate.isSmallerThanValue(
                      from.add(const Duration(days: 1)),
                    ),
              ))
              .get();
      if (sessions.isEmpty) continue;
      final target =
          sessions.where((s) => s.sport == item.ownerSport).firstOrNull ??
          sessions.first;
      final count = (await list(MediaOwner('session', target.id))).length;
      await (_db.update(
        _db.mediaItems,
      )..where((t) => t.id.equals(item.id))).write(
        MediaItemsCompanion(
          ownerId: Value(target.id),
          ownerDate: Value(target.sessionDate),
          ownerSport: Value(target.sport),
          position: Value(count),
        ),
      );
      moved++;
    }
    return moved;
  }
}
