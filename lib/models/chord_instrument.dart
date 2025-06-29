/// Enum for different chord instrument types
enum ChordInstrument {
  guitar,
  ukulele,
  piano,
}

extension ChordInstrumentExtension on ChordInstrument {
  /// Display name for the instrument
  String get displayName {
    switch (this) {
      case ChordInstrument.guitar:
        return 'Guitar';
      case ChordInstrument.ukulele:
        return 'Ukulele';
      case ChordInstrument.piano:
        return 'Piano';
    }
  }

  /// Icon for the instrument
  String get icon {
    switch (this) {
      case ChordInstrument.guitar:
        return '🎸';
      case ChordInstrument.ukulele:
        return '🎺'; // Using trumpet as closest emoji
      case ChordInstrument.piano:
        return '🎹';
    }
  }

  /// Number of strings for string instruments
  int? get stringCount {
    switch (this) {
      case ChordInstrument.guitar:
        return 6;
      case ChordInstrument.ukulele:
        return 4;
      case ChordInstrument.piano:
        return null; // Piano doesn't have strings
    }
  }
}
