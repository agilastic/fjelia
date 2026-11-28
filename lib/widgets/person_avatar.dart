import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A person's photo in a circle, or their initials when they set none.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.photo,
    this.radius = 20,
  });

  final String name;
  final Uint8List? photo;
  final double radius;

  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return CircleAvatar(
      radius: radius,
      backgroundImage: photo == null ? null : MemoryImage(photo),
      child: photo == null
          ? Text(_initials, style: TextStyle(fontSize: radius * 0.8))
          : null,
    );
  }
}
