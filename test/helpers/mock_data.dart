import 'dart:ui';
import 'package:chords_app/models/song.dart';
import 'package:chords_app/models/user_model.dart';
import 'package:chords_app/models/artist.dart';
import 'package:chords_app/models/collection.dart';
import 'package:chords_app/models/karaoke.dart';

/// Factory class for creating mock test data
class MockData {
  /// Creates a mock Song with default or custom values
  static Song createSong({
    String? id,
    String? title,
    String? artist,
    String? key,
    String? lyrics,
    String? chords,
    String? imageUrl,
    String? officialVideoUrl,
    String? tutorialVideoUrl,
    List<String>? tags,
    String? artistId,
    int? capo,
    int? tempo,
    String? timeSignature,
    String? difficulty,
    String? languageId,
    Map<String, dynamic>? language,
    String? strummingPattern,
    bool? isLiked,
    int? commentCount,
    double? averageRating,
    int? ratingCount,
    int? userRating,
    Karaoke? karaoke,
  }) {
    return Song(
      id: id ?? 'test-song-1',
      title: title ?? 'Amazing Grace',
      artist: artist ?? 'John Newton',
      key: key ?? 'G',
      lyrics: lyrics ?? 'Amazing grace, how sweet the sound\nThat saved a wretch like me',
      chords: chords ?? 'G    C    G    D\nAmazing grace, how sweet the sound\nG    C    G    D    G\nThat saved a wretch like me',
      imageUrl: imageUrl,
      officialVideoUrl: officialVideoUrl,
      tutorialVideoUrl: tutorialVideoUrl,
      tags: tags ?? ['worship', 'classic'],
      artistId: artistId ?? 'artist-1',
      capo: capo ?? 0,
      tempo: tempo ?? 120,
      timeSignature: timeSignature ?? '4/4',
      difficulty: difficulty ?? 'Easy',
      languageId: languageId ?? 'en',
      language: language ?? {'id': 'en', 'name': 'English'},
      strummingPattern: strummingPattern ?? 'D-D-U-U-D-U',
      isLiked: isLiked ?? false,
      commentCount: commentCount ?? 5,
      averageRating: averageRating ?? 4.5,
      ratingCount: ratingCount ?? 10,
      userRating: userRating,
      karaoke: karaoke,
    );
  }

  /// Creates a list of mock Songs
  static List<Song> createSongList({int count = 3}) {
    return List.generate(count, (index) => createSong(
      id: 'test-song-${index + 1}',
      title: 'Test Song ${index + 1}',
      artist: 'Test Artist ${index + 1}',
    ));
  }

  /// Creates a mock UserModel with default or custom values
  static UserModel createUser({
    String? id,
    String? name,
    String? email,
    String? firebaseUid,
    String? profilePicture,
    String? phoneNumber,
    String? subscriptionType,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? lastLoginAt,
    String? authProvider,
    bool? rememberMe,
    bool? termsAccepted,
    DateTime? termsAcceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id ?? 'test-user-1',
      name: name ?? 'John Doe',
      email: email ?? 'john.doe@example.com',
      firebaseUid: firebaseUid ?? 'firebase-uid-123',
      profilePicture: profilePicture,
      phoneNumber: phoneNumber,
      subscriptionType: subscriptionType ?? 'free',
      isActive: isActive ?? true,
      isEmailVerified: isEmailVerified ?? true,
      lastLoginAt: lastLoginAt ?? now,
      authProvider: authProvider ?? 'email',
      rememberMe: rememberMe ?? false,
      termsAccepted: termsAccepted ?? true,
      termsAcceptedAt: termsAcceptedAt ?? now,
      createdAt: createdAt ?? now.subtract(const Duration(days: 30)),
      updatedAt: updatedAt ?? now,
    );
  }

  /// Creates a list of mock Users
  static List<UserModel> createUserList({int count = 3}) {
    return List.generate(count, (index) => createUser(
      id: 'test-user-${index + 1}',
      name: 'Test User ${index + 1}',
      email: 'testuser${index + 1}@example.com',
    ));
  }

  /// Creates a mock Artist with default or custom values
  static Artist createArtist({
    String? id,
    String? name,
    String? bio,
    String? imageUrl,
    String? website,
    SocialLinks? socialLinks,
    int? songCount,
    bool? isFeatured,
  }) {
    return Artist(
      id: id ?? 'test-artist-1',
      name: name ?? 'Hillsong United',
      bio: bio ?? 'Contemporary Christian music band from Australia',
      imageUrl: imageUrl,
      website: website ?? 'https://hillsong.com',
      socialLinks: socialLinks ?? SocialLinks(
        facebook: 'https://facebook.com/hillsong',
        instagram: 'https://instagram.com/hillsong',
        twitter: 'https://twitter.com/hillsong',
        youtube: 'https://youtube.com/hillsong',
      ),
      songCount: songCount ?? 25,
      isFeatured: isFeatured ?? false,
    );
  }

