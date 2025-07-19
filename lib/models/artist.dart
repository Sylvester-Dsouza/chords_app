import 'dart:convert';
import 'package:flutter/foundation.dart';

class SocialLinks {
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? youtube;

  SocialLinks({this.facebook, this.twitter, this.instagram, this.youtube});

  factory SocialLinks.fromJson(dynamic json) {
    debugPrint('SocialLinks.fromJson input: $json (type: ${json.runtimeType})');

    if (json == null) {
      debugPrint('SocialLinks: JSON is null, returning empty SocialLinks');
      return SocialLinks();
    }

    Map<String, dynamic>? socialLinksMap;

    // Handle different data types
    if (json is Map<String, dynamic>) {
      socialLinksMap = json;
    } else if (json is String) {
      // Try to parse JSON string
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map<String, dynamic>) {
          socialLinksMap = decoded;
        }
      } catch (e) {
        debugPrint('Failed to parse socialLinks JSON string: $e');
        return SocialLinks();
      }
    } else {
      debugPrint(
        'SocialLinks: Unexpected data type ${json.runtimeType}, returning empty SocialLinks',
      );
      return SocialLinks();
    }

    if (socialLinksMap == null) {
      debugPrint(
        'SocialLinks: Could not extract map, returning empty SocialLinks',
      );
      return SocialLinks();
    }

    final socialLinks = SocialLinks(
      facebook: socialLinksMap['facebook']?.toString(),
      twitter: socialLinksMap['twitter']?.toString(),
      instagram: socialLinksMap['instagram']?.toString(),
      youtube: socialLinksMap['youtube']?.toString(),
    );

    debugPrint(
      'SocialLinks created: facebook=${socialLinks.facebook}, instagram=${socialLinks.instagram}, twitter=${socialLinks.twitter}, youtube=${socialLinks.youtube}',
    );
    return socialLinks;
  }

  Map<String, dynamic> toJson() {
    return {
      'facebook': facebook,
      'twitter': twitter,
      'instagram': instagram,
      'youtube': youtube,
    };
  }
}

class Artist {
  final String id;
  final String name;
  final String? bio;
  final String? imageUrl;
  final String? website;
  final SocialLinks? socialLinks;
  final int songCount;
  final bool isFeatured;

  Artist({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    this.website,
    this.socialLinks,
    this.songCount = 0,
    this.isFeatured = false,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    debugPrint('Artist JSON: $json');
    debugPrint('Artist socialLinks raw: ${json['socialLinks']}');
    debugPrint('Artist website raw: ${json['website']}');

    // Try to parse songCount from different possible fields
    int songCount = 0;
    if (json['songCount'] != null) {
      // Try to parse as int
      songCount =
          json['songCount'] is int
              ? json['songCount'] as int
              : int.tryParse(json['songCount'].toString()) ?? 0;
    } else if (json['songs_count'] != null) {
      // Alternative field name
      songCount =
          json['songs_count'] is int
              ? json['songs_count'] as int
              : int.tryParse(json['songs_count'].toString()) ?? 0;
    } else if (json['songs'] != null && json['songs'] is List) {
      // If songs array is provided, count its length
      songCount = (json['songs'] as List).length;
    }

    // Handle legacy data where social links might be in bio field
    SocialLinks socialLinks = SocialLinks.fromJson(json['socialLinks']);
    String? bio = json['bio']?.toString();
    String? website = json['website']?.toString();

    // Check if bio contains a URL that should be a social link
    bool hasNoSocialLinks =
        socialLinks.facebook == null &&
        socialLinks.instagram == null &&
        socialLinks.twitter == null &&
        socialLinks.youtube == null;

    if (bio != null && bio.contains('http') && hasNoSocialLinks) {
      debugPrint(
        'Found URL in bio field, attempting to parse as social link: $bio',
      );

      // Try to determine which social platform this is
      if (bio.toLowerCase().contains('facebook') ||
          bio.toLowerCase().contains('fb.com')) {
        socialLinks = SocialLinks(facebook: bio);
        bio = null; // Clear bio since it was actually a social link
        debugPrint('Moved Facebook URL from bio to socialLinks');
      } else if (bio.toLowerCase().contains('instagram') ||
          bio.toLowerCase().contains('insta')) {
        socialLinks = SocialLinks(instagram: bio);
        bio = null;
        debugPrint('Moved Instagram URL from bio to socialLinks');
      } else if (bio.toLowerCase().contains('twitter') ||
          bio.toLowerCase().contains('x.com')) {
        socialLinks = SocialLinks(twitter: bio);
        bio = null;
        debugPrint('Moved Twitter URL from bio to socialLinks');
      } else if (bio.toLowerCase().contains('youtube') ||
          bio.toLowerCase().contains('youtu.be')) {
        socialLinks = SocialLinks(youtube: bio);
        bio = null;
        debugPrint('Moved YouTube URL from bio to socialLinks');
      } else {
        // If it's not a social link, treat it as website
        website = bio;
        bio = null;
        debugPrint('Moved URL from bio to website');
      }
    }

    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bio: bio,
      imageUrl: json['imageUrl']?.toString(),
      website: website,
      socialLinks: socialLinks,
      songCount: songCount,
      isFeatured: json['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'website': website,
      'socialLinks': socialLinks?.toJson(),
      'songCount': songCount,
      'isFeatured': isFeatured,
    };
  }
}
