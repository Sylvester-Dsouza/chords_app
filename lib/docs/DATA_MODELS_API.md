# Data Models API Documentation

## Overview

This document provides comprehensive documentation for the data models used throughout the Stuthi Flutter application. All models follow consistent patterns for JSON serialization/deserialization and include proper error handling.

## Core Models

### Comment Model

The `Comment` model represents user comments on songs with support for nested replies.

#### Properties
- `id`: Unique comment identifier
- `songId`: ID of the song being commented on
- `customerId`: ID of the customer who made the comment
- `customerName`: Display name of the customer
- `customerProfilePicture`: Optional profile picture URL
- `text`: Comment content
- `createdAt`: Comment creation timestamp
- `updatedAt`: Last modification timestamp
- `parentId`: Optional parent comment ID for replies
- `replies`: List of nested reply comments
- `likesCount`: Number of likes on the comment
- `isLiked`: Whether current user has liked the comment
- `isDeleted`: Soft deletion flag
- `deletedAt`: Deletion timestamp

#### JSON Serialization
```dart
// From JSON with error handling
Comment comment = Comment.fromJson(jsonData);

// To JSON
Map<String, dynamic> json = comment.toJson();
```

### Setlist Model

The `Setlist` model represents user-created song collections with collaborative features.

#### Properties
- `id`: Unique setlist identifier
- `name`: Setlist name
- `description`: Optional description
- `customerId`: Owner's customer ID
- `createdAt`: Creation timestamp
- `updatedAt`: Last modification timestamp
- `songs`: List of songs in the setlist
- `isPublic`: Public visibility flag
- `isShared`: Sharing enabled flag
- `shareCode`: Unique sharing code
- `allowEditing`: Collaborative editing permission
- `allowComments`: Comments enabled flag
- `isSharedWithMe`: Flag for shared setlists
- `version`: Version number for sync
- `lastSyncAt`: Last synchronization timestamp
- `isDeleted`: Soft deletion flag
- `deletedAt`: Deletion timestamp
- `collaborators`: List of setlist collaborators
- `activities`: List of setlist activities
- `comments`: List of setlist comments

#### Related Models

##### SetlistCollaborator
Represents users who have access to collaborate on a setlist.

**Properties:**
- `id`: Collaborator record ID
- `customerId`: Customer ID of collaborator
- `permission`: Permission level ("VIEW", "EDIT", "ADMIN")
- `status`: Invitation status ("PENDING", "ACCEPTED", "DECLINED", "REMOVED")
- `invitedAt`: Invitation timestamp
- `acceptedAt`: Acceptance timestamp
- `lastActiveAt`: Last activity timestamp
- `customer`: Customer data object

##### SetlistActivity
Tracks changes and activities on setlists for audit purposes.

**Properties:**
- `id`: Activity record ID
- `customerId`: Customer who performed the action
- `action`: Action type ("CREATED", "UPDATED", "SONG_ADDED", etc.)
- `details`: Additional action details
- `timestamp`: When the action occurred
- `version`: Setlist version at time of action
- `customer`: Customer data object

##### SetlistComment
Comments specific to setlists (separate from song comments).

**Properties:**
- `id`: Comment ID
- `customerId`: Commenter's customer ID
- `text`: Comment content
- `parentId`: Parent comment ID for replies
- `createdAt`: Creation timestamp
- `updatedAt`: Last modification timestamp
- `isDeleted`: Soft deletion flag
- `deletedAt`: Deletion timestamp
- `customer`: Customer data object
- `replies`: Nested reply comments

## JSON Parsing Best Practices

### Type Safety

All JSON parsing includes explicit type casting to prevent runtime errors:

```dart
// Correct - with explicit type casting
repliesData = (json['replies'] as List)
    .map((item) => SetlistComment.fromJson(item as Map<String, dynamic>))
    .toList();
```

### Error Handling

JSON parsing includes comprehensive error handling with fallbacks:

```dart
try {
  if (json['replies'] != null) {
    repliesData = (json['replies'] as List)
        .map((item) => SetlistComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }
} catch (e) {
  debugPrint('Error parsing comment replies: $e');
  repliesData = []; // Fallback to empty list
}
```

### Null Safety

All models handle null values gracefully:

```dart
// Safe null handling with fallbacks
name: json['name']?.toString() ?? '',
createdAt: json['createdAt'] != null
    ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
    : DateTime.now(),
```

## Recent Updates

### Type Safety Improvements (Latest)

**Date**: January 2025
**Changes**: Enhanced type safety across data models, UI components, and error handling
**Impact**: Prevents potential runtime type errors and improves overall app stability

**Key Improvements**:

