import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'constants.dart';

/// Centralized error handling for the entire application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Handle API errors and convert them to user-friendly messages
  static String handleApiError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Exception) {
      return _handleGenericException(error);
    } else {
      return _handleUnknownError(error);
    }
  }

  /// Handle Dio-specific errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppConstants.networkErrorMessage;
        
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check your internet connection.';
        
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode, error.response?.data);
        
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
        
      case DioExceptionType.unknown:
      default:
        return _extractErrorMessage(error.response?.data) ?? AppConstants.serverErrorMessage;
    }
  }

  /// Handle HTTP status code errors
  static String _handleHttpError(int? statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return _extractErrorMessage(responseData) ?? 'Invalid request. Please check your input.';
      case 401:
        return AppConstants.authErrorMessage;
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return _extractErrorMessage(responseData) ?? 'Conflict occurred. Please try again.';
      case 422:
        return _extractErrorMessage(responseData) ?? 'Invalid data provided.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return AppConstants.serverErrorMessage;
      default:
        return _extractErrorMessage(responseData) ?? 'An unexpected error occurred.';
    }
  }

  /// Extract error message from response data
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Try different common error message fields
      final message = responseData['message'] ?? 
                     responseData['error'] ?? 
                     responseData['detail'] ?? 
                     responseData['msg'];
      
      if (message is String) {
        return _makeUserFriendly(message);
      }
      
      // Handle validation errors
      if (responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return _makeUserFriendly(firstError.first.toString());
        }
      }
    }
    return null;
  }

  /// Make error messages more user-friendly
  static String _makeUserFriendly(String message) {
    // Convert technical messages to user-friendly ones
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('already exists')) {
      return 'This item already exists. Please try a different name.';
    }
    
    if (lowerMessage.contains('not found')) {
      return 'The requested item could not be found.';
    }
    
    if (lowerMessage.contains('unauthorized') || lowerMessage.contains('forbidden')) {
      return AppConstants.authErrorMessage;
    }
    
    if (lowerMessage.contains('validation') || lowerMessage.contains('invalid')) {
      return 'Please check your input and try again.';
    }
    
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return AppConstants.networkErrorMessage;
    }
    
    if (lowerMessage.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Return original message if no specific pattern matches
    return message;
  }

  /// Handle generic exceptions
  static String _handleGenericException(Exception error) {
    final message = error.toString();
    
    if (message.contains('SocketException')) {
      return AppConstants.networkErrorMessage;
    }
    
    if (message.contains('FormatException')) {
      return 'Invalid data format received from server.';
    }
    
    if (message.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    
    if (message.contains('Permission')) {
      return AppConstants.permissionErrorMessage;
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle unknown errors
  static String _handleUnknownError(dynamic error) {
    if (EnvironmentConstants.enableLogging) {
      debugPrint('Unknown error type: ${error.runtimeType} - $error');
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Log errors for debugging (only in debug mode)
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (EnvironmentConstants.enableLogging) {
      debugPrint('❌ Error in $context: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Handle and log errors with context
  static String handleErrorWithContext(String context, dynamic error) {
    logError(context, error);
    return handleApiError(error);
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout;
    }
    
    final message = error.toString().toLowerCase();
    return message.contains('socket') || 
           message.contains('network') || 
           message.contains('connection');
  }

  /// Check if error requires authentication
  static bool isAuthError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401 || error.response?.statusCode == 403;
    }
    
    final message = error.toString().toLowerCase();
    return message.contains('unauthorized') || 
           message.contains('forbidden') || 
           message.contains('authentication');
  }

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return statusCode == 429 || // Too many requests
                 statusCode == 500 || // Internal server error
                 statusCode == 502 || // Bad gateway
                 statusCode == 503 || // Service unavailable
                 statusCode == 504;   // Gateway timeout
        default:
          return false;
      }
    }
    
    return isNetworkError(error);
  }

  /// Get retry delay based on attempt number
  static Duration getRetryDelay(int attemptNumber) {
    // Exponential backoff: 1s, 2s, 4s, 8s...
    final delaySeconds = (1 << (attemptNumber - 1)).clamp(1, 30);
    return Duration(seconds: delaySeconds);
  }

  /// Create a standardized error result
  static Map<String, dynamic> createErrorResult(String message, {
    String? code,
    Map<String, dynamic>? details,
  }) {
    return {
      'success': false,
      'message': message,
      if (code != null) 'code': code,
      if (details != null) 'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create a standardized success result
  static Map<String, dynamic> createSuccessResult(dynamic data, {
    String? message,
  }) {
    return {
      'success': true,
      'data': data,
      if (message != null) 'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
