import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../config/theme.dart';

class SongPresentationScreen extends StatefulWidget {
  final Song song;

  const SongPresentationScreen({
    super.key,
    required this.song,
  });

  @override
  State<SongPresentationScreen> createState() => _SongPresentationScreenState();
}

class _SongPresentationScreenState extends State<SongPresentationScreen> {
  late PageController _pageController;
  int _currentSectionIndex = 0;
  List<PresentationSection> _sections = [];
  bool _showControls = true;
  bool _showChords = true;
  double _fontSize = 24.0;

  // Color customization options
  int _backgroundThemeIndex = 0;
  int _textColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _parseSongIntoSections();
    _hideControlsAfterDelay();

    // Set full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _parseSongIntoSections() {
    final sections = <PresentationSection>[];

    // Add title section
    sections.add(PresentationSection(
      type: SectionType.title,
      title: 'Title',
      content: widget.song.title,
      subtitle: 'by ${widget.song.artist}',
      metadata: 'Key: ${widget.song.key} • Difficulty: ${widget.song.difficulty}',
    ));

    if (widget.song.chords != null && widget.song.chords!.isNotEmpty) {
      // Parse chord sheet into sections
      final parsedSections = _parseChordSheet(widget.song.chords!);
      sections.addAll(parsedSections);
    } else {
      // Fallback if no chords available
      sections.add(PresentationSection(
        type: SectionType.content,
        title: 'Song Content',
        content: 'No chord sheet available for presentation.',
      ));
    }

    setState(() {
      _sections = sections;
    });
  }

  List<PresentationSection> _parseChordSheet(String chordSheet) {
    final sections = <PresentationSection>[];

    debugPrint('Parsing chord sheet: ${chordSheet.substring(0, chordSheet.length > 100 ? 100 : chordSheet.length)}...');

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
            type: SectionType.content,
            title: _formatSectionTitle(currentSectionName),
            content: currentSectionLines.join('\n').trim(),
          ));
          debugPrint('Added section: "$currentSectionName" with ${currentSectionLines.length} lines');
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
        type: SectionType.content,
        title: _formatSectionTitle(currentSectionName),
        content: currentSectionLines.join('\n').trim(),
      ));
      debugPrint('Added final section: "$currentSectionName" with ${currentSectionLines.length} lines');
    }

    // If no sections were created, add a fallback
    if (sections.isEmpty) {
      debugPrint('No sections found, using entire content as one section');
      sections.add(PresentationSection(
        type: SectionType.content,
        title: 'Song Content',
        content: chordSheet.trim(),
      ));
    }

    debugPrint('Created ${sections.length} presentation sections');
    for (int i = 0; i < sections.length; i++) {
      debugPrint('Section ${i + 1}: "${sections[i].title}"');
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

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _nextSection() {
    if (_currentSectionIndex < _sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: GestureDetector(
          onTap: _toggleControls,
          child: Column(
            children: [
              // Top controls (always visible)
              _buildTopControls(),

              // Main content area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _sections.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSectionIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildSectionSlide(_sections[index]);
                  },
                ),
              ),

              // Bottom section navigation (always visible)
              _buildSectionNavigation(),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),

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

          // Current section indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_currentSectionIndex + 1} of ${_sections.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Spacer(),

          // Chord toggle
          IconButton(
            icon: Icon(
              _showChords ? Icons.music_note : Icons.music_off,
              color: _showChords ? Theme.of(context).colorScheme.primary : Colors.white70,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _showChords = !_showChords;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionNavigation() {
    return Container(
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
        // Add subtle border at top
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
                final isTitle = section.type == SectionType.title;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => _jumpToSection(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isTitle ? 'TITLE' : section.title,
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
              // Previous button
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: _currentSectionIndex > 0 ? Colors.white : Colors.white30,
                  size: 32,
                ),
                onPressed: _currentSectionIndex > 0 ? _previousSection : null,
              ),

              // Play/pause placeholder (for future auto-advance feature)
              IconButton(
                icon: const Icon(Icons.pause, color: Colors.white30, size: 28),
                onPressed: null, // Disabled for now
              ),

              // Next button
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
    );
  }

  // Jump to specific section
  void _jumpToSection(int index) {
    // Use jumpToPage for instant, seamless navigation
    _pageController.jumpToPage(index);
  }

  Widget _buildSectionSlide(PresentationSection section) {
    if (section.type == SectionType.title) {
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  section.metadata!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              section.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: _fontSize - 6,
                fontWeight: FontWeight.w500,
                fontFamily: AppTheme.primaryFontFamily,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

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
          color: Theme.of(context).colorScheme.primary,
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
}

// Data classes for presentation sections
class PresentationSection {
  final SectionType type;
  final String title;
  final String content;
  final String? subtitle;
  final String? metadata;

  PresentationSection({
    required this.type,
    required this.title,
    required this.content,
    this.subtitle,
    this.metadata,
  });
}

enum SectionType {
  title,
  content,
}
