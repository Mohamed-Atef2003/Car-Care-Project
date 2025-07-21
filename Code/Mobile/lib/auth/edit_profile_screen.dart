import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/providers/user_provider.dart';
import 'package:flutter_application_1/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _mobileController.text = user.mobile;
    } else {
      // If we don't have user data, load it
      userProvider.loadUser().then((_) {
        if (mounted) {
          final updatedUser = userProvider.user;
          if (updatedUser != null) {
            _firstNameController.text = updatedUser.firstName;
            _lastNameController.text = updatedUser.lastName;
            _emailController.text = updatedUser.email;
            _mobileController.text = updatedUser.mobile;
          }
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Create updated user object
        final currentUser = Provider.of<UserProvider>(context, listen: false).user;
        User updatedUser = User(
          id: currentUser?.id,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          mobile: _mobileController.text,
          password: currentUser?.password ?? "", // Keep the current password
        );
  
        // Save user data through provider
        await Provider.of<UserProvider>(context, listen: false).updateUser(updatedUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error occurred: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Profile picture
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: const AssetImage('assets/image/7309681.jpg'),
                        // If you have a network image, use:
                        // backgroundImage: NetworkImage(userImageUrl),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            onPressed: () {
                              // TODO: Implement image picker functionality
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
  
                  const SizedBox(height: 30),
                  
                  // First Name field
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Last Name field
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                    readOnly: true,
                    enabled: false,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Phone field
                  TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Save button
                  _isLoading 
                      ? const CircularProgressIndicator()
                      : CustomButton(
                          onPressed: _saveProfile,
                          text: 'Save Changes',
                          isFullWidth: true,
                          icon: const Icon(Icons.save, color: Colors.white),
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