1. **Explicit Type Casting in JSON Parsing**:
```dart
// Before
.map((item) => SetlistComment.fromJson(item))

// After  
.map((item) => SetlistComment.fromJson(item as Map<String, dynamic>))
```

2. **Enhanced Error Handler Type Safety**:
```dart
// Before
return stream.handleError((error, stackTrace) {

// After
return stream.handleError((Object error, StackTrace stackTrace) {
```

3. **Safe String Conversion in UI Components**:
```dart
// Before - potential runtime error if name is not a String
comment.customer?['name'] ?? 'Anonymous'

// After - safe conversion to String
comment.customer?['name']?.toString() ?? 'Anonymous'
```

4. **Dynamic Data Extraction with Type Safety**:
```dart
// Before - unsafe dynamic access
title = song['title'] ?? 'Unknown Song';
artist = song['artist']['name'] ?? 'Unknown Artist';
songId = song['id'] ?? '';

// After - explicit type casting with null safety
title = (song['title'] as String?) ?? 'Unknown Song';
final artistMap = song['artist'] as Map<String, dynamic>;
artist = (artistMap['name'] as String?) ?? 'Unknown Artist';
songId = (song['id'] as String?) ?? '';
```

5. **Nested Object Handling**: Improved handling of nested dynamic objects with proper type validation:
```dart
// Safe extraction of nested artist data
if (song['artist'] is Map<String, dynamic>) {
  final artistMap = song['artist'] as Map<String, dynamic>;
  artist = (artistMap['name'] as String?) ?? 'Unknown Artist';
} else if (song['artist'] is String) {
  artist = song['artist'] as String;
} else {
  artist = 'Unknown Artist';
}
```

6. **Consistent Type Annotations**: All model parsing methods now include explicit type annotations to prevent runtime type errors and improve IDE support.

**Affected Components**:
- **SetlistDetailScreen**: Enhanced song data extraction with explicit type casting
- **Comment Models**: Improved nested data parsing
- **Error Handlers**: Type-safe error handling across all streams
- **UI Components**: Safe dynamic data rendering
- **ListScreen**: Optimized collection loading with dual-strategy approach

These changes ensure that JSON parsing and error handling are more robust and prevent `TypeError` exceptions that could occur if the API returns unexpected data types or if stream operations encounter type-related issues. The latest update specifically addresses dynamic type safety in UI rendering where API data might not match expected types, particularly in setlist management where song data can have varying structures.

### Collection Loading Optimization (January 2025)

**Date**: January 2025
**Changes**: Enhanced collection loading strategy in ListScreen with intelligent metadata completion
**Impact**: Ensures complete collection metadata while maintaining section-specific context

**Key Improvements**:

1. **Intelligent Metadata Completion**: Collections are loaded from section-specific API first, then missing metadata is filled in selectively
2. **Hybrid Loading Strategy**: Combines section-specific data with complete metadata fetching only when needed
3. **Performance Optimization**: Only fetches complete data for collections with missing songCount (songCount = 0)
4. **Graceful Fallback**: Multiple fallback strategies ensure data is always available
5. **Context Preservation**: Maintains section-specific ordering and filtering while ensuring complete data

```dart
// New intelligent approach
Future<void> _loadSectionCollectionsWithSongCount() async {
  // First get section-specific collections
  final sectionItems = await _homeSectionService.getSectionItems(
    widget.sectionId!,
    widget.sectionType!,
  );
  
  List<Collection> collections = sectionItems.cast<Collection>();
  
  // Only fetch complete data for collections with missing songCount
  final collectionsWithMissingSongCount = collections.where((c) => c.songCount == 0).toList();
  
  if (collectionsWithMissingSongCount.isNotEmpty) {
    // Selectively update collections with missing data
    for (int i = 0; i < collections.length; i++) {
      if (collections[i].songCount == 0) {
        final completeCollection = await _collectionService.getCollectionById(collections[i].id);
        collections[i] = completeCollection;
      }
    }
  }
}
```

**Benefits**:
- **Maintains Context**: Preserves section-specific ordering and filtering
- **Optimized Performance**: Only makes additional API calls when necessary
- **Complete Data**: Ensures all collections have accurate metadata
- **Resilient Loading**: Multiple fallback strategies prevent data loading failures

## Screen-Specific Data Handling

### List Screen

The `ListScreen` implements optimized data loading strategies for different content types, with special handling for collections to ensure complete data integrity.

#### Collection Loading Optimization

The screen uses an intelligent hybrid approach for loading collections that balances performance with data completeness:

