import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

  Future adminCheck() async {
  try {
    String admin = 'false';
    var user = FirebaseAuth.instance.currentUser!;
    String email = user.email!;
    await FirebaseFirestore.instance
        .collection('user')
        .doc(email)
        .get()
        .then((value) => {
          admin = value.data()!['admin']
          });
    if (admin == 'true') {
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

  // Future<void> changeNameDB() async {
  //     await FirebaseFirestore.instance
  //         .collection('old')
  //         .get()
  //         .then((QuerySnapshot snapShot) async {
  //       snapShot.docs.forEach((element) async {
  //         await FirebaseFirestore.instance
  //             .collection('new')
  //             .doc(element.id)
  //             .set(element.data()as Map<String, dynamic>);
  //       });
  //     });
  //   }