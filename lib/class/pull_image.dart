import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>?> pullImage(String userId) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('informationUser').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    } else {
      print("PullImage: No such user!");
      return null;
    }
  } catch (e) {
    print("PullImage: Error fetching user data: $e");
    return null;
  }
}
