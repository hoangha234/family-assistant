import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Exception for auth service errors
class AuthServiceException implements Exception {
  final String message;
  final String? code;

  AuthServiceException(this.message, {this.code});

  @override
  String toString() => 'AuthServiceException: $message';
}

/// Service for handling Firebase Authentication
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Disable app verification for development/testing
      // This helps bypass reCAPTCHA on emulators and debug builds
      await _firebaseAuth.setSettings(
        appVerificationDisabledForTesting: true,
        forceRecaptchaFlow: false,
      );
      debugPrint('[AuthService] Auth settings configured successfully');
    } catch (e) {
      debugPrint('[AuthService] Failed to set auth settings: $e');
    }
  }

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Login with email and password
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] Attempting login for: $email');
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('[AuthService] Login successful for: ${credential.user?.email}');

      if (credential.user == null) {
        throw AuthServiceException('Login failed: No user returned');
      }

      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthServiceException(
        _getErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      if (e is AuthServiceException) rethrow;
      throw AuthServiceException('Login failed: $e');
    }
  }

  /// Register with email and password
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    debugPrint('[AuthService] Attempting registration for: $email');
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('[AuthService] Registration successful for: ${credential.user?.email}');

      if (credential.user == null) {
        throw AuthServiceException('Registration failed: No user returned');
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        debugPrint('[AuthService] Display name updated to: $displayName');
      }

      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthServiceException(
        _getErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      debugPrint('[AuthService] Registration error: $e');
      if (e is AuthServiceException) rethrow;
      throw AuthServiceException('Registration failed: $e');
    }
  }

  /// Login with Google
  Future<UserModel> loginWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthServiceException('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw AuthServiceException('Google login failed: No user returned');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(
        _getErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      if (e is AuthServiceException) rethrow;
      throw AuthServiceException('Google login failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthServiceException('Sign out failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(
        _getErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      throw AuthServiceException('Password reset failed: $e');
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

