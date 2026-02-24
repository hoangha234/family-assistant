part of 'auth_cubit.dart';

/// Auth status enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state
class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// Initial state
  const AuthState.initial() : this();

  /// Loading state
  const AuthState.loading()
      : this(status: AuthStatus.loading);

  /// Authenticated state
  const AuthState.authenticated(UserModel user)
      : this(status: AuthStatus.authenticated, user: user);

  /// Unauthenticated state
  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);

  /// Error state
  const AuthState.error(String message)
      : this(status: AuthStatus.error, errorMessage: message);

  /// Check states
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error;

  /// Copy with
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}

