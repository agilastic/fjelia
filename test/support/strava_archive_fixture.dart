import 'dart:io';

import 'package:archive/archive_io.dart';

import 'coros_fit_fixture.dart';

/// A Strava "Download your account" ZIP in miniature, with German headers
/// as Strava writes them for a German account.
String _csv(List<List<String>> rows) {
  final header = List.generate(104, (i) => 'Spalte $i');
  header[0] = 'Aktivitäts-ID';
  header[102] = 'Medien';
  String q(String v) =>
      v.contains(RegExp(r'[,"\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
  return [
    header.map(q).join(','),
    for (final r in rows) r.map(q).join(','),
  ].join('\n');
}

List<String> _row({
  required String id,
  required String date,
  required String type,
  required int seconds,
  String name = 'Lauf',
  String file = '',
  String media = '',
  String description = '',
}) {
  final r = List.filled(104, '');
  r[0] = id;
  r[1] = date;
  r[2] = name;
  r[3] = type;
  r[4] = description;
  r[12] = file;
  r[15] = '$seconds.0';
  r[16] = '${seconds - 10}.0';
  r[17] = '3000.0';
  r[18] = '3.85';
  r[34] = '136.0';
  r[20] = '12.0';
  r[30] = '160.0';
  r[31] = '140.0';
  r[102] = media;
  return r;
}

String writeStravaArchive(Directory dir) {
  final fit = corosStyleFit(); // a walk on 3 Nov 2026 17:44 UTC
  final zip = Archive()
    ..addFile(
      ArchiveFile.string(
        'activities.csv',
        _csv([
          _row(
            id: '111',
            date: '03.11.2026, 17:44:00',
            type: 'Spaziergang',
            seconds: 120,
            name: 'Abendrunde, "kurz"',
            file: 'activities/9001.fit.gz',
            media: 'media/a.jpg|media/b.jpg',
            description: 'zwei\nZeilen',
          ),
          // The same ride a Garmin sync already brought.
          _row(
            id: '222',
            date: '01.11.2026, 08:00:00',
            type: 'Radfahrt',
            seconds: 3600,
            media: 'media/c.jpg',
          ),
          // Deleted in Fjelia before.
          _row(
            id: '333',
            date: '30.10.2026, 07:00:00',
            type: 'Lauf',
            seconds: 1800,
          ),
          // Strava's placeholder date: the start comes from the file.
          _row(
            id: '444',
            date: '01.01.1970, 00:00:00',
            type: 'Lauf',
            seconds: 120,
            file: 'activities/9001.fit.gz',
          ),
        ]),
      ),
    )
    ..addFile(
      ArchiveFile.bytes(
        'activities/9001.fit.gz',
        const GZipEncoder().encodeBytes(fit),
      ),
    )
    ..addFile(ArchiveFile.bytes('media/a.jpg', [0xFF, 0xD8, 1, 2]))
    ..addFile(ArchiveFile.bytes('media/b.jpg', [0xFF, 0xD8, 3, 4]))
    ..addFile(ArchiveFile.bytes('media/c.jpg', [0xFF, 0xD8, 5, 6]));
  final path = '${dir.path}/export_1.zip';
  File(path).writeAsBytesSync(ZipEncoder().encodeBytes(zip));
  return path;
}