  /// Creates a list of mock Artists
  static List<Artist> createArtistList({int count = 3}) {
    return List.generate(count, (index) => createArtist(
      id: 'test-artist-${index + 1}',
      name: 'Test Artist ${index + 1}',
      songCount: (index + 1) * 10,
    ));
  }

  /// Creates a mock Collection with default or custom values
  static Collection createCollection({
    String? id,
    String? title,
    String? description,
    int? songCount,
    int? likeCount,
    bool? isLiked,
    Color? color,
    String? imageUrl,
    List<Song>? songs,
    bool? isPublic,
  }) {
    return Collection(
      id: id ?? 'test-collection-1',
      title: title ?? 'Worship Favorites',
      description: description ?? 'A collection of favorite worship songs',
      songCount: songCount ?? 10,
      likeCount: likeCount ?? 25,
      isLiked: isLiked ?? false,
      color: color ?? const Color(0xFF3498DB),
      imageUrl: imageUrl,
      songs: songs ?? createSongList(count: 3),
      isPublic: isPublic ?? true,
    );
  }

  /// Creates a list of mock Collections
  static List<Collection> createCollectionList({int count = 3}) {
    final colors = [
      const Color(0xFF3498DB), // Blue
      const Color(0xFF2ECC71), // Green
      const Color(0xFFE74C3C), // Red
    ];

    return List.generate(count, (index) => createCollection(
      id: 'test-collection-${index + 1}',
      title: 'Test Collection ${index + 1}',
      color: colors[index % colors.length],
      songCount: (index + 1) * 5,
    ));
  }

  /// Creates a mock Karaoke with default or custom values
  static Karaoke createKaraoke({
    String? id,
    String? songId,
    String? fileUrl,
    int? duration,
    String? status,
  }) {
    final now = DateTime.now();
    return Karaoke(
      id: id ?? 'test-karaoke-1',
      songId: songId ?? 'test-song-1',
      fileUrl: fileUrl ?? 'https://example.com/karaoke-audio.mp3',
      duration: duration ?? 240, // 4 minutes
      uploadedAt: now,
      updatedAt: now,
      version: 1,
      status: status ?? 'ACTIVE',
    );
  }

  /// Creates a mock SocialLinks with default or custom values
  static SocialLinks createSocialLinks({
    String? facebook,
    String? twitter,
    String? instagram,
    String? youtube,
  }) {
    return SocialLinks(
      facebook: facebook ?? 'https://facebook.com/testartist',
      twitter: twitter ?? 'https://twitter.com/testartist',
      instagram: instagram ?? 'https://instagram.com/testartist',
      youtube: youtube ?? 'https://youtube.com/testartist',
    );
  }

  /// Creates mock API response data
  static Map<String, dynamic> createApiResponse({
    required dynamic data,
    bool success = true,
    String? message,
    int? statusCode,
  }) {
    return {
      'success': success,
      'data': data,
      'message': message ?? (success ? 'Success' : 'Error'),
      'statusCode': statusCode ?? (success ? 200 : 500),
    };
  }

  /// Creates mock error response data
  static Map<String, dynamic> createErrorResponse({
    String? message,
    int? statusCode,
    String? error,
  }) {
    return {
      'success': false,
      'error': error ?? 'Test error',
      'message': message ?? 'An error occurred during testing',
      'statusCode': statusCode ?? 500,
    };
  }

  /// Creates mock pagination data
  static Map<String, dynamic> createPaginatedResponse({
    required List<dynamic> data,
    int page = 1,
    int limit = 10,
    int? total,
  }) {
    final totalCount = total ?? data.length;
    final totalPages = (totalCount / limit).ceil();
    
    return {
      'data': data,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': totalCount,
        'totalPages': totalPages,
        'hasNext': page < totalPages,
        'hasPrev': page > 1,
      },
    };
  }

  /// Creates mock search results
  static Map<String, dynamic> createSearchResults({
    List<Song>? songs,
    List<Artist>? artists,
    List<Collection>? collections,
    String? query,
  }) {
    return {
      'query': query ?? 'test',
      'results': {
        'songs': songs?.map((s) => s.toJson()).toList() ?? [],
        'artists': artists?.map((a) => a.toJson()).toList() ?? [],
        'collections': collections?.map((c) => c.toJson()).toList() ?? [],
      },
      'totalResults': (songs?.length ?? 0) + (artists?.length ?? 0) + (collections?.length ?? 0),
    };
  }

  /// Creates mock authentication token data
  static Map<String, dynamic> createAuthTokenData({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
  }) {
    return {
      'accessToken': accessToken ?? 'mock-access-token-123',
      'refreshToken': refreshToken ?? 'mock-refresh-token-456',
      'expiresIn': expiresIn ?? 3600, // 1 hour
      'tokenType': tokenType ?? 'Bearer',
    };
  }

  /// Creates mock user preferences data
  static Map<String, dynamic> createUserPreferences({
    String? theme,
    bool? notifications,
    String? language,
    Map<String, dynamic>? customSettings,
  }) {
    return {
      'theme': theme ?? 'light',
      'notifications': notifications ?? true,
      'language': language ?? 'en',
      'customSettings': customSettings ?? {},
    };
  }
}