import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract class BackendService {
  Future<String?> createPrediction(String imageData, String prompt);
  Future<UserCredential?> signInAnonUser();
  Future<void> logEvent(String name, Map<String, Object?>? parameters);
}

class BackendServiceImpl extends BackendService {
  UserCredential? _userCredential;

  @override
  Future<String?> createPrediction(String imageData, String prompt) async {
    var userCredential = await signInAnonUser();
    final userId = userCredential?.user?.uid ?? '';
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('createPrediction')
          .call({'image': imageData, 'prompt': prompt, 'userId': userId});
      if (kDebugMode) {
        print(result.data);
      }
      return result.data['data'] ?? '';
    } on FirebaseFunctionsException catch (error) {
      if (kDebugMode) {
        print(error);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserCredential?> signInAnonUser() async {
    try {
      _userCredential ??= await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'operation-not-allowed':
          if (kDebugMode) {
            print('Anonymous auth hasn\'t been enabled for this project.');
          }
          break;
        default:
          if (kDebugMode) {
            print('Unknown error. $e');
          }
      }
    }
    return _userCredential;
  }

  @override
  Future<void> logEvent(String name, Map<String, Object?>? parameters) async {
    await FirebaseAnalytics.instance
        .logEvent(name: name, parameters: parameters);
  }
}
