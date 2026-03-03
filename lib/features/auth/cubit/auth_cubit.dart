import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

part 'auth_state.dart';

/// Cubit for handling authentication
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthState.initial()) {
    debugPrint('[AuthCubit] Created');
  }

  /// Initialize and listen to auth state changes
  void initialize() {
    debugPrint('[AuthCubit] Initializing...');
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen((user) {
      debugPrint('[AuthCubit] Auth state changed: ${user?.email ?? "null"}');
      if (user != null) {
        emit(AuthState.authenticated(UserModel.fromFirebaseUser(user)));
      } else {
        emit(const AuthState.unauthenticated());
      }
    });
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    debugPrint('[AuthCubit] Login attempt for: $email');

    if (email.isEmpty || password.isEmpty) {
      emit(AuthState.error('Please enter email and password'));
      return;
    }

    emit(const AuthState.loading());

    try {
      final user = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthCubit] Login successful: ${user.email}');
      emit(AuthState.authenticated(user));
    } on AuthServiceException catch (e) {
      debugPrint('[AuthCubit] AuthServiceException: ${e.message}');
      emit(AuthState.error(e.message));
    } catch (e) {
      debugPrint('[AuthCubit] Unknown error: $e');
      emit(AuthState.error('Login failed. Please try again.'));
    }
  }

  /// Login with Google
  Future<void> loginWithGoogle() async {
    debugPrint('[AuthCubit] Google login attempt');
    emit(const AuthState.loading());

    try {
      final user = await _authService.loginWithGoogle();
      debugPrint('[AuthCubit] Google login successful: ${user.email}');
      emit(AuthState.authenticated(user));
    } on AuthServiceException catch (e) {
      debugPrint('[AuthCubit] AuthServiceException: ${e.message}');
      emit(AuthState.error(e.message));
    } catch (e) {
      debugPrint('[AuthCubit] Unknown error: $e');
      emit(AuthState.error('Google login failed. Please try again.'));
    }
  }

  /// Register with email and password
  Future<void> register(String email, String password, {String? displayName}) async {
    debugPrint('[AuthCubit] Register attempt for: $email');

    if (email.isEmpty || password.isEmpty) {
      emit(AuthState.error('Please enter email and password'));
      return;
    }

    emit(const AuthState.loading());

    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      debugPrint('[AuthCubit] Registration successful: ${user.email}');
      emit(AuthState.authenticated(user));
    } on AuthServiceException catch (e) {
      debugPrint('[AuthCubit] AuthServiceException: ${e.message}');
      emit(AuthState.error(e.message));
    } catch (e) {
      debugPrint('[AuthCubit] Unknown error: $e');
      emit(AuthState.error('Registration failed. Please try again.'));
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    if (email.isEmpty) {
      emit(AuthState.error('Please enter your email'));
      return;
    }

    emit(const AuthState.loading());

    try {
      await _authService.sendPasswordResetEmail(email);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      ));
    } on AuthServiceException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('Failed to send reset email. Please try again.'));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Sign out failed. Please try again.'));
    }
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

