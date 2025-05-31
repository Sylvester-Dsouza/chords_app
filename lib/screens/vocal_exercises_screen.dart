import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/inner_screen_app_bar.dart';
import 'vocal_exercise_player_screen.dart';

class VocalExercisesScreen extends StatefulWidget {
  const VocalExercisesScreen({super.key});

  @override
  State<VocalExercisesScreen> createState() => _VocalExercisesScreenState();
}

class _VocalExercisesScreenState extends State<VocalExercisesScreen> {
  String selectedCategory = 'All';
  String selectedDifficulty = 'All';
  String searchQuery = '';

  final List<String> categories = [
    'All',
    'Breathing',
    'Scales',
    'Range',
    'Agility',
    'Classical',
    'Contemporary',
    'Worship',
  ];

  final List<String> difficulties = ['All', 'Easy', 'Medium', 'Pro'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Custom App Bar
          InnerScreenAppBar(
            title: 'Vocal Exercises',
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Search and Filters
                _buildSearchAndFilters(),

                // Category Tabs
                _buildCategoryTabs(),

                // Exercise List
                Expanded(
                  child: _buildExercisesList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vocal Exercises',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getFilteredExercises().length} exercises available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Enhanced Search Bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: AppTheme.primaryFontFamily,
              ),
              decoration: InputDecoration(
                hintText: 'Search for breathing, scales, range...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 22,
                  ),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.clear_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Enhanced Difficulty Filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by difficulty',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: difficulties.map((difficulty) {
                    final isSelected = selectedDifficulty == difficulty;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDifficulty = difficulty;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getDifficultyColor(difficulty).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _getDifficultyColor(difficulty).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _getDifficultyColor(difficulty),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                difficulty,
                                style: TextStyle(
                                  color: isSelected
                                      ? _getDifficultyColor(difficulty)
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.primaryFontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse by category',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    final exercises = _getFilteredExercises();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (exercise['color'] as Color).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openExercisePlayer(exercise),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Enhanced Exercise Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (exercise['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (exercise['color'] as Color).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      exercise['emoji'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Enhanced Exercise Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['title'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise['description'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Enhanced Duration Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (exercise['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (exercise['color'] as Color).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: exercise['color'] as Color,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${exercise['duration']}m',
                                  style: TextStyle(
                                    color: exercise['color'] as Color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppTheme.primaryFontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Enhanced Difficulty Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(exercise['difficulty'] as String).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getDifficultyColor(exercise['difficulty'] as String).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              exercise['difficulty'] as String,
                              style: TextStyle(
                                color: _getDifficultyColor(exercise['difficulty'] as String),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exercise['category'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.primaryFontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Enhanced Play Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (exercise['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (exercise['color'] as Color).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: exercise['color'] as Color,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredExercises() {
    final allExercises = [
      // Breathing Exercises
      {
        'title': 'Diaphragmatic Breathing',
        'description': 'Master the foundation of vocal support 💪',
        'category': 'Breathing',
        'difficulty': 'Easy',
        'duration': 3,
        'color': const Color(0xFF6366F1),
        'emoji': '🫁',
        'type': 'breathing',
      },
      {
        'title': '4-7-8 Breath Control',
        'description': 'Calm your nerves and improve control 🧘‍♀️',
        'category': 'Breathing',
        'difficulty': 'Easy',
        'duration': 4,
        'color': const Color(0xFF06B6D4),
        'emoji': '🌬️',
        'type': 'breathing',
      },
      {
        'title': 'Sustained Breath Hold',
        'description': 'Build endurance for long phrases 💨',
        'category': 'Breathing',
        'difficulty': 'Medium',
        'duration': 5,
        'color': const Color(0xFF0EA5E9),
        'emoji': '⏱️',
        'type': 'breathing',
      },

      // Classical Scales
      {
        'title': 'Do-Re-Mi Major Scale',
        'description': 'Classic solfege training for pitch accuracy 🎼',
        'category': 'Classical',
        'difficulty': 'Easy',
        'duration': 4,
        'color': const Color(0xFF8B5CF6),
        'emoji': '🎼',
        'type': 'scales',
      },
      {
        'title': 'Chromatic Scale Exercise',
        'description': 'Half-step precision training 🎯',
        'category': 'Classical',
        'difficulty': 'Medium',
        'duration': 6,
        'color': const Color(0xFF7C3AED),
        'emoji': '🎯',
        'type': 'scales',
      },
      {
        'title': 'Arpeggios (Broken Chords)',
        'description': 'Classical vocal agility training 🎪',
        'category': 'Classical',
        'difficulty': 'Pro',
        'duration': 8,
        'color': const Color(0xFF6D28D9),
        'emoji': '🎪',
        'type': 'scales',
      },

      // Range Development
      {
        'title': 'Vocal Sirens',
        'description': 'Smooth glides to expand your range 🌊',
        'category': 'Range',
        'difficulty': 'Easy',
        'duration': 3,
        'color': const Color(0xFF10B981),
        'emoji': '🌊',
        'type': 'range',
      },
      {
        'title': 'Octave Jumps',
        'description': 'Build strength across your range 🏃‍♀️',
        'category': 'Range',
        'difficulty': 'Medium',
        'duration': 5,
        'color': const Color(0xFF059669),
        'emoji': '🏃‍♀️',
        'type': 'range',
      },
      {
        'title': 'Head Voice Development',
        'description': 'Strengthen your upper register 👑',
        'category': 'Range',
        'difficulty': 'Pro',
        'duration': 7,
        'color': const Color(0xFF047857),
        'emoji': '👑',
        'type': 'range',
      },

      // Agility & Runs
      {
        'title': 'Simple Melismas',
        'description': 'Basic vocal runs and riffs 🎵',
        'category': 'Agility',
        'difficulty': 'Medium',
        'duration': 5,
        'color': const Color(0xFFEC4899),
        'emoji': '🎵',
        'type': 'agility',
      },
      {
        'title': 'Fast Scale Runs',
        'description': 'Speed and precision training ⚡',
        'category': 'Agility',
        'difficulty': 'Pro',
        'duration': 6,
        'color': const Color(0xFFDB2777),
        'emoji': '⚡',
        'type': 'agility',
      },
      {
        'title': 'Staccato Exercises',
        'description': 'Sharp, detached note practice 🔥',
        'category': 'Agility',
        'difficulty': 'Medium',
        'duration': 4,
        'color': const Color(0xFFBE185D),
        'emoji': '🔥',
        'type': 'agility',
      },

      // Contemporary Styles
      {
        'title': 'Belt Training',
        'description': 'Powerful contemporary singing 💪',
        'category': 'Contemporary',
        'difficulty': 'Pro',
        'duration': 8,
        'color': const Color(0xFFEF4444),
        'emoji': '💪',
        'type': 'contemporary',
      },
      {
        'title': 'Mixed Voice Blending',
        'description': 'Seamless register transitions 🌈',
        'category': 'Contemporary',
        'difficulty': 'Medium',
        'duration': 6,
        'color': const Color(0xFFDC2626),
        'emoji': '🌈',
        'type': 'contemporary',
      },
      {
        'title': 'Vocal Fry Control',
        'description': 'Modern vocal texture technique 🎭',
        'category': 'Contemporary',
        'difficulty': 'Medium',
        'duration': 4,
        'color': const Color(0xFFB91C1C),
        'emoji': '🎭',
        'type': 'contemporary',
      },

      // Worship Specific
      {
        'title': 'Worship Vibrato',
        'description': 'Controlled vibrato for worship songs 🙏',
        'category': 'Worship',
        'difficulty': 'Medium',
        'duration': 5,
        'color': const Color(0xFFF59E0B),
        'emoji': '🙏',
        'type': 'worship',
      },
      {
        'title': 'Sustained Notes',
        'description': 'Hold those powerful worship moments ✨',
        'category': 'Worship',
        'difficulty': 'Easy',
        'duration': 4,
        'color': const Color(0xFFD97706),
        'emoji': '✨',
        'type': 'worship',
      },
      {
        'title': 'Harmony Training',
        'description': 'Blend with worship team vocals 🎶',
        'category': 'Worship',
        'difficulty': 'Medium',
        'duration': 6,
        'color': const Color(0xFFB45309),
        'emoji': '🎶',
        'type': 'worship',
      },

      // Additional Scales
      {
        'title': 'Minor Scale Patterns',
        'description': 'Explore emotional minor tonalities 🌙',
        'category': 'Scales',
        'difficulty': 'Easy',
        'duration': 4,
        'color': const Color(0xFF6B7280),
        'emoji': '🌙',
        'type': 'scales',
      },
      {
        'title': 'Pentatonic Scales',
        'description': 'Five-note scale mastery 🎸',
        'category': 'Scales',
        'difficulty': 'Medium',
        'duration': 5,
        'color': const Color(0xFF4B5563),
        'emoji': '🎸',
        'type': 'scales',
      },
      {
        'title': 'Modal Scales',
        'description': 'Advanced scale variations 🎨',
        'category': 'Scales',
        'difficulty': 'Pro',
        'duration': 8,
        'color': const Color(0xFF374151),
        'emoji': '🎨',
        'type': 'scales',
      },
    ];

    return allExercises.where((exercise) {
      final matchesCategory = selectedCategory == 'All' || exercise['category'] == selectedCategory;
      final matchesDifficulty = selectedDifficulty == 'All' || exercise['difficulty'] == selectedDifficulty;
      final matchesSearch = searchQuery.isEmpty ||
          exercise['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          exercise['description'].toString().toLowerCase().contains(searchQuery.toLowerCase());

      return matchesCategory && matchesDifficulty && matchesSearch;
    }).toList();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00D4AA);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'pro':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'breathing':
        return Icons.air_rounded;
      case 'scales':
        return Icons.music_note_rounded;
      case 'range':
        return Icons.trending_up_rounded;
      case 'agility':
        return Icons.speed_rounded;
      case 'classical':
        return Icons.piano_rounded;
      case 'contemporary':
        return Icons.mic_rounded;
      case 'worship':
        return Icons.favorite_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }

  void _openExercisePlayer(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisePlayerScreen(
          exercise: exercise,
        ),
      ),
    );
  }
}