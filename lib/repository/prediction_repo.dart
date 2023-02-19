import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_scribble/models/prediction_model.dart';

class PredictionRepository {
  final _predictionsRef = FirebaseFirestore.instance.collection('results');

  Future<List<PredictionModel>> get() async {
    List<PredictionModel> resultsList = [];
    try {
      final predictions = await _predictionsRef.get();
      for (var element in predictions.docs) {
        resultsList.add(PredictionModel.fromMap(element.data()));
      }
      return resultsList;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Failed to fetch predicitons with error ${e.code}: ${e.message}');
      }
      return resultsList;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Stream<PredictionModel> prediction(String id) {
    return _predictionsRef.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      return PredictionModel.fromMap(data ?? {});
    });
  }
}
