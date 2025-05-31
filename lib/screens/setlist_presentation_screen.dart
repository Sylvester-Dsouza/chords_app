import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../services/song_service.dart';
import '../widgets/skeleton_loader.dart';

class SetlistPresentationScreen extends StatefulWidget {
  final String setlistName;
  final List<Map<String, dynamic>> songs;

  const SetlistPresentationScreen({
    super.key,
    required this.setlistName,
    required this.songs,
  });

  @override
  State<SetlistPresentationScreen> createState() => _SetlistPresentationScreenState();
}

class _SetlistPresentationScreenState extends State<SetlistPresentationScreen> {
  int _currentSongIndex = 0;
  int _currentSectionIndex = 0;
  bool _showControls = true;
  bool _showChords = true;
  double _fontSize = 24.0;

  // Color customization options
  int _backgroundThemeIndex = 0;
  int _textColorIndex = 0;

  // Parsed sections for current song
  List<PresentationSection> _sections = [];

  // View mode: 'setlist' shows song names, 'song' shows individual song sections
  String _viewMode = 'setlist'; // 'setlist' or 'song'

  // Loading state for song details
  bool _isLoadingSong = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _parseCurrentSong();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Get current song
  Map<String, dynamic> get _currentSong => widget.songs[_currentSongIndex];

  // Parse current song into sections
  void _parseCurrentSong() {
    final song = _currentSong;
    final String lyrics = song['lyrics'] ?? '';
    final String chords = song['chords'] ?? '';

    setState(() {
      _sections = _parseSongContent(lyrics, chords, song);
      _currentSectionIndex = 0;
    });
  }

  // Navigate to next song
  void _nextSong() {
    if (_currentSongIndex < widget.songs.length - 1) {
      setState(() {
        _currentSongIndex++;
        _parseCurrentSong();
      });
    }
  }

  // Navigate to previous song
  void _previousSong() {
    if (_currentSongIndex > 0) {
      setState(() {
        _currentSongIndex--;
        _parseCurrentSong();
      });
    }
  }

