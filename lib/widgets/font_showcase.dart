import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/font_utils.dart';

/// A widget that showcases all the app's text styles
/// This is useful for developers to see all available text styles in one place
class FontShowcase extends StatelessWidget {
  const FontShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Font Showcase',
          style: FontUtils.primaryHeading(fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Display Styles'),
            _buildStyleRow('Display Large', Theme.of(context).textTheme.displayLarge!),
            _buildStyleRow('Display Medium', Theme.of(context).textTheme.displayMedium!),
            _buildStyleRow('Display Small', Theme.of(context).textTheme.displaySmall!),
            
            _buildSection('Heading Styles'),
            _buildStyleRow('Headline Medium', Theme.of(context).textTheme.headlineMedium!),
            _buildStyleRow('Title Large', Theme.of(context).textTheme.titleLarge!),
            
            _buildSection('Body Styles'),
            _buildStyleRow('Body Large', Theme.of(context).textTheme.bodyLarge!),
            _buildStyleRow('Body Medium', Theme.of(context).textTheme.bodyMedium!),
            _buildStyleRow('Label Large', Theme.of(context).textTheme.labelLarge!),
            
            _buildSection('App-Specific Styles'),
            _buildStyleRow('Song Title', AppTheme.songTitleStyle),
            _buildStyleRow('Artist Name', AppTheme.artistNameStyle),
            _buildStyleRow('Section Title', AppTheme.sectionTitleStyle),
            _buildStyleRow('Chord Sheet', AppTheme.chordSheetStyle),
            _buildStyleRow('Chord', AppTheme.chordStyle),
            _buildStyleRow('Section Header', AppTheme.sectionHeaderStyle),
            _buildStyleRow('Tab Label', AppTheme.tabLabelStyle),
            _buildStyleRow('Bottom Nav Label', AppTheme.bottomNavLabelStyle),
            
            _buildSection('Additional Styles'),
            _buildStyleRow('Error Text', AppTheme.errorTextStyle),
            _buildStyleRow('Placeholder Text', AppTheme.placeholderTextStyle),
            _buildStyleRow('Dialog Title', AppTheme.dialogTitleStyle),
            _buildStyleRow('Dialog Content', AppTheme.dialogContentStyle),
            _buildStyleRow('Caption', AppTheme.captionStyle),
            _buildStyleRow('Code', AppTheme.codeStyle),
            _buildStyleRow('Button Text', AppTheme.buttonTextStyle),
            
            _buildSection('Font Styles'),
            _buildStyleRow('Primary Heading', FontUtils.primaryHeading(fontSize: 18)),
            _buildStyleRow('Secondary Heading', FontUtils.secondaryHeading(fontSize: 16)),
            _buildStyleRow('Body Text', FontUtils.bodyText(fontSize: 14)),
            _buildStyleRow('Light Text', FontUtils.lightText(fontSize: 12)),
            
            _buildSection('Font Weight Constants'),
            _buildWeightRow('Primary (w600)', FontUtils.primary),
            _buildWeightRow('Secondary (w500)', FontUtils.secondary),
            _buildWeightRow('Regular (w400)', FontUtils.regular),
            _buildWeightRow('Light (w300)', FontUtils.light),
            _buildWeightRow('Emphasis (w700)', FontUtils.emphasis),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: FontUtils.primaryHeading(
          fontSize: 20,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildStyleRow(String name, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: FontUtils.lightText(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: style,
          ),
          const SizedBox(height: 4),
          Text(
            'Font: ${style.fontFamily}, Size: ${style.fontSize}, Weight: ${style.fontWeight}',
            style: const TextStyle(
              fontFamily: AppTheme.monospaceFontFamily,
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
  
  Widget _buildWeightRow(String name, FontWeight weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: FontUtils.lightText(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: TextStyle(
              fontFamily: AppTheme.primaryFontFamily,
              fontSize: 16,
              fontWeight: weight,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Weight: $weight',
            style: const TextStyle(
              fontFamily: AppTheme.monospaceFontFamily,
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}