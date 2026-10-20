import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hampa/firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;

  /// Initializes Firebase safely with graceful fallback for web and local runs
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _isInitialized = true;
        debugPrint('[FirebaseService] Native Firebase initialized.');
      } else {
        // On Web, try initialize or fallback gracefully so UI loads instantly without white screen
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.web,
          );
          _isInitialized = true;
          debugPrint('[FirebaseService] Web Firebase initialized.');
        } catch (webError) {
          debugPrint('[FirebaseService] Web Firebase fallback to offline mode: $webError');
        }
      }
    } catch (e) {
      debugPrint('[FirebaseService] Offline-first fallback mode active: $e');
    }
  }

  static FirebaseFirestore? get firestore {
    if (!_isInitialized) return null;
    return FirebaseFirestore.instance;
  }
}
