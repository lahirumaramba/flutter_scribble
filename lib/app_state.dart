import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class AppState {
  AppState() {
    StreamController<QuerySnapshot> _localStreamController =
        StreamController.broadcast();
  }

  void _listenForEntries() {
    FirebaseFirestore.instance
        .collection('Entries')
        .snapshots()
        .listen((event) {
      final entries = event.docs.map((doc) {
        final data = doc.data();
        /*return Entry(
          date: data['date'] as String,
          text: data['text'] as String,
          title: data['title'] as String,
        );*/
      }).toList();

      //_entriesStreamController.add(entries);
    });
  }
}
