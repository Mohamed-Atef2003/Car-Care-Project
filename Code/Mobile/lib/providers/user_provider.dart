import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  // Load user data from Firestore using email
  Future<void> loadUserFromFirestore(String email) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customer_account')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data() as Map<String, dynamic>;
        
        _user = User(
          id: snapshot.docs.first.id,
          firstName: userData['firstName'] ?? '',
          lastName: userData['lastName'] ?? '',
          email: userData['email'] ?? '',
          mobile: userData['mobile'] ?? '',
          password: '',
        );
        
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user from Firestore: $e');
    }
  }

  // Load user data from Firebase Auth
  Future<void> loadUser() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    
    if (firebaseUser != null) {
      // Try to load data from Firestore first
      await loadUserFromFirestore(firebaseUser.email ?? '');
      
      // If no data found in Firestore, use Firebase Auth data
      if (_user == null) {
        _user = User(
          id: firebaseUser.uid, // Use Firebase user ID directly
          firstName: firebaseUser.displayName?.split(' ').first ?? '',
          lastName: firebaseUser.displayName?.split(' ').last ?? '',
          email: firebaseUser.email ?? '',
          mobile: firebaseUser.phoneNumber ?? '',
          password: '', // We don't store the password
        );
        
        notifyListeners();
      }
    }
  }

  // Set user data directly
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Update user data
  Future<void> updateUser(User updatedUser) async {
    try {
      // Update data in Firestore
      if (updatedUser.id != null) {
        await FirebaseFirestore.instance
            .collection('customer_account')
            .doc(updatedUser.id)
            .update({
          'firstName': updatedUser.firstName,
          'lastName': updatedUser.lastName,
          'email': updatedUser.email,
          'mobile': updatedUser.mobile,
        });
      }
      
      // Update local user data
      _user = updatedUser;
      
      // Notify listeners of the change
      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  // Logout
  void logout() {
    _user = null;
    notifyListeners();
  }
} 