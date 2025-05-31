import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../models/song.dart';
import '../services/comment_service.dart';
import '../widgets/skeleton_loader.dart';
import '../config/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsScreen extends StatefulWidget {
  final Song song;

  const CommentsScreen({super.key, required this.song});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();

  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _commentService.getCommentsForSong(widget.song.id);

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _comments = []; // Ensure we have an empty list, not null
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading comments: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadComments,
            ),
          ),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final text = _commentController.text.trim();
    _commentController.clear();

    try {
      if (_replyingToId != null) {
        // Adding a reply
        final reply = await _commentService.addReply(
          widget.song.id,
          _replyingToId!,
          text
        );

        setState(() {
          // Find the parent comment and add the reply
          for (int i = 0; i < _comments.length; i++) {
            if (_comments[i].id == _replyingToId) {
              final updatedReplies = List<Comment>.from(_comments[i].replies)..add(reply);
              _comments[i] = Comment(
                id: _comments[i].id,
                songId: _comments[i].songId,
                customerId: _comments[i].customerId,
                customerName: _comments[i].customerName,
                customerProfilePicture: _comments[i].customerProfilePicture,
                text: _comments[i].text,
                createdAt: _comments[i].createdAt,
                updatedAt: _comments[i].updatedAt,
                likesCount: _comments[i].likesCount,
                isLiked: _comments[i].isLiked,
                replies: updatedReplies,
                isDeleted: _comments[i].isDeleted,
                deletedAt: _comments[i].deletedAt,
                parentId: _comments[i].parentId,
              );
              // Update the comment count in the song object
              widget.song.commentCount += 1;
              break;
            }
          }
          _replyingToId = null;
          _replyingToName = null;
        });
      } else {
        // Adding a new comment
        final comment = await _commentService.addComment(widget.song.id, text);
        setState(() {
          _comments = [comment, ..._comments];
          // Update the comment count in the song object
          widget.song.commentCount += 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _addComment,
            ),
          ),
        );
      }
    }
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      _replyingToId = commentId;
      _replyingToName = authorName;
    });
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
  }

  Future<void> _toggleLike(Comment comment) async {
    try {
      if (comment.isLiked) {
        await _commentService.unlikeComment(comment.id);
      } else {
        await _commentService.likeComment(comment.id);
      }

      // Update the UI optimistically
      setState(() {
        for (int i = 0; i < _comments.length; i++) {
          if (_comments[i].id == comment.id) {
            _comments[i] = Comment(
              id: comment.id,
              songId: comment.songId,
              customerId: comment.customerId,
              customerName: comment.customerName,
              customerProfilePicture: comment.customerProfilePicture,
              text: comment.text,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              replies: comment.replies,
              likesCount: comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
              isLiked: !comment.isLiked,
              isDeleted: comment.isDeleted,
              deletedAt: comment.deletedAt,
              parentId: comment.parentId,
            );
            break;
          }

          // Check in replies
          for (int j = 0; j < _comments[i].replies.length; j++) {
            if (_comments[i].replies[j].id == comment.id) {
              final updatedReplies = List<Comment>.from(_comments[i].replies);
              updatedReplies[j] = Comment(
                id: comment.id,
                songId: comment.songId,
                customerId: comment.customerId,
                customerName: comment.customerName,
                customerProfilePicture: comment.customerProfilePicture,
                text: comment.text,
                createdAt: comment.createdAt,
                updatedAt: comment.updatedAt,
                replies: [],
                likesCount: comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
                isLiked: !comment.isLiked,
                isDeleted: comment.isDeleted,
                deletedAt: comment.deletedAt,
                parentId: comment.parentId,
              );
              _comments[i] = Comment(
                id: _comments[i].id,
                songId: _comments[i].songId,
                customerId: _comments[i].customerId,
                customerName: _comments[i].customerName,
                customerProfilePicture: _comments[i].customerProfilePicture,
                text: _comments[i].text,
                createdAt: _comments[i].createdAt,
                updatedAt: _comments[i].updatedAt,
                likesCount: _comments[i].likesCount,
                isLiked: _comments[i].isLiked,
                replies: updatedReplies,
                isDeleted: _comments[i].isDeleted,
                deletedAt: _comments[i].deletedAt,
                parentId: _comments[i].parentId,
              );
              break;
            }
          }
        }
      });
    } catch (e) {
      if (mounted) {
        // Revert the optimistic update
        _loadComments(); // Reload all comments to get the correct state

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating like status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Build comments skeleton loading
  Widget _buildCommentsSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // Show 6 skeleton comments
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ShimmerEffect(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar skeleton
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Comment content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username skeleton
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Comment text skeleton
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 200,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time and actions skeleton
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 30,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          'Comments - ${widget.song.title}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: _isLoading
                ? _buildCommentsSkeleton()
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
          ),

          // Reply indicator
          if (_replyingToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E1E1E),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to $_replyingToName',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: Color(0xFF333333), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _replyingToId != null
                          ? 'Write a reply...'
                          : 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF333333),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _addComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF333333),
                backgroundImage: comment.customerProfilePicture != null
                    ? NetworkImage(comment.customerProfilePicture!)
                    : null,
                child: comment.customerProfilePicture == null
                    ? Text(
                        comment.customerName.isNotEmpty
                            ? comment.customerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment header
                    Row(
                      children: [
                        Text(
                          comment.customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(comment.createdAt),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Comment text
                    Text(
                      comment.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    // Comment actions
                    Row(
                      children: [
                        // Like button
                        InkWell(
                          onTap: () => _toggleLike(comment),
                          child: Row(
                            children: [
                              Icon(
                                comment.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: comment.isLiked
                                    ? Colors.red
                                    : Colors.white54,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                comment.likesCount.toString(),
                                style: TextStyle(
                                  color: comment.isLiked
                                      ? Colors.red
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Reply button
                        InkWell(
                          onTap: () => _startReply(comment.id, comment.customerName),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.reply,
                                color: Colors.white54,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Replies
        if (comment.replies.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 52),
            child: Column(
              children: comment.replies.map((reply) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF333333),
                        backgroundImage: reply.customerProfilePicture != null
                            ? NetworkImage(reply.customerProfilePicture!)
                            : null,
                        child: reply.customerProfilePicture == null
                            ? Text(
                                reply.customerName.isNotEmpty
                                    ? reply.customerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reply header
                            Row(
                              children: [
                                Text(
                                  reply.customerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeago.format(reply.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Reply text
                            Text(
                              reply.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Reply actions
                            Row(
                              children: [
                                // Like button
                                InkWell(
                                  onTap: () => _toggleLike(reply),
                                  child: Row(
                                    children: [
                                      Icon(
                                        reply.isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: reply.isLiked
                                            ? Colors.red
                                            : Colors.white54,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        reply.likesCount.toString(),
                                        style: TextStyle(
                                          color: reply.isLiked
                                              ? Colors.red
                                              : Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Reply button
                                InkWell(
                                  onTap: () => _startReply(comment.id, reply.customerName),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.reply,
                                        color: Colors.white54,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Reply',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Divider between comments
        const Divider(color: Color(0xFF333333)),
      ],
    );
  }
}
