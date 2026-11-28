import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/race_library.dart';

/// races.fjelia.com typeahead for race names in the race goal editor.
final raceLibraryProvider = Provider<RaceLibrary>((ref) => httpRaceLibrary());
