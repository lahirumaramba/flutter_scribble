import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_scribble/models/prediction_model.dart';

abstract class PredictionRepository {
  Stream<PredictionModel> onPredictionUpdated(String id);
  Future<List<PredictionModel>> getShowcase(String uid);
  Future<PredictionModel?> getPrediction(String id);
}

class PredictionRepositoryImpl extends PredictionRepository {
  final _predictionsRef = FirebaseFirestore.instance.collection('results');
  final _showcaseRef = FirebaseFirestore.instance.collection('showcase');

  @override
  Future<List<PredictionModel>> getShowcase(String uid) async {
    List<PredictionModel> resultsList = [];
    try {
      final predictions = await _getUserPredictions(uid);
      final showcase = await _getShowcase();
      for (var element in predictions.docs) {
        var data = element.data();
        data['id'] = element.id;
        resultsList.add(PredictionModel.fromMap(data));
      }
      for (var element in showcase.docs) {
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

  Future<QuerySnapshot<Map<String, dynamic>>> _getShowcase() async {
    return await _showcaseRef.limit(3).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUserPredictions(
      String uid) async {
    return await _predictionsRef.where('user', isEqualTo: uid).get();
  }

  @override
  Stream<PredictionModel> onPredictionUpdated(String id) {
    return _predictionsRef.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data() ?? {};
      data['id'] = id;
      return PredictionModel.fromMap(data);
    });
  }

  @override
  Future<PredictionModel?> getPrediction(String id) async {
    PredictionModel? predictionModel;
    final docSnapshot = await _predictionsRef.doc(id).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() ?? {};
      data['id'] = id;
      predictionModel = PredictionModel.fromMap(data);
    }
    return predictionModel;
  }
}
