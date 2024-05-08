import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  final String informationUserUID;

  const EditProfile({Key? key, required this.informationUserUID})
      : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController _nameController = TextEditingController();
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // เรียกใช้ฟังก์ชันเพื่อโหลดข้อมูลโปรไฟล์
  }

  // ฟังก์ชันเพื่อโหลดข้อมูลโปรไฟล์
  void _loadUserProfile() {
    // ใส่โค้ดที่นี่เพื่อโหลดข้อมูลโปรไฟล์ เช่น ชื่อผู้ใช้ และ URL รูปโปรไฟล์
    // ในกรณีนี้คุณอาจต้องดึงข้อมูลจาก Firestore หรือจากที่เก็บข้อมูลอื่น ๆ
    // ตัวอย่างเช่น:
    _nameController.text = 'ชื่อผู้ใช้';
    // _imageUrl = 'URL รูปโปรไฟล์'; // กำหนด URL รูปโปรไฟล์เริ่มต้น
  }

  // ฟังก์ชั่นสำหรับเลือกรูปภาพจากแกลเลอรี
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path).readAsBytesSync();
      });
    }
  }

  // ฟังก์ชั่นสำหรับอัปเดตรูปโปรไฟล์
  Future<void> _updateProfileImage() async {
    try {
      if (_image != null) {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref = storage
            .ref()
            .child('User Profile/${widget.informationUserUID}.jpg');

        // อัปโหลดรูปภาพ
        await ref.putData(_image!);

        // รับ URL ของรูปภาพหลังจากอัปโหลด
        final String imageUrl = await ref.getDownloadURL();

        // อัปเดต URL ใน Firestore
        await _saveImagePathToFirestore(imageUrl, widget.informationUserUID);

        print('Image updated successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image updated successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        print('No image selected.');
      }
    } catch (error) {
      print('Error updating image: $error');
    }
  }

  // ฟังก์ชั่นสำหรับอัปเดตชื่อผู้ใช้
  Future<void> _updateUserName() async {
    try {
      String newName = _nameController.text;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userRef = firestore
          .collection('informationUser')
          .doc(widget.informationUserUID);
      await userRef.update({'Name': newName});
      print("Username updated successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username updated successfully'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      print("Error updating username: $error");
    }
  }

  // ฟังก์ชั่นสำหรับอัปเดต URL ใน Firestore
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขโปรไฟล์"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'แก้ไขชื่อผู้ใช้',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'ชื่อผู้ใช้',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'แก้ไขรูปโปรไฟล์',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _image != null ? MemoryImage(_image!) : null,
                child: _image == null
                    ? Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _updateUserName();
                    _updateProfileImage();
                  },
                  child: Text('บันทึก'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
