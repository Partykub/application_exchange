import 'dart:typed_data';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<void> uploadImageToFirebase(
    BuildContext context, String informationUserUID) async {
  final DateTime now = DateTime.now();
  final String timestamp = now.toIso8601String().replaceAll(
      RegExp(r'[:\-\. ]'), ''); // สร้าง timestamp จากวันที่และเวลาปัจจุบัน
  final String fileName =
      '$informationUserUID-$timestamp.jpg'; // ตั้งชื่อไฟล์โดยรวมกับ UID และ timestamp

  try {
    final Directory tempDir = await getTemporaryDirectory();
    final File tempFile = File('${tempDir.path}/temp.jpg');
    final ByteData data = await rootBundle.load('lib/images/UserProfile.jpg');
    final Uint8List bytes = data.buffer.asUint8List();
    await tempFile.writeAsBytes(bytes); // บันทึกไฟล์รูปภาพไว้ในโฟลเดอร์ temp

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('User Profile/$fileName');
    await ref.putFile(tempFile); // อัปโหลดไฟล์รูปภาพ

    final String url =
        await ref.getDownloadURL(); // รับ URL ของรูปภาพหลังจากอัปโหลด
    _saveImagePathToFirestore(
        url, informationUserUID); // บันทึก URL ลงใน Firestore

    print('Image URL: $url');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload successful'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    print('Error uploading image: $error');
  }
}

Future<void> _saveImagePathToFirestore(
    String imageUrl, String informationUserUID) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userRef =
        firestore.collection('informationUser').doc(informationUserUID);
    await userRef.update({'profileImageUrl': imageUrl});
    print("Image URL saved to Firestore successfully!");
  } catch (error) {
    print("Error saving image URL: $error");
  }
}
