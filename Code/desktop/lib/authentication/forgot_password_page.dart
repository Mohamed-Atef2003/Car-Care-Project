import 'package:car_care/authentication/base_auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _emailError;
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email);
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  void _sendPasswordResetEmail() async {
    // Reset error message
    setState(() {
      _emailError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _resetEmailSent = true;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        // Vibrate if available
        HapticFeedback.mediumImpact();
        
        setState(() {
          _isLoading = false;
          _emailError = _getFirebaseAuthErrorMessage(error);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseAuthPage(
      images: const [
        'assets/image/Landing_Page_0.jpg',
        'assets/image/Landing_Page_1.jpg',
        'assets/image/Landing_Page_2.jpg',
      ],
      child: _resetEmailSent ? _buildSuccessContent() : _buildRequestForm(),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        Text(
          'Reset Email Sent!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a password reset link to:',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Please check your email and follow the instructions to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Return to Login'),
        ),
      ],
    );
  }

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address to receive a password reset link',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          
          // Email Field
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!_validateEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Reset Password Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendPasswordResetEmail,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
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
                      'Reset Password',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Back to Login Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 