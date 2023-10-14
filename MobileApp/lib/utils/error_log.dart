import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void sendErrorLog(String message, String page) {
  try {
    if (FirebaseAuth.instance.currentUser != null) {
      String time = DateTime.now().toString();
      String email = FirebaseAuth.instance.currentUser!.email!;
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('error_log').doc(email);
      docRef.get().then((doc) {
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          int fieldCount = data.length;
          if (fieldCount > 100) {
            docRef.delete().then((_) {
              createNewDocument(docRef, time, message, page);
            }).catchError((error) {});
          } else {
            docRef
                .update({
                  (fieldCount + 1).toString(): {
                    'page': page,
                    'message': message,
                    'timestamp': DateTime.now().toString(),
                  }
                })
                .then((_) {})
                .catchError((error) {});
          }
        } else {
          createNewDocument(docRef, time, message, page);
        }
      }).catchError((error) {});
    }
  } catch (e) {
    print(e);
  }
}

void createNewDocument(
    DocumentReference docRef, String time, String message, String page) {
  docRef
      .set({
        "1": {
          'page': page,
          'message': message,
          'timestamp': DateTime.now().toString(),
        }
      })
      .then((_) {})
      .catchError((error) {});
}
