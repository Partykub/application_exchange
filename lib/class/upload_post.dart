import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

Future<void> uploadImagePost(
    List<Uint8List?> images,
    String informationUserUID,
    String itemNameController,
    String itemDetailController,
    String selectedOption,
    String category,
    BuildContext context) async {
  try {
    FirebaseStorage storage = FirebaseStorage.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      Uint8List? image = images[i];
      if (image != null) {
        String imageName = const Uuid().v4();
        Reference ref =
            storage.ref().child('User/$informationUserUID/$imageName.jpg');

        await ref.putData(image);

        final String imageUrl = await ref.getDownloadURL();

        // เพิ่ม URL ในรายการ
        imageUrls.add(imageUrl);

        print('Image $i uploaded successfully!');
      } else {
        print('No image selected.');
      }
    }

    // เก็บ URLs ใน Firestore ในฟิลด์ images ในรูปแบบของ List
    await firestore.collection('posts').add({
      'UserId': informationUserUID,
      'Images': imageUrls,
      'PostCategory': selectedOption,
      'Category': category,
      'Name': itemNameController,
      'Detail': itemDetailController,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'available', // เพิ่มฟิลด์นี้
    });

    DocumentReference userDocRef =
        firestore.collection('informationUser').doc(informationUserUID);
    await firestore.runTransaction((transaction) async {
      DocumentSnapshot userDocSnapshot = await transaction.get(userDocRef);

      if (!userDocSnapshot.exists ||
          userDocSnapshot.data() is! Map<String, dynamic> ||
          !(userDocSnapshot.data() as Map<String, dynamic>)
              .containsKey('NumberOfPosts')) {
        // ใช้ `merge` เพื่อไม่ให้ field อื่นๆ หายไป
        transaction.set(
            userDocRef, {'NumberOfPosts': 1}, SetOptions(merge: true));
      } else {
        int currentNumberOfPosts = (userDocSnapshot.data()
            as Map<String, dynamic>)['NumberOfPosts'] as int;
        transaction
            .update(userDocRef, {'NumberOfPosts': currentNumberOfPosts + 1});
      }
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Images uploaded successfully'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(initialTabIndex: 4),
      ),
    );

    // ignore: use_build_context_synchronously
  } catch (error) {
    print('Error uploading images: $error');
  }
}
