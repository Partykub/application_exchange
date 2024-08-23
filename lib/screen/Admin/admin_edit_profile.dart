import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminEditProfile extends StatefulWidget {
  final String userId;

  const AdminEditProfile({Key? key, required this.userId}) : super(key: key);

  @override
  State<AdminEditProfile> createState() => _AdminEditProfileState();
}

class _AdminEditProfileState extends State<AdminEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameEditingController = TextEditingController();

  bool isLoading = false;
  Uint8List? _image;

  @override
  void dispose() {
    _nameEditingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path).readAsBytesSync();
      });
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      if (_image != null) {
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref =
            storage.ref().child('User Profile/${widget.userId}.jpg');

        await ref.putData(_image!);

        final String imageUrl = await ref.getDownloadURL();

        await _saveImagePathToFirestore(imageUrl, widget.userId);

        // ignore: avoid_print
        print('แก้ไขรูปโปรไฟล์สำเร็จ!');
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขรูปโปรไฟล์สำเร็จ!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        }
      } else {
        // ignore: avoid_print
        print('No image selected.');
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error updating image: $error');
    }
  }

  Future<void> _updateUserName() async {
    try {
      String newName = _nameEditingController.text;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userRef =
          firestore.collection('informationUser').doc(widget.userId);
      await userRef.update({'Name': newName});
      // ignore: avoid_print
      print("แก้ไขชื่อผู้ใช้สำเร็จ!");
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แก้ไขชื่อผู้ใช้สำเร็จ!'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      }
    } catch (error) {
      // ignore: avoid_print
      print("Error updating username: $error");
    }
  }

  Future<void> _saveImagePathToFirestore(
      String imageUrl, String informationUserUID) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userRef =
          firestore.collection('informationUser').doc(informationUserUID);
      await userRef.update({'profileImageUrl': imageUrl});
      // ignore: avoid_print
      print("Image URL saved to Firestore successfully!");
    } catch (error) {
      // ignore: avoid_print
      print("Error saving image URL: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("แก้ไขโปรไฟล์"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey[100],
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: Center(
                  child: InkWell(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _image != null ? MemoryImage(_image!) : null,
                      child: _image == null
                          ? Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          const Text(
                            'แก้ไขชื่อผู้ใช้',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextFormField(
                              controller: _nameEditingController,
                              validator: (inputname) {
                                if (inputname!.isEmpty) {
                                  return "กรุณากรอกชื่อผู้ใช้";
                                } else if (inputname.length < 6) {
                                  return 'ต้องมีตัวอักษรอย่างน้อย 6 ตัวอักษร';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelText: 'ชื่อผู้ใช้',
                                hintText: 'ชื่อผู้ใช้',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.black54),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        fixedSize:
                            MaterialStateProperty.all(const Size(180, 30)),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (_nameEditingController.text.isNotEmpty &&
                                  _formKey.currentState!.validate()) {
                                try {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  await _updateUserName();
                                  await _updateProfileImage();
                                } catch (error) {
                                  print("Error: $error");
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              } else if (_nameEditingController.text.isEmpty) {
                                try {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  await _updateProfileImage();
                                } catch (error) {
                                  print("Error: $error");
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                      child: isLoading
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width / 20,
                              height: MediaQuery.of(context).size.height / 40,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('บันทึก',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
