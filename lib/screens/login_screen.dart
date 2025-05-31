import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/toast_util.dart';
import '../providers/user_provider.dart';
import '../providers/app_data_provider.dart';
import '../utils/page_transitions.dart';
import '../config/theme.dart';
import 'register_screen.dart';
import '../screens/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Create an instance of AuthService
  final AuthService _authService = AuthService();
  String? _errorMessage;

  // Separate loading states for different login methods
  bool _isEmailLoginLoading = false;
  bool _isGoogleLoginLoading = false;

  // Safe navigation method that doesn't use context across async gaps
  // and prevents navigation back after login
  void _safeNavigate(String route) {
    if (mounted) {
      debugPrint('LoginScreen: Navigating to $route');
      // Use a direct navigation approach to avoid issues
      // pushAndRemoveUntil removes all previous routes from the stack
      // preventing the user from going back to the login screen with the back button
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  // Safe toast method that doesn't use context across async gaps
  void _safeShowSuccessToast(String message) {
    if (mounted) {
      ToastUtil.showSuccess(context, message);
    }
  }

  // Safe toast method that doesn't use context across async gaps
  void _safeShowErrorToast(String message) {
    if (mounted) {
      ToastUtil.showError(context, message);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
        _isEmailLoginLoading = true; // Show loading indicator for email login
      });

      try {
        final result = await _authService.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

        if (!mounted) return;

        debugPrint('Login result: $result');

        // Check if the response contains a user object or success is true
        if (result['success'] == true ||
            (result['data'] != null &&
                result['message']?.contains('successful') == true)) {
          // Show success message
          _safeShowSuccessToast('Login successful');

          // Update user data in provider
          if (result['data'] != null) {
            await Provider.of<UserProvider>(
              context,
              listen: false,
            ).setUserData(result['data']);
          }

          // Initialize app data after successful login (non-blocking)
          if (mounted) {
            Provider.of<AppDataProvider>(context, listen: false)
                .initializeAfterLogin()
                .catchError((e) {
              debugPrint('Error initializing app data after login: $e');
            });
          }

          // Navigate to home screen
          _safeNavigate('/home');
        } else {
          // Show error message
          setState(() {
            _errorMessage = result['message'] ?? 'Login failed';

            // Make the error message more user-friendly
            if (_errorMessage!.contains('social login') ||
                _errorMessage!.contains(
                  'sign in with the appropriate provider',
                )) {
              _errorMessage =
                  'This account was created with Firebase. Please try again - we will now use Firebase authentication.';
            } else if (_errorMessage!.contains('wrong password') ||
                _errorMessage!.contains('password is invalid')) {
              _errorMessage = 'Incorrect password. Please try again.';
            } else if (_errorMessage!.contains('user not found') ||
                _errorMessage!.contains('no user record')) {
              _errorMessage =
                  'Account not found. Please check your email or register a new account.';
            }
          });
          _safeShowErrorToast(_errorMessage!);

          // No need for additional action - we've already updated the error message
        }
      } catch (e) {
        if (!mounted) return;

        // Show error message
        setState(() {
          _errorMessage = 'An error occurred during login';
        });
        _safeShowErrorToast(_errorMessage!);
      } finally {
        if (mounted) {
          setState(() {
            _isEmailLoginLoading =
                false; // Hide loading indicator for email login
          });
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isGoogleLoginLoading = true; // Show loading indicator for Google login
    });

    try {
      final result = await _authService.loginWithGoogle(
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      debugPrint('Google login result: $result');

      // Check if the response contains a user object or success is true
      if (result['success'] == true ||
          (result['data'] != null &&
              result['message']?.contains('successful') == true)) {
        // Show success message
        _safeShowSuccessToast('Login successful');

        // Update user data in provider
        if (result['data'] != null) {
          await Provider.of<UserProvider>(
            context,
            listen: false,
          ).setUserData(result['data']);
        }

        // Initialize app data after successful login (non-blocking)
        if (mounted) {
          Provider.of<AppDataProvider>(context, listen: false)
              .initializeAfterLogin()
              .catchError((e) {
            debugPrint('Error initializing app data after login: $e');
          });
        }

        // Navigate to home screen
        _safeNavigate('/home');
      } else {
        // Show error message
        setState(() {
          _errorMessage = result['message'] ?? 'Google login failed';

          // Make the error message more user-friendly
          if (_errorMessage!.contains('social login') ||
              _errorMessage!.contains(
                'sign in with the appropriate provider',
              )) {
            _errorMessage =
                'This account was created with a different method. Please try logging in with email and password.';
          }
        });
        _safeShowErrorToast(_errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message
      setState(() {
        _errorMessage = 'An error occurred during Google sign in';
      });
      _safeShowErrorToast(_errorMessage!);
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoginLoading =
              false; // Hide loading indicator for Google login
        });
      }
    }
  }

  Future<void> _loginWithApple() async {
    setState(() {
      _errorMessage = null;
    });

    final result = await _authService.loginWithApple(rememberMe: _rememberMe);

    if (!mounted) return;

    if (result['success'] == true) {
      // Navigate to home screen
      _safeNavigate('/home');
    } else {
      // Show error message
      setState(() {
        _errorMessage = result['message'] ?? 'Apple login failed';
      });
      _safeShowErrorToast(_errorMessage!);
    }
  }

  void _forgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  'Exit App',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Do you want to exit the app?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'No',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Use PopScope to handle back button presses
    // This prevents users from navigating back after logout
    return PopScope(
      canPop: false, // Disable default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Show exit confirmation dialog
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add some top padding instead of logo
                  const SizedBox(height: 50),

                  // Login text
                  const Center(
                    child: Text(
                      'Login to your account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Remember me and Forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember me checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),

                      // Forgot password
                      TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Forgot password ?',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton(
                    onPressed: _isEmailLoginLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isEmailLoginLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(height: 24),

                  // Or divider
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey, thickness: 0.5),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey, thickness: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Continue with Google
                  OutlinedButton.icon(
                    onPressed:
                        _isGoogleLoginLoading
                            ? null
                            : _loginWithGoogle, // Disable button when loading
                    // Using the Google image from assets
                    icon: Image.asset(
                      'assets/images/google.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    label:
                        _isGoogleLoginLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Continue with Apple
                  OutlinedButton.icon(
                    onPressed: _loginWithApple,
                    // Using a custom Apple icon
                    icon: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    label: const Text(
                      'Continue with Apple',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Don't have an account? Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account?',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            FadeSlidePageRoute(page: const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
