import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

abstract class BackendService {
  Future<String?> createPrediction(String imageData, String prompt);
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
}
