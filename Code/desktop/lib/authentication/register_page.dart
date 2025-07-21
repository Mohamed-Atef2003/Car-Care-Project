import 'package:car_care/authentication/base_auth_page.dart';
import 'package:car_care/authentication/login_page.dart';
import 'package:car_care/authentication/terms_page.dart';
import 'package:car_care/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final List<String> backgroundImages = [
    'assets/image/Register0.png',
    'assets/image/Register1.png',
    'assets/image/Register2.png',
  ];

  bool termsAccepted = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _emailError;
  String? _passwordError;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Enter password';
  Color _passwordStrengthColor = Colors.grey;


  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.removeListener(_checkPasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = 'Enter password';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }
    
    double strength = 0;
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]')) && 
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      strength += 0.1;
    }
    
    if (strength > 1.0) strength = 1.0;
    
    String strengthText;
    Color strengthColor;
    
    if (strength < 0.3) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
    } else if (strength < 0.7) {
      strengthText = 'Medium';
      strengthColor = Colors.orange;
    } else {
      strengthText = 'Strong';
      strengthColor = Colors.green;
    }
    
    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
      _passwordStrengthColor = strengthColor;
    });
  }

  void _register() async {
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
    
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Use direct FirebaseAuth as requested
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Update user info in Firestore
      try {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'isAdmin': true,
          'lastSeen': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        });
        
        // Send verification email
        await userCredential.user!.sendEmailVerification();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please check your email for verification.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } catch (error) {
        // If Firestore save fails, delete the account
        await userCredential.user?.delete();
        throw Exception('Failed to save user data');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        setState(() => _passwordError = 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        setState(() => _emailError = 'The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        setState(() => _emailError = 'The email address is not valid.');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      HapticFeedback.mediumImpact();
      
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return BaseAuthPage(
      images: backgroundImages,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create an Account',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign up to get started',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            
            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a username',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) => 
                (value == null || value.isEmpty) ? 'Please enter a username' :
                (value.length < 3) ? 'Username must be at least 3 characters' : null,
            ),
            const SizedBox(height: 16),
            
            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                errorText: _emailError,
              ),
              validator: (value) => 
                (value == null || value.isEmpty) ? 'Please enter your email' :
                (!_validateEmail(value)) ? 'Please enter a valid email' : null,
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() => _emailError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                errorText: _passwordError,
              ),
              validator: (value) => 
                (value == null || value.isEmpty) ? 'Please enter a password' :
                (value.length < 6) ? 'Password must be at least 6 characters' : null,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            
            // Password strength indicator
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _passwordStrengthText,
                  style: TextStyle(
                    color: _passwordStrengthColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Confirm password field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) => 
                (value == null || value.isEmpty) ? 'Please confirm your password' :
                (value != _passwordController.text) ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 16),
            
            // Terms and conditions checkbox
            Row(
              children: [
                Checkbox(
                  value: termsAccepted,
                  onChanged: (value) {
                    setState(() {
                      termsAccepted = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text('I agree to the '),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const TermsPage(),
                          );
                        },
                        child: const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Register button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.textPrimary ,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