  // Navigate to next section
  void _nextSection() {
    if (_currentSectionIndex < _sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
      });
    } else {
      // If at last section, go to next song
      _nextSong();
    }
  }

  // Navigate to previous section
  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
    } else {
      // If at first section, go to previous song
      _previousSong();
    }
  }



  // Enter song view for specific song
  void _enterSongView(int songIndex) async {
    setState(() {
      _currentSongIndex = songIndex;
      _viewMode = 'song';
    });

    // Fetch full song details if needed
    await _loadSongDetails(songIndex);

    // Parse the song after loading details
    _parseCurrentSong();
  }

  // Return to setlist view
  void _returnToSetlistView() {
    setState(() {
      _viewMode = 'setlist';
    });
  }

  // Load full song details including chord sheet
  Future<void> _loadSongDetails(int songIndex) async {
    try {
      final song = widget.songs[songIndex];
      final songId = song['id'];

      if (songId == null) {
        debugPrint('Song ID is null for song at index $songIndex');
        return;
      }

      debugPrint('Loading full details for song: ${song['title']} (ID: $songId)');

      // Check if song already has chord sheet data
      if (song['chords'] != null && song['chords'].toString().isNotEmpty) {
        debugPrint('Song already has chord data, skipping fetch');
        return;
      }

      // Set loading state
      setState(() {
        _isLoadingSong = true;
      });

      // Fetch full song details from API
      final songService = SongService();
      final fullSong = await songService.getSongById(songId);

      debugPrint('Successfully loaded full song details');
      debugPrint('Chord sheet length: ${fullSong.chords?.length ?? 0}');

      // Update the song in the list with full details
      setState(() {
        widget.songs[songIndex] = {
          ...song,
          'chords': fullSong.chords ?? '',
          'lyrics': fullSong.lyrics ?? fullSong.chords ?? '', // Use lyrics or chord sheet as fallback
          'key': fullSong.key,
          'capo': fullSong.capo,
          'tempo': fullSong.tempo,
          'timeSignature': fullSong.timeSignature,
        };
        _isLoadingSong = false;
      });

      debugPrint('Updated song data in widget.songs');
    } catch (e) {
      debugPrint('Error loading song details: $e');
      setState(() {
        _isLoadingSong = false;
      });
      // Don't throw error, just continue with existing data
    }
  }

  // Background theme options
  List<List<Color>> get _backgroundThemes => [
    // 0: Dark Black Gradient (Default)
    [
      const Color(0xFF1a1a1a), // Dark grey
      const Color(0xFF0d0d0d), // Darker grey
      const Color(0xFF000000), // Pure black
    ],
    // 1: Deep Blue Gradient
    [
      const Color(0xFF1a237e), // Deep indigo
      const Color(0xFF0d47a1), // Deep blue
      const Color(0xFF000051), // Very dark blue
    ],
    // 2: Purple Gradient
    [
      const Color(0xFF4a148c), // Deep purple
      const Color(0xFF2d1b69), // Dark purple
      const Color(0xFF1a0033), // Very dark purple
    ],
    // 3: Warm Gradient
    [
      const Color(0xFF3e2723), // Dark brown
      const Color(0xFF1c1c1c), // Dark grey
      const Color(0xFF000000), // Black
    ],
    // 4: Pure Black
    [
      const Color(0xFF000000), // Pure black
      const Color(0xFF000000), // Pure black
      const Color(0xFF000000), // Pure black
    ],
  ];

  // Text color options
  List<Color> get _textColors => [
    Colors.white,           // 0: White (Default)
    Colors.grey[300]!,      // 1: Light grey
    Colors.blue[100]!,      // 2: Light blue
    Colors.green[100]!,     // 3: Light green
    Colors.yellow[100]!,    // 4: Light yellow
    Colors.orange[100]!,    // 5: Light orange
  ];

  // Build beautiful background decoration
  BoxDecoration _buildBackgroundDecoration() {
    final theme = _backgroundThemes[_backgroundThemeIndex];

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme,
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  // Get current text color
  Color get _currentTextColor => _textColors[_textColorIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _previousSection();
              } else if (details.primaryVelocity! < 0) {
                _nextSection();
              }
            },
            child: Stack(
              children: [
                // Main content
                _buildMainContent(),

                // Top controls
                if (_showControls) _buildTopControls(),

                // Bottom navigation
                if (_showControls) _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_viewMode == 'setlist') {
      return _buildSetlistView();
    } else {
      return _buildSongView();
    }
  }

  Widget _buildSetlistView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Setlist title
            Text(
              widget.setlistName,
              style: TextStyle(
                color: _currentTextColor,
                fontSize: _fontSize + 16,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Song count
            Text(
              '${widget.songs.length} Songs',
              style: TextStyle(
                color: _currentTextColor.withValues(alpha: 0.7),
                fontSize: _fontSize,
                fontFamily: AppTheme.primaryFontFamily,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Instructions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _currentTextColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: _currentTextColor.withValues(alpha: 0.7),
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap a song below to view its chords and lyrics',
                    style: TextStyle(
                      color: _currentTextColor.withValues(alpha: 0.8),
                      fontSize: _fontSize - 2,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build loading skeleton for presentation
  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Song title skeleton
          ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              width: 300,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Content skeleton
          ShimmerEffect(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Column(
              children: [
                // Multiple lines of content skeleton
                for (int i = 0; i < 8; i++) ...[
                  Container(
                    width: double.infinity,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Loading text
          Text(
            'Loading song details...',
            style: TextStyle(
              color: _currentTextColor,
              fontSize: _fontSize,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongView() {
    if (_isLoadingSong) {
      return _buildLoadingSkeleton();
    }

    if (_sections.isEmpty) {
      return const Center(
        child: Text(
          'No content available',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      );
    }

    final section = _sections[_currentSectionIndex];
    return _buildSectionSlide(section);
  }

  Widget _buildSectionSlide(PresentationSection section) {
    if (section.isTitle) {
      return _buildTitleSlide(section);
    } else {
      return _buildContentSlide(section);
    }
  }

  Widget _buildTitleSlide(PresentationSection section) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Song title
            Text(
              section.content,
              style: TextStyle(
                color: _currentTextColor,
                fontSize: _fontSize + 12, // Larger title
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            // Artist name
            if (section.subtitle != null) ...[
              const SizedBox(height: 20),
              Text(
                section.subtitle!,
                style: TextStyle(
                  color: _currentTextColor.withValues(alpha: 0.7),
                  fontSize: _fontSize + 2,
                  fontFamily: AppTheme.primaryFontFamily,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Metadata (key, difficulty, etc.)
            if (section.metadata != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  section.metadata!,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: _fontSize - 2,
                    fontFamily: AppTheme.primaryFontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentSlide(PresentationSection section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Column(
        children: [
          // Section title - smaller and more subtle
          if (section.title != null && section.title!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                section.title!,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: _fontSize - 6,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.primaryFontFamily,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section content - centered in remaining space
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: _buildFormattedContent(section.content),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Close button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),

            const Spacer(),

            // Background color picker
            IconButton(
              icon: const Icon(Icons.palette, color: Colors.white, size: 24),
              onPressed: () {
                setState(() {
                  _backgroundThemeIndex = (_backgroundThemeIndex + 1) % _backgroundThemes.length;
                });
              },
            ),

            // Text color picker
            IconButton(
              icon: Icon(Icons.format_color_text, color: _currentTextColor, size: 24),
              onPressed: () {
                setState(() {
                  _textColorIndex = (_textColorIndex + 1) % _textColors.length;
                });
              },
            ),

            // Font size controls
            IconButton(
              icon: const Icon(Icons.text_decrease, color: Colors.white, size: 24),
              onPressed: () {
                setState(() {
                  _fontSize = (_fontSize - 2).clamp(16.0, 36.0);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.text_increase, color: Colors.white, size: 24),
              onPressed: () {
                setState(() {
                  _fontSize = (_fontSize + 2).clamp(16.0, 36.0);
                });
              },
            ),

            const Spacer(),

            // View mode indicator and counter
            if (_viewMode == 'setlist') ...[
              Text(
                'Setlist View',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ] else ...[
              Text(
                '${_currentSongIndex + 1} of ${widget.songs.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],

            const Spacer(),

            // Chord toggle
            IconButton(
              icon: Icon(
                _showChords ? Icons.music_note : Icons.music_off,
                color: _showChords ? AppTheme.primaryColor : Colors.white,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _showChords = !_showChords;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (_viewMode == 'setlist') {
      return _buildSongNavigation();
    } else {
      return _buildSectionNavigation();
    }
  }

  Widget _buildSongNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          border: const Border(
            top: BorderSide(
              color: Color(0x20FFFFFF),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Song names row
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.songs.length,
                itemBuilder: (context, index) {
                  final song = widget.songs[index];
                  final isActive = index == _currentSongIndex;
                  final songTitle = song['title'] ?? 'Unknown Song';

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => _enterSongView(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryColor
                                : Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            songTitle,
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Navigation controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous song button
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: _currentSongIndex > 0 ? Colors.white : Colors.white30,
                    size: 32,
                  ),
                  onPressed: _currentSongIndex > 0 ? _previousSong : null,
                ),

                // View current song button (just highlights, doesn't switch)
                IconButton(
                  icon: const Icon(Icons.visibility, color: AppTheme.primaryColor, size: 28),
                  onPressed: () {
                    // Just scroll to current song in the list, don't enter song view
                    // The user needs to tap on a specific song to enter song view
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tap on "${widget.songs[_currentSongIndex]['title']}" below to view its chords'),
                        backgroundColor: const Color(0xFF1E1E1E),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // Next song button
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: _currentSongIndex < widget.songs.length - 1 ? Colors.white : Colors.white30,
                    size: 32,
                  ),
                  onPressed: _currentSongIndex < widget.songs.length - 1 ? _nextSong : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          border: const Border(
            top: BorderSide(
              color: Color(0x20FFFFFF),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section tags row
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  final isActive = index == _currentSectionIndex;
                  final isTitle = section.isTitle;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => _jumpToSection(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryColor
                                : Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isTitle ? 'TITLE' : (section.title ?? 'SECTION'),
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Navigation controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous section button
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: _currentSectionIndex > 0 ? Colors.white : Colors.white30,
                    size: 32,
                  ),
                  onPressed: _currentSectionIndex > 0 ? _previousSection : null,
                ),

                // Back to setlist button
                IconButton(
                  icon: const Icon(Icons.list, color: AppTheme.primaryColor, size: 28),
                  onPressed: _returnToSetlistView,
                ),

                // Next section button
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: _currentSectionIndex < _sections.length - 1 ? Colors.white : Colors.white30,
                    size: 32,
                  ),
                  onPressed: _currentSectionIndex < _sections.length - 1 ? _nextSection : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Jump to specific section
  void _jumpToSection(int index) {
    setState(() {
      _currentSectionIndex = index;
    });
  }

  Widget _buildFormattedContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Check if line contains chords
      if (line.contains('[') && line.contains(']')) {
        if (_showChords) {
          // Show chord line
          widgets.add(_buildChordLine(line));
        } else {
          // Convert chord line to lyrics only
          final lyricsOnly = _extractLyricsFromChordLine(line);
          if (lyricsOnly.trim().isNotEmpty) {
            widgets.add(_buildLyricLine(lyricsOnly));
          }
        }
      } else {
        // Regular lyric line
        widgets.add(_buildLyricLine(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets,
    );
  }

  // Extract lyrics from a chord line, removing chord annotations
  String _extractLyricsFromChordLine(String chordLine) {
    // Remove chord annotations in brackets [G], [Am], etc.
    String result = chordLine.replaceAll(RegExp(r'\[[^\]]*\]'), '');

    // Clean up multiple spaces and trim
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }



  Widget _buildChordLine(String line) {
    // Parse the line to separate chords and lyrics
    final spans = <TextSpan>[];
    final regex = RegExp(r'\[([^\]]+)\]');
    final matches = regex.allMatches(line);

    if (matches.isEmpty) {
      // No chords found, treat as regular lyric line
      return _buildLyricLine(line);
    }

    int lastEnd = 0;

    // Process the line character by character, inserting chords above lyrics
    for (final match in matches) {
      // Add any text before this chord
      if (match.start > lastEnd) {
        final beforeText = line.substring(lastEnd, match.start);
        if (beforeText.isNotEmpty) {
          spans.add(TextSpan(
            text: beforeText,
            style: TextStyle(
              color: _currentTextColor,
              fontSize: _fontSize,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ));
        }
      }

      // Add the chord with special styling
      final chord = match.group(1)!;
      spans.add(TextSpan(
        text: '[$chord]',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: _fontSize - 2,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ));

      lastEnd = match.end;
    }

    // Add any remaining text after the last chord
    if (lastEnd < line.length) {
      final remainingText = line.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: TextStyle(
            color: _currentTextColor,
            fontSize: _fontSize,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildLyricLine(String line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        line,
        style: TextStyle(
          color: _currentTextColor,
          fontSize: _fontSize,
          fontFamily: AppTheme.primaryFontFamily,
          height: 1.5, // Increased line height for better readability
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<PresentationSection> _parseSongContent(String lyrics, String chords, Map<String, dynamic> song) {
    final List<PresentationSection> sections = [];

    // Add title section
    sections.add(PresentationSection(
      content: song['title'] ?? 'Unknown Song',
      subtitle: 'by ${song['artist'] ?? 'Unknown Artist'}',
      metadata: _buildMetadata(song),
      isTitle: true,
    ));

    // Debug: Print available content
    debugPrint('Song: ${song['title']}');
    debugPrint('Chords available: ${chords.isNotEmpty}');
    debugPrint('Lyrics available: ${lyrics.isNotEmpty}');
    if (chords.isNotEmpty) {
      debugPrint('Chords content: ${chords.substring(0, chords.length > 100 ? 100 : chords.length)}...');
    }
    if (lyrics.isNotEmpty) {
      debugPrint('Lyrics content: ${lyrics.substring(0, lyrics.length > 100 ? 100 : lyrics.length)}...');
    }

    // Parse the chord sheet content (prefer chords over lyrics)
    String content = '';
    if (chords.isNotEmpty) {
      content = chords;
      debugPrint('Using chords for content');
    } else if (lyrics.isNotEmpty) {
      content = lyrics;
      debugPrint('Using lyrics for content');
    }

    if (content.isEmpty) {
      debugPrint('No content available, adding fallback section');
      sections.add(PresentationSection(
        title: 'Song Information',
        content: 'This song is in your setlist but doesn\'t have chord sheet or lyrics data loaded.\n\nTo fix this:\n• Open the song individually to load its content\n• Check if the song has chords/lyrics in the database\n• Contact support if the issue persists\n\nSong: ${song['title']}\nArtist: ${song['artist']}',
      ));
      return sections;
    }

    // Parse chord sheet into sections
    final parsedSections = _parseChordSheet(content);
    debugPrint('Parsed ${parsedSections.length} sections from content');
    sections.addAll(parsedSections);

    return sections;
  }

  String _buildMetadata(Map<String, dynamic> song) {
    final List<String> metadata = [];

    if (song['key'] != null && song['key'].toString().isNotEmpty) {
      metadata.add('Key: ${song['key']}');
    }

    if (song['capo'] != null && song['capo'].toString() != '0') {
      metadata.add('Capo: ${song['capo']}');
    }

    if (song['tempo'] != null && song['tempo'].toString().isNotEmpty) {
      metadata.add('Tempo: ${song['tempo']}');
    }

    if (song['timeSignature'] != null && song['timeSignature'].toString().isNotEmpty) {
      metadata.add('Time: ${song['timeSignature']}');
    }

    return metadata.isNotEmpty ? metadata.join(' • ') : '';
  }

  List<PresentationSection> _parseChordSheet(String chordSheet) {
    final sections = <PresentationSection>[];

    // Split by lines and process line by line to find sections
    final lines = chordSheet.split('\n');
    String currentSectionName = '';
    List<String> currentSectionLines = [];

    for (String line in lines) {
      final trimmedLine = line.trim();

      // Check if line contains a section marker {section_name}
      final sectionMatch = RegExp(r'\{([^}]+)\}').firstMatch(trimmedLine);

      if (sectionMatch != null) {
        // Save previous section if it has content
        if (currentSectionLines.isNotEmpty && currentSectionName.isNotEmpty) {
          sections.add(PresentationSection(
            title: _formatSectionTitle(currentSectionName),
            content: currentSectionLines.join('\n').trim(),
          ));
        }

        // Start new section
        currentSectionName = sectionMatch.group(1)!.trim();
        currentSectionLines.clear();

        // Check if there's content on the same line after the section marker
        final remainingContent = trimmedLine.substring(sectionMatch.end).trim();
        if (remainingContent.isNotEmpty) {
          currentSectionLines.add(remainingContent);
        }
      } else if (currentSectionName.isNotEmpty) {
        // Add content line to current section
        if (trimmedLine.isNotEmpty || currentSectionLines.isNotEmpty) {
          currentSectionLines.add(line); // Keep original spacing
        }
      } else if (trimmedLine.isNotEmpty) {
        // Content before any section marker - treat as intro or first section
        if (currentSectionName.isEmpty) {
          currentSectionName = 'intro';
        }
        currentSectionLines.add(line);
      }
    }

    // Add final section if it has content
    if (currentSectionLines.isNotEmpty && currentSectionName.isNotEmpty) {
      sections.add(PresentationSection(
        title: _formatSectionTitle(currentSectionName),
        content: currentSectionLines.join('\n').trim(),
      ));
    }

    // If no sections were created, add a fallback
    if (sections.isEmpty) {
      sections.add(PresentationSection(
        title: 'Song Content',
        content: chordSheet.trim(),
      ));
    }

    return sections;
  }

  // Format section title for display
  String _formatSectionTitle(String sectionName) {
    // Convert to title case and handle common section names
    final formatted = sectionName.toLowerCase();

    switch (formatted) {
      case 'chorus':
        return 'CHORUS';
      case 'verse':
      case 'verse1':
      case 'verse 1':
        return 'VERSE 1';
      case 'verse2':
      case 'verse 2':
        return 'VERSE 2';
      case 'verse3':
      case 'verse 3':
        return 'VERSE 3';
      case 'bridge':
        return 'BRIDGE';
      case 'intro':
        return 'INTRO';
      case 'outro':
      case 'ending':
        return 'OUTRO';
      case 'prechorus':
      case 'pre-chorus':
        return 'PRE-CHORUS';
      default:
        // Capitalize first letter of each word
        return sectionName
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ')
            .toUpperCase();
    }
  }
}

class PresentationSection {
  final String content;
  final String? subtitle;
  final String? title;
  final String? metadata;
  final List<String> lines;
  final bool isTitle;

  PresentationSection({
    this.content = '',
    this.subtitle,
    this.title,
    this.metadata,
    this.lines = const [],
    this.isTitle = false,
  });
}