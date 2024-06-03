import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> checkPhoneNumberIsNew(String phoneNumber) async {
  try {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('informationUser')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .get();

    return querySnapshot.docs.isEmpty;
  } catch (e) {
    print('Error checking phone number: $e');
    return false;
  }
}
