import 'package:flutter/material.dart';
import '../../services/chord_timing_service.dart';
import '../../config/theme.dart';

class SectionNavigator extends StatefulWidget {
  final ChordTimingService chordTimingService;
  final Function(String)? onSectionSelected;

  const SectionNavigator({
    super.key,
    required this.chordTimingService,
    this.onSectionSelected,
  });

  @override
  State<SectionNavigator> createState() => _SectionNavigatorState();
}

class _SectionNavigatorState extends State<SectionNavigator> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Listen to section changes to auto-scroll
    widget.chordTimingService.addListener(_onSectionChanged);
  }

  @override
  void dispose() {
    widget.chordTimingService.removeListener(_onSectionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSectionChanged() {
    if (mounted) {
      _scrollToCurrentSection();
    }
  }

  void _scrollToCurrentSection() {
    final sections = widget.chordTimingService.sections;
    final currentSection = widget.chordTimingService.currentSection;
    
    final currentIndex = sections.indexWhere((s) => s.name == currentSection);
    if (currentIndex != -1 && _scrollController.hasClients) {
      final itemWidth = 120.0; // Approximate width of each section tab
      final targetOffset = (currentIndex * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.chordTimingService,
      builder: (context, child) {
        final sections = widget.chordTimingService.sections;
        
        if (sections.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // Section progress indicator
              _buildProgressIndicator(),
              
              const SizedBox(height: 8),
              
              // Section tabs
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return _buildSectionTab(section, index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    final progress = widget.chordTimingService.getSectionProgress();
    
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTab(SongSection section, int index) {
    final isCurrentSection = widget.chordTimingService.currentSection == section.name;
    final isLooping = widget.chordTimingService.isLooping && 
                     widget.chordTimingService.loopSection == section.name;
    
    return GestureDetector(
      onTap: () {
        widget.chordTimingService.jumpToSection(section.name);
        widget.onSectionSelected?.call(section.name);
      },
      onLongPress: () {
        _showSectionOptions(section);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentSection 
              ? AppTheme.primary
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: isLooping 
              ? Border.all(color: AppTheme.primary, width: 2)
              : null,
          boxShadow: isCurrentSection
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loop indicator
            if (isLooping)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.repeat,
                  size: 14,
                  color: isCurrentSection ? Colors.black : AppTheme.primary,
                ),
              ),
            
            // Section name
            Text(
              section.displayName,
              style: TextStyle(
                color: isCurrentSection ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: isCurrentSection ? FontWeight.w600 : FontWeight.w500,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSectionOptions(SongSection section) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildSectionOptionsSheet(section),
    );
  }

  Widget _buildSectionOptionsSheet(SongSection section) {
    final isLooping = widget.chordTimingService.isLooping && 
                     widget.chordTimingService.loopSection == section.name;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                section.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Options
          _buildOptionTile(
            icon: Icons.play_arrow,
            title: 'Jump to Section',
            subtitle: 'Start playing from this section',
            onTap: () {
              Navigator.pop(context);
              widget.chordTimingService.jumpToSection(section.name);
              widget.onSectionSelected?.call(section.name);
            },
          ),
          
          _buildOptionTile(
            icon: isLooping ? Icons.repeat_on : Icons.repeat,
            title: isLooping ? 'Stop Looping' : 'Loop Section',
            subtitle: isLooping 
                ? 'Stop repeating this section'
                : 'Repeat this section continuously',
            onTap: () {
              Navigator.pop(context);
              widget.chordTimingService.toggleLoop(section.name);
            },
          ),
          
          _buildOptionTile(
            icon: Icons.info_outline,
            title: 'Section Info',
            subtitle: 'Beats: ${section.startBeat}-${section.endBeat} • Chords: ${section.chordTimings.length}',
            onTap: () {
              Navigator.pop(context);
              _showSectionInfo(section);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showSectionInfo(SongSection section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              section.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Start Beat', '${section.startBeat}'),
            _buildInfoRow('End Beat', '${section.endBeat}'),
            _buildInfoRow('Total Beats', '${section.endBeat - section.startBeat + 1}'),
            _buildInfoRow('Chord Changes', '${section.chordTimings.length}'),
            
            if (section.chordTimings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Chords in this section:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: section.chordTimings
                    .map((timing) => _buildChordChip(timing.chord))
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppTheme.primary,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChordChip(String chord) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        chord,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
    );
  }
}
