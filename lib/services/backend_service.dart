import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

abstract class BackendService {
  Future<String?> createPrediction(String imageData, String prompt);
  Future<void> logEvent(String name, Map<String, Object?>? parameters);
}

class BackendServiceImpl extends BackendService {
  @override
  Future<String?> createPrediction(String imageData, String prompt) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('createPrediction')
          .call({'image': imageData, 'prompt': prompt});
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
  Future<void> logEvent(String name, Map<String, Object?>? parameters) async {
    await FirebaseAnalytics.instance
        .logEvent(name: name, parameters: parameters);
  }
}
