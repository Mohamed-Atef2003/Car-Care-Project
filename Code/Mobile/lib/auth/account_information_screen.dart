import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/edit_profile_screen.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/services/preferences_service.dart';
import 'package:flutter_application_1/widgets/custom_button.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() => _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  bool _isLoading = true;
  bool _isResettingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.user == null) {
      // If user data is not loaded yet, load it
      await userProvider.loadUser();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword(String email) async {
    try {
      setState(() {
        _isResettingPassword = true;
      });
      
      // Send password reset link via email
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link has been sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = 'Failed to send password reset instructions';
        
        if (error is FirebaseAuthException) {
          if (error.code == 'user-not-found') {
            errorMessage = 'No user found with this email address';
          } else if (error.code == 'invalid-email') {
            errorMessage = 'Invalid email address';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    ).then((_) {
      // No need to reload data as Provider will handle the update automatically
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account Information'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  
                  if (user == null) {
                    return const Center(
                      child: Text('User data not found'),
                    );
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Profile picture
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: const AssetImage('assets/image/7309681.jpg'),
                          // If you have a network image, use:
                          // backgroundImage: NetworkImage(userImageUrl),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // User name
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Information cards
                        _buildInfoCard(Icons.email, 'Email', user.email),
                        const SizedBox(height: 12),
                        _buildInfoCard(Icons.phone, 'Mobile', user.mobile),
                        
                        const Spacer(),
                        
                        // Edit profile button
                        CustomButton(
                          onPressed: _navigateToEditProfile,
                          text: 'Edit Profile',
                          isFullWidth: true,
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Change password button
                        CustomButton(
                          onPressed: _isResettingPassword 
                              ? () {}
                              : () {
                                  _resetPassword(user.email);
                                },
                          text: _isResettingPassword 
                              ? 'Sending link...' 
                              : 'Change Password',
                          isFullWidth: true,
                          isprimaryLight: true,
                          icon: _isResettingPassword 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock, color: Colors.white),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Logout button
                        CustomButton(
                          onPressed: () async {
                            // Sign out
                            userProvider.logout();
                            // Save logout state
                            await PreferencesService.logout();
                            // Navigate to login screen
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            }
                          },
                          text: 'Sign Out',
                          isFullWidth: true,
                          isOutlined: true,
                          icon: const Icon(Icons.logout, color: AppColors.primary),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 