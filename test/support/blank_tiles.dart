import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Map tiles for tests: one blank pixel, nothing from the internet.
class BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGPYcunOfwAI'
          'AgNiJBgw5wAAAABJRU5ErkJggg==',
        ),
      );
}
