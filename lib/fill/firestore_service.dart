import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_mobile/fill/sports_field.dart';

class FirestoreService {
  final CollectionReference fieldsCollection = FirebaseFirestore.instance.collection('sports_fields');

  Future<void> addSportsField(SportsField field) async {
    await fieldsCollection.add(field.toFirestore());
  }

  Future<void> addMultipleSportsFields(List<SportsField> fields) async {
    for (final field in fields) {
      await addSportsField(field);
    }
  }
}
