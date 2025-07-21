import 'package:flutter/material.dart';
import '../../constants/colors.dart';
// import '../../models/user_model.dart' as LocalModels;
import 'login_screen.dart';
import 'terms_conditions_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _AddUserDetails(String firstName, String lastName, String email,
      String mobile) async {
 await FirebaseFirestore.instance.collection('customer_account').add({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
  
    });
  }

  

  Future<void> _validateAndSubmit() async {
    if (!_acceptTerms) {
      _showErrorMessage('Please accept the terms and conditions');
      return;
    }

    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorMessage('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showErrorMessage('Please enter a valid email');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorMessage('Password must be at least 6 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorMessage('Passwords do not match');
      return;
    }

    try {
      // Create user with Firebase Authentication
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If Firebase authentication is successful, send email verification and save user to local database
      if (userCredential.user != null) {
        final user = userCredential.user;
        // Send email verification
        await user?.sendEmailVerification();
        _AddUserDetails(
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _emailController.text.trim(),
          _mobileController.text.trim(),
        
        );
        // final newUser = LocalModels.User(
        //   firstName: _firstNameController.text.trim(),
        //   lastName: _lastNameController.text.trim(),
        //   email: _emailController.text.trim(),
        //   mobile: _mobileController.text.trim(),
        //   password: _passwordController.text.trim(),
        // );

        // await DatabaseHelper.instance.registerUser(newUser);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // Handle Firebase specific errors
      String errorMessage = 'An error occurred. Please try again.';
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'The email address is already in use.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password is too weak.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is invalid.';
        }
      }
      _showErrorMessage(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sign UP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const Text(
                  'Welcome in My Store',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          hintText: 'First Name',
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          hintText: 'Last Name',
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Mobile',
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TermsConditionsScreen(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'I accept the ',
                            style: const TextStyle(color: AppColors.grey),
                            children: [
                              TextSpan(
                                text: 'terms and conditions',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _validateAndSubmit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SIGN UP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
