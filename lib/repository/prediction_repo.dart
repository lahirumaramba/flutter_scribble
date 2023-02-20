import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_scribble/models/prediction_model.dart';

abstract class PredictionRepository {
  Stream<PredictionModel> onPredictionUpdated(String id);
  Future<List<PredictionModel>> get showcase;
}

class PredictionRepositoryImpl extends PredictionRepository {
  final _predictionsRef = FirebaseFirestore.instance.collection('results');
  final _showcaseRef = FirebaseFirestore.instance.collection('showcase');

  @override
  Future<List<PredictionModel>> get showcase async {
    List<PredictionModel> resultsList = [];
    try {
      final predictions = await _showcaseRef.limit(3).get();
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

  @override
  Stream<PredictionModel> onPredictionUpdated(String id) {
    return _predictionsRef.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data() ?? {};
      data['id'] = id;
      return PredictionModel.fromMap(data);
    });
  }
}
