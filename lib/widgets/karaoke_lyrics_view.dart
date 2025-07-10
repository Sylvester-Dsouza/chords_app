import 'package:flutter/material.dart';
import '../models/song.dart';
import '../config/theme.dart';
import '../utils/chord_extractor.dart';

class KaraokeLyricsView extends StatefulWidget {
  final Song song;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;

  const KaraokeLyricsView({
    super.key,
    required this.song,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
  });

  @override
  State<KaraokeLyricsView> createState() => _KaraokeLyricsViewState();
}

class _KaraokeLyricsViewState extends State<KaraokeLyricsView> {
  List<String> _lyricsLines = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _extractLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _extractLyrics() {
    debugPrint('🎵 Extracting lyrics for song: ${widget.song.title}');
    debugPrint('🎵 Has chords: ${widget.song.chords != null}');
    debugPrint('🎵 Has lyrics: ${widget.song.lyrics != null}');

    String? lyricsText;

    // Try to extract lyrics from chords first (chord sheet format)
    if (widget.song.chords != null && widget.song.chords!.isNotEmpty) {
      debugPrint('🎵 Extracting lyrics from chord sheet');
      debugPrint('🎵 Chord sheet preview: ${widget.song.chords!.substring(0, widget.song.chords!.length > 200 ? 200 : widget.song.chords!.length)}...');

      try {
        final result = ChordExtractor.extractLyrics(widget.song.chords!);
        if (result.isNotEmpty && result.length > 10) {
          lyricsText = result;
          debugPrint('🎵 Successfully extracted lyrics from chord sheet (${result.length} chars)');
        } else {
          debugPrint('🎵 ChordExtractor result too short, trying manual extraction');
          lyricsText = _manualLyricsExtraction(widget.song.chords!);
        }
      } catch (e) {
        debugPrint('🎵 Error extracting lyrics from chord sheet: $e');
        debugPrint('🎵 Falling back to manual extraction');
        lyricsText = _manualLyricsExtraction(widget.song.chords!);
      }
    }

    // If no lyrics from chord sheet, try the lyrics field
    if (lyricsText == null && widget.song.lyrics != null && widget.song.lyrics!.isNotEmpty) {
      debugPrint('🎵 Using lyrics field directly');
      lyricsText = widget.song.lyrics!;
    }

    // If still no lyrics, try using the chord sheet as-is (fallback)
    if (lyricsText == null && widget.song.chords != null && widget.song.chords!.isNotEmpty) {
      debugPrint('🎵 Using chord sheet as-is for lyrics');
      lyricsText = widget.song.chords!;
    }

    if (lyricsText != null) {
      setState(() {
        _lyricsLines = lyricsText!
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      });
      debugPrint('🎵 Extracted ${_lyricsLines.length} lines of lyrics');
    } else {
      debugPrint('🎵 No lyrics found for song');
      setState(() {
        _lyricsLines = [];
      });
    }
  }

  /// Manual lyrics extraction as fallback when ChordExtractor fails
  String _manualLyricsExtraction(String chordSheet) {
    String lyrics = chordSheet;

    // Keep section headers but format them nicely
    lyrics = lyrics.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
      final sectionName = match.group(1)?.toUpperCase() ?? '';
      return '\n--- $sectionName ---\n';
    });

    // Remove bracketed chords [C] [Am] [G/B] etc.
    lyrics = lyrics.replaceAll(RegExp(r'\[[^\]]+\]'), '');

    // Remove lines that are mostly chords (lines with multiple chord patterns)
    final lines = lyrics.split('\n');
    final lyricsLines = <String>[];

    for (String line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) continue;

      // Skip lines that are mostly chord patterns
      // Check if line has more than 3 chord-like patterns
      final chordMatches = RegExp(r'\b[A-G][#b]?(?:maj|min|m|sus|aug|dim|add|maj7|m7|7|6|9|11|13|sus2|sus4)?(?:\d)?(?:/[A-G][#b]?)?\b').allMatches(trimmedLine);

      if (chordMatches.length > 3 && trimmedLine.length < 50) {
        // Likely a chord line, skip it
        continue;
      }

      // Keep lines that look like lyrics
      lyricsLines.add(trimmedLine);
    }

    return lyricsLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: _lyricsLines.isEmpty ? _buildNoLyricsState() : _buildLyricsContent(),
    );
  }

  Widget _buildNoLyricsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lyrics_outlined,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Lyrics Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.displayFontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lyrics will appear here when available',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
              fontFamily: AppTheme.primaryFontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Song Info Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Row(
              children: [
                if (widget.song.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.song.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.displayFontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.song.artist,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.song.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lyrics
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _lyricsLines.map((line) {
                  
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: AppTheme.textPrimary,
                        fontFamily: AppTheme.primaryFontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }


}
