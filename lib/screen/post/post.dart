import 'dart:io';
import 'dart:typed_data';

import 'package:exchange/class/upload_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class Post extends StatefulWidget {
  const Post({Key? key}) : super(key: key);

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  bool isLoading = false;
  final auth = FirebaseAuth.instance;
  final _itemNameController = TextEditingController();
  final _itemDetailController = TextEditingController();
  final formKeyItemName = GlobalKey<FormState>();
  final formKeyItemDetail = GlobalKey<FormState>();
  List<Uint8List?> images = List<Uint8List?>.filled(4, null);
  String? _selectedOption;
  String? category;

  Future<Uint8List?> _pickImageInPost() async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('การอนุญาตถูกปฏิเสธในการเข้าถึงภาพถ่าย')),
        );
      }
      {
        null;
      }
    }
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      return File(pickedImage.path).readAsBytesSync();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("เพิ่มสิ่งของ"),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //input image1
                    Container(
                      alignment: Alignment.center,
                      height:
                          ((MediaQuery.of(context).size.height / 2) / 2) - 50,
                      width: ((MediaQuery.of(context).size.width / 2) - 30),
                      child: ElevatedButton(
                        onPressed: () async {
                          final imageBytes = await _pickImageInPost();
                          if (imageBytes != null) {
                            setState(() {
                              images[0] = imageBytes;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          minimumSize:
                              const Size(double.infinity, double.infinity),
                          padding: EdgeInsets.zero,
                        ),
                        child: images[0] != null
                            ? Image.memory(
                                images[0]!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                              )
                            : Icon(
                                Icons.add,
                                size: 11 /
                                    100 *
                                    MediaQuery.of(context).size.width,
                                color: Colors.black54,
                              ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 20,
                    ),
                    //input image2
                    Container(
                      alignment: Alignment.center,
                      height:
                          ((MediaQuery.of(context).size.height / 2) / 2) - 50,
                      width: ((MediaQuery.of(context).size.width / 2) - 30),
                      child: ElevatedButton(
                        onPressed: () async {
                          final imageBytes = await _pickImageInPost();
                          if (imageBytes != null) {
                            setState(() {
                              images[1] = imageBytes;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          minimumSize:
                              const Size(double.infinity, double.infinity),
                          padding: EdgeInsets.zero,
                        ),
                        child: images[1] != null
                            ? Image.memory(
                                images[1]!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                              )
                            : Icon(
                                Icons.add,
                                size: 11 /
                                    100 *
                                    MediaQuery.of(context).size.width,
                                color: Colors.black54,
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //input image3
                    Container(
                      alignment: Alignment.center,
                      height:
                          ((MediaQuery.of(context).size.height / 2) / 2) - 50,
                      width: ((MediaQuery.of(context).size.width / 2) - 30),
                      child: ElevatedButton(
                        onPressed: () async {
                          final imageBytes = await _pickImageInPost();
                          if (imageBytes != null) {
                            setState(() {
                              images[2] = imageBytes;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          minimumSize:
                              const Size(double.infinity, double.infinity),
                          padding: EdgeInsets.zero,
                        ),
                        child: images[2] != null
                            ? Image.memory(
                                images[2]!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                              )
                            : Icon(
                                Icons.add,
                                size: 11 /
                                    100 *
                                    MediaQuery.of(context).size.width,
                                color: Colors.black54,
                              ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 20,
                    ),
                    //input image4
                    Container(
                      alignment: Alignment.center,
                      height:
                          ((MediaQuery.of(context).size.height / 2) / 2) - 50,
                      width: ((MediaQuery.of(context).size.width / 2) - 30),
                      child: ElevatedButton(
                        onPressed: () async {
                          final imageBytes = await _pickImageInPost();
                          if (imageBytes != null) {
                            setState(() {
                              images[3] = imageBytes;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          minimumSize:
                              const Size(double.infinity, double.infinity),
                          padding: EdgeInsets.zero,
                        ),
                        child: images[3] != null
                            ? Image.memory(
                                images[3]!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                              )
                            : Icon(
                                Icons.add,
                                size: 11 /
                                    100 *
                                    MediaQuery.of(context).size.width,
                                color: Colors.black54,
                              ),
                      ),
                    ),
                  ],
                ),
                //input
                //ชื่อสิ่งของ และ ประเภทของโพสต์
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      //แถวแรก
                      Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Text(
                              "ชื่อสิ่งของ",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height / 60,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 25,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 2.8,
                            child: Text(
                              "ประเภทโพสต์",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height / 60,
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 90,
                      ),
                      //แถวสอง
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: MediaQuery.of(context).size.width / 2,
                              height: MediaQuery.of(context).size.height / 13,
                              child: Form(
                                key: formKeyItemName,
                                child: TextFormField(
                                  controller: _itemNameController,
                                  validator: (inputItemName) {
                                    if (inputItemName!.isEmpty) {
                                      return "กรุณากรอกชื่อสิ่งของ";
                                    } else if (!RegExp(r'^[ก-๙\s]{3,30}$')
                                        .hasMatch(inputItemName)) {
                                      return "ต้องเป็นคำภาษาไทย 3-10 ตัวอักษร";
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Colors
                                              .black54), // กำหนดสีของกรอบเมื่อได้รับโฟกัส
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    hintText: 'ชื่อสิ่งของ',
                                    hintStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height /
                                              60,
                                      color: Colors.black38,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 1,
                                      horizontal: 3,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.height / 60,
                                  ),
                                ),
                              )),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 25,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 2.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black54),
                            ),
                            child: Center(
                              child: PopupMenuButton<String>(
                                color: Colors.grey[100],
                                onSelected: (String result) {
                                  setState(() {
                                    _selectedOption = result;
                                  });
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'แลกเปลี่ยนสิ่งของเท่านั้น',
                                    child: Text(
                                      'แลกเปลี่ยนสิ่งของเท่านั้น',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'ขายเท่านั้น',
                                    child: Text(
                                      'ขายเท่านั้น',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'แลกเปลี่ยนและขาย',
                                    child: Text(
                                      'แลกเปลี่ยนและขาย',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size:
                                            MediaQuery.of(context).size.width /
                                                13,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: _selectedOption != null
                                            ? Text(
                                                _selectedOption.toString(),
                                              )
                                            : Text(
                                                "ประเภทโพสต์",
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height /
                                                          60,
                                                  color: Colors.black38,
                                                ),
                                              ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 90,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Text(
                              "รายละเอียดสิ่งของ",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height / 60,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 25,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 2.8,
                            child: Text(
                              "หมวดหมู่สิ่งของ",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height / 60,
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 90,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: MediaQuery.of(context).size.width / 2,
                              height: MediaQuery.of(context).size.height / 11,
                              child: Form(
                                  key: formKeyItemDetail,
                                  child: TextFormField(
                                    controller: _itemDetailController,
                                    minLines: 2,
                                    maxLines: 2,
                                    maxLength: 40,
                                    validator: (inputItemDetail) {
                                      if (inputItemDetail!.isEmpty) {
                                        return "กรุณากรอกรายละเอียดสิ่งของ";
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors
                                                .black54), // กำหนดสีของกรอบเมื่อได้รับโฟกัส
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      hintText: 'รายละเอียดสิ่งของ',
                                      hintStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                        color: Colors.black38,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 3,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height /
                                              60,
                                    ),
                                  ))),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 25,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 2.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black54),
                            ),
                            child: Center(
                              child: PopupMenuButton<String>(
                                color: Colors.grey[100],
                                onSelected: (String result) {
                                  setState(() {
                                    category = result;
                                  });
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'สุขภาพและความงาม',
                                    child: Text(
                                      'สุขภาพและความงาม',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'เครื่องแต่งกาย',
                                    child: Text(
                                      'เครื่องแต่งกาย',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'กีฬา',
                                    child: Text(
                                      'กีฬา',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'อิเล็กทรอนิกส์',
                                    child: Text(
                                      'อิเล็กทรอนิกส์',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'เครื่องใช้ไฟฟ้า',
                                    child: Text(
                                      'เครื่องใช้ไฟฟ้า',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'อุปกรณ์สัตว์เลี้ยง',
                                    child: Text(
                                      'อุปกรณ์สัตว์เลี้ยง',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'อุปกรณ์สำนักงาน',
                                    child: Text(
                                      'อุปกรณ์สำนักงาน',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'อุปกรณ์ช่าง',
                                    child: Text(
                                      'อุปกรณ์ช่าง',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'บ้านและห้องครัว',
                                    child: Text(
                                      'บ้านและห้องครัว',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'ของเล่นและเกมส์',
                                    child: Text(
                                      'ของเล่นและเกมส์',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                60,
                                      ),
                                    ),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size:
                                            MediaQuery.of(context).size.width /
                                                13,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: category != null
                                            ? Text(
                                                category.toString(),
                                              )
                                            : Text(
                                                "หมวดหมู่สิ่งของ",
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height /
                                                          60,
                                                  color: Colors.black38,
                                                ),
                                              ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        fixedSize: MaterialStateProperty.all(Size(
                          MediaQuery.of(context).size.width /
                              3, // กำหนดความกว้าง
                          MediaQuery.of(context).size.height /
                              22, // กำหนดความสูง
                        )),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (images[0] != null &&
                                  images[1] != null &&
                                  images[2] != null &&
                                  images[3] != null) {
                                if (formKeyItemName.currentState!.validate() ==
                                    true) {
                                  print("ผ่าน");
                                  if (formKeyItemDetail.currentState!
                                          .validate() ==
                                      true) {
                                    print("ผ่าน2");
                                    if (_selectedOption != null) {
                                      print("ผ่าน3");
                                      if (category != null) {
                                        print("ผ่าน4");
                                        setState(() {
                                          isLoading = true;
                                        });
                                        try {
                                          await uploadImagePost(
                                            images,
                                            auth.currentUser!.uid,
                                            _itemNameController.text,
                                            _itemDetailController.text,
                                            _selectedOption!,
                                            category!,
                                            context,
                                          );
                                        } catch (error) {
                                          print(
                                              'Error uploading images: $error');
                                        } finally {
                                          setState(() {
                                            _itemNameController.clear();
                                            _itemDetailController.clear();
                                            _selectedOption = null;
                                            category = null;
                                            images[0] = null;
                                            images[1] = null;
                                            images[2] = null;
                                            images[3] = null;
                                            isLoading =
                                                false; // เสร็จสิ้นการอัปโหลด
                                          });
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'กรุณาเลือกหมวดหมู่สิ่งของ'),
                                            duration: Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('กรุณาเลือกประเภทโพสต์'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('กรุณาเลือกภาพสิ่งของ 4 รูปภาพ'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
                          : Text(
                              "ยืนยัน",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height / 60,
                                color: Colors.white,
                              ),
                            ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
