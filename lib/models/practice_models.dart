/// Practice mode difficulty levels
enum PracticeDifficulty {
  beginner('Beginner', 0.5, 'Start slow and build confidence'),
  intermediate('Intermediate', 0.75, 'Moderate pace with guidance'),
  advanced('Advanced', 1.0, 'Full tempo practice'),
  master('Master', 1.25, 'Performance ready');

  const PracticeDifficulty(this.displayName, this.tempoMultiplier, this.description);
  
  final String displayName;
  final double tempoMultiplier;
  final String description;
}

/// Practice session data
class PracticeSession {
  final DateTime startTime;
  final String songId;
  final String songTitle;
  final PracticeDifficulty difficulty;
  final int originalTempo;
  final int practiceTempo;
  
  DateTime? endTime;
  int correctChordChanges = 0;
  int totalChordChanges = 0;
  List<String> sectionsPlayed = [];
  Map<String, int> chordAccuracy = {};
  List<PracticeEvent> events = [];

  PracticeSession({
    required this.startTime,
    required this.songId,
    required this.songTitle,
    required this.difficulty,
    required this.originalTempo,
    required this.practiceTempo,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  
  double get accuracy => totalChordChanges > 0 ? correctChordChanges / totalChordChanges : 0.0;
  
  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'songId': songId,
    'songTitle': songTitle,
    'difficulty': difficulty.name,
    'originalTempo': originalTempo,
    'practiceTempo': practiceTempo,
    'correctChordChanges': correctChordChanges,
    'totalChordChanges': totalChordChanges,
    'sectionsPlayed': sectionsPlayed,
    'chordAccuracy': chordAccuracy,
    'events': events.map((e) => e.toJson()).toList(),
  };
}

/// Practice event for detailed tracking
class PracticeEvent {
  final DateTime timestamp;
  final PracticeEventType type;
  final String? chord;
  final String? section;
  final Map<String, dynamic>? data;

  PracticeEvent({
    required this.timestamp,
    required this.type,
    this.chord,
    this.section,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'chord': chord,
    'section': section,
    'data': data,
  };
}

enum PracticeEventType {
  sessionStart,
  sessionEnd,
  chordChange,
  sectionChange,
  tempoChange,
  mistake,
  achievement,
}

/// Chord transition data for analysis
class ChordTransition {
  final String fromChord;
  final String toChord;
  final Duration timing;
  final bool wasCorrect;
  final DateTime timestamp;

  ChordTransition({
    required this.fromChord,
    required this.toChord,
    required this.timing,
    required this.wasCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'fromChord': fromChord,
    'toChord': toChord,
    'timing': timing.inMilliseconds,
    'wasCorrect': wasCorrect,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Practice achievement
class PracticeAchievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final DateTime unlockedAt;
  final Map<String, dynamic>? metadata;

  PracticeAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconName': iconName,
    'unlockedAt': unlockedAt.toIso8601String(),
    'metadata': metadata,
  };
}

/// Practice statistics
class PracticeStats {
  final String songId;
  final int totalSessions;
  final Duration totalPracticeTime;
  final double averageAccuracy;
  final int bestTempo;
  final List<PracticeDifficulty> masteredDifficulties;
  final Map<String, double> sectionMastery;
  final Map<String, int> chordMastery;
  final DateTime lastPracticed;
  final DateTime firstPracticed;

  PracticeStats({
    required this.songId,
    required this.totalSessions,
    required this.totalPracticeTime,
    required this.averageAccuracy,
    required this.bestTempo,
    required this.masteredDifficulties,
    required this.sectionMastery,
    required this.chordMastery,
    required this.lastPracticed,
    required this.firstPracticed,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'totalSessions': totalSessions,
    'totalPracticeTime': totalPracticeTime.inMilliseconds,
    'averageAccuracy': averageAccuracy,
    'bestTempo': bestTempo,
    'masteredDifficulties': masteredDifficulties.map((d) => d.name).toList(),
    'sectionMastery': sectionMastery,
    'chordMastery': chordMastery,
    'lastPracticed': lastPracticed.toIso8601String(),
    'firstPracticed': firstPracticed.toIso8601String(),
  };
}

/// Practice goal
class PracticeGoal {
  final String id;
  final String title;
  final String description;
  final PracticeGoalType type;
  final Map<String, dynamic> target;
  final Map<String, dynamic> current;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isActive;

  PracticeGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.current,
    required this.createdAt,
    this.completedAt,
    this.isActive = true,
  });

  double get progress {
    switch (type) {
      case PracticeGoalType.tempo:
        final targetTempo = target['tempo'] as int;
        final currentTempo = current['tempo'] as int? ?? 0;
        return (currentTempo / targetTempo).clamp(0.0, 1.0);
      case PracticeGoalType.accuracy:
        final targetAccuracy = target['accuracy'] as double;
        final currentAccuracy = current['accuracy'] as double? ?? 0.0;
        return (currentAccuracy / targetAccuracy).clamp(0.0, 1.0);
      case PracticeGoalType.sessions:
        final targetSessions = target['sessions'] as int;
        final currentSessions = current['sessions'] as int? ?? 0;
        return (currentSessions / targetSessions).clamp(0.0, 1.0);
      case PracticeGoalType.time:
        final targetMinutes = target['minutes'] as int;
        final currentMinutes = current['minutes'] as int? ?? 0;
        return (currentMinutes / targetMinutes).clamp(0.0, 1.0);
    }
  }

  bool get isCompleted => progress >= 1.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'target': target,
    'current': current,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'isActive': isActive,
  };
}

enum PracticeGoalType {
  tempo,
  accuracy,
  sessions,
  time,
}
