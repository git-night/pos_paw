import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  
  // Cache for current user profile
  app_user.User? _cachedUserProfile;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user password
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile data from public.users table
  Future<app_user.User?> getUserProfile() async {
    if (currentUser == null) return null;
    
    // Return cached profile if available
    if (_cachedUserProfile != null && _cachedUserProfile!.id == currentUser!.id) {
      return _cachedUserProfile;
    }
    
    // Fetch from database
    _cachedUserProfile = await _supabaseService.getCurrentUser();
    return _cachedUserProfile;
  }
  
  // Clear cached profile
  void clearCachedProfile() {
    _cachedUserProfile = null;
  }
  
  // Get user email (synchronous from auth)
  String? get userEmail => currentUser?.email;
  
  // Get user full name (synchronous from cache or metadata)
  String? get userFullName {
    // Try from cached profile first
    if (_cachedUserProfile != null) {
      return _cachedUserProfile!.fullName ?? _cachedUserProfile!.displayName;
    }
    // Fallback to metadata
    return currentUser?.userMetadata?['full_name'];
  }
  
  // Get user role (synchronous from cache)
  String? get userRole => _cachedUserProfile?.role;
  
  // Load user profile on init
  Future<void> loadUserProfile() async {
    if (currentUser != null) {
      await getUserProfile();
    }
  }
}
