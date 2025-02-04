import 'package:cf_buddy/services.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  bool isLogin = true;
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _handleController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Error states
  String? _emailError;
  String? _handleError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _handleController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() async {
    await _animationController.forward();
    setState(() {
      isLogin = !isLogin;
      _emailController.clear();
      _handleController.clear();
      _passwordController.clear();
      // Clear errors
      _emailError = null;
      _handleError = null;
      _passwordError = null;
    });
    await _animationController.reverse();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      // Reset errors
      _emailError = null;
      _handleError = null;
      _passwordError = null;

      // Validate email if signing up
      if (!isLogin) {
        if (_emailController.text.isEmpty) {
          _emailError = 'Please enter your email';
          isValid = false;
        } else if (!_emailController.text.contains('@')) {
          _emailError = 'Please enter a valid email';
          isValid = false;
        }
      }

      // Validate handle
      if (_handleController.text.isEmpty) {
        _handleError = 'Please enter your handle';
        isValid = false;
      }

      // Validate password
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Please enter your password';
        isValid = false;
      } else if (!isLogin && _passwordController.text.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        isValid = false;
      }
    });
    return isValid;
  }

  void loginUser() {
    if (!_validateInputs()) return;
    print("Login");
    _authService.signInUser(
      context: context,
      handle: _handleController.text,
      password: _passwordController.text,
    );
  }

  void signUpUser() {
    if (!_validateInputs()) return;
    print("Sign Up");
    _authService.signUpUser(
      context: context,
      email: _emailController.text,
      handle: _handleController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green[400]?.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.code_rounded,
                        size: 64,
                        color: Colors.green[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'CodeForces Companion',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[100],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin ? 'Welcome back!' : 'Create your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 48),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isLogin) ...[
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                errorText: _emailError,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildTextField(
                              controller: _handleController,
                              label: 'Codeforces Handle',
                              icon: Icons.person_outline,
                              errorText: _handleError,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: !_isPasswordVisible,
                              errorText: _passwordError,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLogin ? loginUser : signUpUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[400],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.grey[100],
                                        ),
                                      )
                                    : Text(
                                        isLogin ? 'Sign In' : 'Create Account',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _toggleAuthMode,
                                  child: Text(
                                    isLogin ? 'Sign Up' : 'Sign In',
                                    style: TextStyle(
                                      color: Colors.green[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null 
                ? Colors.red[400]!.withOpacity(0.5) 
                : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(
              color: Colors.grey[100],
              decoration: TextDecoration.none,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                icon, 
                color: errorText != null ? Colors.red[400] : Colors.grey[400],
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}