import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save travel usage data for the current user
  Future<void> saveTravelUsage(Map<String, dynamic> travelData) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = _db.collection('users').doc(user.uid);
      await userDoc.collection('travelUsage').add(travelData);
    }
  }
}
