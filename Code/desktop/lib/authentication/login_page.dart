import 'package:car_care/authentication/base_auth_page.dart';
import 'package:car_care/authentication/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:car_care/providers/auth_provider.dart' as app_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Load saved credentials if they exist
    _loadSavedCredentials();
  }

  // Load saved email and remember me status
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final rememberMe = prefs.getBool('remember_me') ?? false;
      
      if (savedEmail != null && rememberMe) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignore errors during loading
      debugPrint('Error loading saved credentials: $e');
    }
  }

  // Save email and remember me status
  Future<void> _saveCredentials(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', email);
        await prefs.setBool('remember_me', true);
      } else {
        // If remember me is turned off, clear saved credentials
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  void _login() async {
    // Reset error messages
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Special case for admin login
    if (email == 'admin' && password == 'admin') {
      await Provider.of<app_auth.AuthProvider>(context, listen: false).adminLogin();
      
      // Save credentials if remember me is checked
      if (_rememberMe) {
        await _saveCredentials(email);
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
      return;
    }

    try {
      // Use direct Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Save credentials if remember me is checked
      if (_rememberMe) {
        await _saveCredentials(email);
      }
      
      // If login successful, navigate to home
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        
        if (e.code == 'user-not-found') {
          setState(() => _emailError = 'No user found for that email.');
        } else if (e.code == 'wrong-password') {
          setState(() => _passwordError = 'Wrong password provided for that user.');
        } else if (e.code == 'invalid-email') {
          setState(() => _emailError = 'The email address is not valid.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return BaseAuthPage(
      images: const [
        'assets/image/Landing_Page_0.jpg',
        'assets/image/Landing_Page_1.jpg',
        'assets/image/Landing_Page_2.jpg',
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.directions_car_rounded,
                  size: 60,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Welcome text
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF434343)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 36),
            
            // Login form
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email field
                    const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _emailError != null ? Colors.red : Colors.grey.shade200),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (value) => 
                          (value == null || value.isEmpty) ? 'Please enter your email' :
                          (!_validateEmail(value)) ? 'Please enter a valid email address' : null,
                        decoration: InputDecoration(
                          hintText: 'Enter your Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded, color: Colors.grey.shade500, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          errorText: _emailError,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Password field
                    const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _passwordError != null ? Colors.red : Colors.grey.shade200),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
                        decoration: InputDecoration(
                          hintText: 'Enter your Password',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                          errorText: _passwordError,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Remember me and forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                side: BorderSide(color: Colors.grey.shade300),
                                activeColor: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Remember me', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                          ],
                        ),
                        TextButton(
                          onPressed: _navigateToForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Login button
            Container(
              width: 400,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Colors.black, Color(0xFF333333)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.transparent,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Sign up link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                TextButton(
                  onPressed: _navigateToRegister,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
