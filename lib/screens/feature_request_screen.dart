import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/feature_request.dart';
import '../services/feature_request_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class FeatureRequestScreen extends StatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final FeatureRequestService _featureRequestService = FeatureRequestService();
  List<FeatureRequest> _featureRequests = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
    _fetchFeatureRequests();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app is resumed
      _fetchFeatureRequests();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the screen becomes visible after navigation
    _fetchFeatureRequests();
  }

  @override
  bool get wantKeepAlive => true;

  void _checkLoginStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isLoggedIn = userProvider.isLoggedIn;
    });
  }

  Future<void> _fetchFeatureRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _featureRequestService.getAllFeatureRequests();

      // Debug the hasUpvoted property for each request
      debugPrint('📋 Loaded ${requests.length} feature requests from API:');
      for (var request in requests) {
        debugPrint(
          '  💡 ${request.title} - hasUpvoted: ${request.hasUpvoted} (${request.upvotes} votes)',
        );
      }

      setState(() {
        // Use the server state directly - it already includes the correct hasUpvoted status from the database
        _featureRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching feature requests: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load feature requests');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _showAddFeatureRequestBottomSheet() {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => _AddFeatureRequestForm(
            onFeatureRequestAdded: (newRequest) {
              setState(() {
                _featureRequests.add(newRequest);
              });
              _showSuccessSnackBar('Feature request submitted successfully');
            },
          ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Login Required',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'You need to be logged in to request features.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleUpvote(FeatureRequest request) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    debugPrint(
      'Handling upvote for feature request: ${request.id} - Current hasUpvoted: ${request.hasUpvoted}',
    );

    // Toggle the upvote state
    bool newUpvoteState = !request.hasUpvoted;
    int newUpvoteCount =
        newUpvoteState ? request.upvotes + 1 : request.upvotes - 1;

    // Ensure upvote count doesn't go below 0
    if (newUpvoteCount < 0) newUpvoteCount = 0;

    // Create updated request object
    final updatedRequest = FeatureRequest(
      id: request.id,
      title: request.title,
      description: request.description,
      category: request.category,
      priority: request.priority,
      status: request.status,
      upvotes: newUpvoteCount,
      customerId: request.customerId,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      hasUpvoted: newUpvoteState, // Set to the new state
    );

    // Update UI immediately
    setState(() {
      final index = _featureRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _featureRequests[index] = updatedRequest;
        debugPrint(
          'Updated UI for feature request: ${request.id} - New hasUpvoted: $newUpvoteState',
        );
      }
    });

    // Make API call in the background
    try {
      bool success;

      if (newUpvoteState) {
        // Adding an upvote
        success = await _featureRequestService.upvoteFeatureRequest(request.id);
        debugPrint('Added upvote, success: $success');
      } else {
        // Removing an upvote
        success = await _featureRequestService.removeUpvote(request.id);
        debugPrint('Removed upvote, success: $success');
      }

      if (success) {
        // If successful, refresh the feature requests list from the server
        // to ensure we have the correct upvote state
        await _fetchFeatureRequests();
        debugPrint('Refreshed feature requests after successful upvote toggle');
      } else {
        // If API call failed, check if it's because the user already upvoted
        final alreadyUpvoted = await _featureRequestService
            .checkIfAlreadyUpvoted(request.id);

        if (alreadyUpvoted) {
          // If already upvoted, show info notification instead of error
          debugPrint('User has already upvoted this feature request');
          _showInfoSnackBar('You have already voted for this feature');
          // Refresh data to ensure UI is correct
          await _fetchFeatureRequests();
          return;
        }

        // For other errors, revert the UI change
        debugPrint('API call failed, reverting UI change');
        setState(() {
          final index = _featureRequests.indexWhere((r) => r.id == request.id);
          if (index != -1) {
            final revertedRequest = FeatureRequest(
              id: request.id,
              title: request.title,
              description: request.description,
              category: request.category,
              priority: request.priority,
              status: request.status,
              upvotes: request.upvotes, // Original upvote count
              customerId: request.customerId,
              createdAt: request.createdAt,
              updatedAt: request.updatedAt,
              hasUpvoted: request.hasUpvoted, // Original upvote state
            );
            _featureRequests[index] = revertedRequest;
          }
        });
        _showErrorSnackBar('Failed to update upvote');
      }
    } catch (e) {
      debugPrint('Exception during upvote API call: $e');
      // Revert the UI change on exception
      setState(() {
        final index = _featureRequests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          final revertedRequest = FeatureRequest(
            id: request.id,
            title: request.title,
            description: request.description,
            category: request.category,
            priority: request.priority,
            status: request.status,
            upvotes: request.upvotes, // Original upvote count
            customerId: request.customerId,
            createdAt: request.createdAt,
            updatedAt: request.updatedAt,
            hasUpvoted: request.hasUpvoted, // Original upvote state
          );
          _featureRequests[index] = revertedRequest;
        }
      });
      _showErrorSnackBar('Failed to update upvote');
    }
  }

  Widget _buildFeatureRequestItem(FeatureRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showFeatureRequestDetails(request),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Upvote button and count
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _handleUpvote(request),
                        child: Icon(
                          request.hasUpvoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          color:
                              request.hasUpvoted
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.upvotes}',
                        style: TextStyle(
                          color:
                              request.hasUpvoted
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (request.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.categoryDisplayName,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        request.status,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.statusDisplayName,
                      style: TextStyle(
                        color: _getStatusColor(request.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeatureRequestDetails(FeatureRequest request) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          request.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status and category
                  Wrap(
                    spacing: 8,
                    children: [
                      if (request.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.categoryDisplayName,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            request.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          request.statusDisplayName,
                          style: TextStyle(
                            color: _getStatusColor(request.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppTheme.primaryFontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.description,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Upvote section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Submitted on ${_formatDate(request.createdAt)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${request.upvotes} votes',
                            style: TextStyle(
                              color:
                                  request.hasUpvoted
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppTheme.primaryFontFamily,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _handleUpvote(request);
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              request.hasUpvoted
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 18,
                              color: Colors.black,
                            ),
                            label: Text(
                              request.hasUpvoted ? 'Upvoted' : 'Upvote',
                              style: const TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  request.hasUpvoted
                                      ? AppTheme.primary.withValues(alpha: 0.2)
                                      : AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'UNDER_REVIEW':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Feature'),
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Header with explanation text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Suggest new features or improvements for the app. Other users can upvote your suggestions to show support. The most popular requests will be prioritized for development.',
              style: const TextStyle(
                color: Color(0xB3FFFFFF), // White with 70% opacity
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Add feature request button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddFeatureRequestBottomSheet,
                icon: const Icon(Icons.add),
                label: const Text('Request New Feature'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Feature request list
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : _featureRequests.isEmpty
                    ? Center(
                      child: const Text(
                        'No feature requests yet',
                        style: TextStyle(
                          color: Color(0xB3FFFFFF), // White with 70% opacity
                          fontSize: 16,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchFeatureRequests,
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView.builder(
                        itemCount: _featureRequests.length,
                        itemBuilder: (context, index) {
                          final request = _featureRequests[index];
                          return _buildFeatureRequestItem(request);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _AddFeatureRequestForm extends StatefulWidget {
  final Function(FeatureRequest) onFeatureRequestAdded;

  const _AddFeatureRequestForm({required this.onFeatureRequestAdded});

  @override
  State<_AddFeatureRequestForm> createState() => _AddFeatureRequestFormState();
}

class _AddFeatureRequestFormState extends State<_AddFeatureRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FeatureRequestService _featureRequestService = FeatureRequestService();

  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'NEW_FEATURE', 'label': 'New Feature'},
    {'value': 'UI_UX', 'label': 'UI/UX Improvement'},
    {'value': 'PERFORMANCE', 'label': 'Performance'},
    {'value': 'BUG_FIX', 'label': 'Bug Fix'},
    {'value': 'INTEGRATION', 'label': 'Integration'},
    {'value': 'SECURITY', 'label': 'Security'},
    {'value': 'OTHER', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeatureRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newRequest = await _featureRequestService.createFeatureRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );

      if (newRequest != null) {
        widget.onFeatureRequestAdded(newRequest);
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Failed to submit feature request');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Request New Feature',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title field
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Feature Title *',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Brief title for your feature request',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a feature title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters long';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description *',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Describe your feature request in detail',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters long';
                }
                return null;
              },
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              dropdownColor: const Color(0xFF1E1E1E),
              items:
                  _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Text(
                        category['label']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeatureRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                      : const Text(
                        'Submit Feature Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
