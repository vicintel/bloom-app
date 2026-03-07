// Mock Authentication Service
// Ready to swap with Firebase when needed

class User {
  final String uid;
  final String email;
  final String? displayName;

  User({
    required this.uid,
    required this.email,
    this.displayName,
  });
}

class UserCredential {
  final User user;

  UserCredential({required this.user});
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentUser = User(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
    );
    
    return UserCredential(user: _currentUser!);
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentUser = User(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
    );
    
    return UserCredential(user: _currentUser!);
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  Future<void> resetPassword({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