```dart
// Intelligent collection loading with selective metadata completion
Future<void> _loadSectionCollectionsWithSongCount() async {
  // First get section-specific collections to preserve context
  final sectionItems = await _homeSectionService.getSectionItems(
    widget.sectionId!,
    widget.sectionType!,
  );
  
  List<Collection> collections = sectionItems.cast<Collection>();
  
  // Identify collections with missing metadata
  final collectionsWithMissingSongCount = collections.where((c) => c.songCount == 0).toList();
  
  // Only fetch complete data for collections that need it
  if (collectionsWithMissingSongCount.isNotEmpty) {
    for (int i = 0; i < collections.length; i++) {
      if (collections[i].songCount == 0) {
        final completeCollection = await _collectionService.getCollectionById(collections[i].id);
        collections[i] = completeCollection;
      }
    }
  }
}
```

#### Key Features

- **Context-Aware Loading**: Preserves section-specific ordering and filtering from `HomeSectionService`
- **Selective Metadata Completion**: Only fetches complete data for collections with missing `songCount`
- **Performance Optimization**: Minimizes API calls by only requesting additional data when needed
- **Graceful Fallback**: Multiple fallback strategies including complete collection loading if section loading fails
- **Type-Safe Loading**: Explicit type casting prevents runtime errors during data loading

#### Benefits

- **Maintains Section Context**: Preserves the intended section-specific collection ordering
- **Optimized Performance**: Reduces unnecessary API calls by selectively completing metadata
- **Complete Data Integrity**: Ensures all collections have accurate song counts and metadata
- **Resilient Loading**: Multiple fallback strategies prevent data loading failures
- **Better User Experience**: Shows contextually relevant collections with complete information

### Setlist Detail Screen

The `SetlistDetailScreen` implements robust data extraction patterns for handling dynamic song data from various sources (API, cache, collaborative updates).

#### Song Data Extraction Pattern

```dart
// Safe extraction of song properties with type validation
String title = 'Unknown Song';
String artist = 'Unknown Artist';
String songId = '';

try {
  if (song is Map<String, dynamic>) {
    // Extract title with explicit type casting
    title = (song['title'] as String?) ?? 'Unknown Song';

    // Handle artist data which could be a string or a map
    if (song['artist'] is Map<String, dynamic>) {
      final artistMap = song['artist'] as Map<String, dynamic>;
      artist = (artistMap['name'] as String?) ?? 'Unknown Artist';
    } else if (song['artist'] is String) {
      artist = song['artist'] as String;
    } else {
      artist = 'Unknown Artist';
    }

    // Extract song ID with type safety
    songId = (song['id'] as String?) ?? '';
  }
} catch (e) {
  debugPrint('Error extracting song data: $e');
  // Fallback values are already set above
}
```

#### Key Features

- **Type Validation**: Checks data types before casting to prevent runtime errors
- **Flexible Artist Handling**: Supports both string and object artist representations
- **Graceful Degradation**: Provides meaningful fallback values when data is missing
- **Error Isolation**: Catches parsing errors without breaking the UI
- **Debug Logging**: Comprehensive logging for troubleshooting data issues

#### Benefits

- **Prevents Crashes**: Type-safe extraction prevents `TypeError` exceptions
- **Handles API Variations**: Accommodates different API response formats
- **Improves User Experience**: Shows meaningful fallback data instead of errors
- **Facilitates Debugging**: Clear error messages help identify data issues

## Development Guidelines

### Adding New Models

When creating new data models, follow these patterns:

1. **Constructor**: Include all required fields and sensible defaults
2. **fromJson**: Include comprehensive error handling and type casting
3. **toJson**: Return clean JSON suitable for API consumption
4. **Null Safety**: Handle all nullable fields appropriately
5. **Debug Logging**: Include debug prints for parsing errors

### Testing Models

Always test JSON parsing with:
- Valid complete data
- Missing optional fields
- Null values
- Invalid data types
- Malformed JSON

### Performance Considerations

- Use `debugPrint` instead of `print` for logging
- Implement lazy loading for large nested collections
- Consider using `compute` for heavy JSON parsing operations
- Cache parsed models when appropriate

## API Integration

### Request/Response Patterns

Models are designed to work seamlessly with the API:

```dart
// API Response -> Model
final response = await apiService.getSetlists();
final setlists = (response.data as List)
    .map((json) => Setlist.fromJson(json))
    .toList();

// Model -> API Request
final setlistJson = setlist.toJson();
await apiService.updateSetlist(setlist.id, setlistJson);
```

### Error Handling Integration

Models integrate with the app's error handling system:

```dart
try {
  final setlist = Setlist.fromJson(jsonData);
  return setlist;
} catch (e) {
  ErrorHandler.handleError(e, context: 'Parsing setlist data');
  return null;
}
```

This documentation will be updated as new models are added or existing models are modified.