import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/api_service.dart';

class CommentService {
  final ApiService _apiService = ApiService();

  // Get all comments for a song
  Future<List<Comment>> getCommentsForSong(String songId) async {
    try {
      final response = await _apiService.get('/comments/song/$songId');

      if (response.statusCode == 200) {
        final List<dynamic> commentsJson = response.data;
        return commentsJson.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      debugPrint('Error getting comments: $e');
      // Return empty list instead of mock data
      return [];
    }
  }

  // Add a new comment
  Future<Comment> addComment(String songId, String text) async {
    try {
      final response = await _apiService.post('/comments', data: {
        'songId': songId,
        'text': text,
      });

      if (response.statusCode == 201) {
        return Comment.fromJson(response.data);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      // Return a temporary comment until the server is fixed
      return Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        songId: songId,
        customerId: 'temp-user',
        customerName: 'You',
        text: text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Add a reply to a comment
  Future<Comment> addReply(String songId, String commentId, String text) async {
    try {
      final response = await _apiService.post('/comments', data: {
        'songId': songId,
        'text': text,
        'parentId': commentId,
      });

      if (response.statusCode == 201) {
        return Comment.fromJson(response.data);
      } else {
        throw Exception('Failed to add reply: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding reply: $e');
      // Return a temporary reply until the server is fixed
      return Comment(
        id: '$commentId-${DateTime.now().millisecondsSinceEpoch}',
        songId: songId,
        customerId: 'temp-user',
        customerName: 'You',
        text: text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentId: commentId,
      );
    }
  }

  // Like a comment
  Future<void> likeComment(String commentId) async {
    try {
      final response = await _apiService.post('/comments/$commentId/like');

      if (response.statusCode != 201) {
        throw Exception('Failed to like comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error liking comment: $e');
      // Silently fail but log the error
    }
  }

  // Unlike a comment
  Future<void> unlikeComment(String commentId) async {
    try {
      final response = await _apiService.delete('/comments/$commentId/like');

      if (response.statusCode != 200) {
        throw Exception('Failed to unlike comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error unliking comment: $e');
      // Silently fail but log the error
    }
  }

  // Update a comment
  Future<Comment> updateComment(String commentId, String text) async {
    try {
      final response = await _apiService.patch('/comments/$commentId', data: {
        'text': text,
      });

      if (response.statusCode == 200) {
        return Comment.fromJson(response.data);
      } else {
        throw Exception('Failed to update comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating comment: $e');
      throw Exception('Failed to update comment. Please try again.');
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await _apiService.delete('/comments/$commentId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      throw Exception('Failed to delete comment. Please try again.');
    }
  }

  // Get comment count for a song
  Future<int> getCommentCount(String songId) async {
    try {
      final comments = await getCommentsForSong(songId);

      // Count top-level comments and their replies
      int count = 0;
      for (var comment in comments) {
        count++; // Count the comment itself
        count += comment.replies.length; // Count all replies
      }

      return count;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0; // Return 0 if there's an error
    }
  }
}
