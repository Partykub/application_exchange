import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> updateImageInFirebase(
    BuildContext context, String imageUrl, String informationUserUID) async {
  try {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('User Profile/$informationUserUID.jpg');

    // ดาวน์โหลดรูปภาพใหม่จาก URL และอัปโหลดไปยัง Firebase Storage
    HttpClient httpClient = HttpClient();
    final HttpClientRequest request =
        await httpClient.getUrl(Uri.parse(imageUrl));
    final HttpClientResponse response = await request.close();
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    await ref.putData(bytes);

    final String newImageUrl =
        await ref.getDownloadURL(); // รับ URL ของรูปภาพใหม่หลังจากอัปโหลด

    // อัปเดต URL ใน Firestore
    await _saveImagePathToFirestore(newImageUrl, informationUserUID);

    print('Image updated successfully!');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image updated successfully'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    print('Error updating image: $error');
  }
}

Future<void> _saveImagePathToFirestore(
    String imageUrl, String informationUserUID) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userRef =
        firestore.collection('informationUser').doc(informationUserUID);
    await userRef.update(
        {'profileImageUrl': imageUrl}); // อัปเดต URL ของรูปภาพใน Firestore
    print("Image URL saved to Firestore successfully!");
  } catch (error) {
    print("Error saving image URL: $error");
  }
}
