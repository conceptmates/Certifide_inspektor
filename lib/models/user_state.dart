class UserState {
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final String? error;
  final String? token;

  const UserState({
    this.userData,
    this.isLoading = false,
    this.error,
    this.token,
  });

  bool get isAuthenticated => userData != null && token != null;

  bool isAdmin() {
    final roles = userData?['roles'] as List?;
    return roles?.any((role) => role['name'] == 'admin') ?? false;
  }

  bool hasRole(String roleName) {
    final roles = userData?['roles'] as List?;
    return roles?.any((role) => role['name'] == roleName) ?? false;
  }

  UserState copyWith({
    Object? userData = _sentinel,
    bool? isLoading,
    Object? error = _sentinel,
    Object? token = _sentinel,
  }) {
    return UserState(
      userData: userData == _sentinel
          ? this.userData
          : userData as Map<String, dynamic>?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      token: token == _sentinel ? this.token : token as String?,
    );
  }
}

const _sentinel = Object();
