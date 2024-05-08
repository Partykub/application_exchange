import 'package:exchange/class/pull_image.dart';
import 'package:exchange/screen/profile/edit_profile.dart';
import 'package:exchange/screen/profile/history_post.dart';
import 'package:exchange/screen/profile/post.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  final informationUserUID;
  const Profile({super.key, required this.informationUserUID});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<bool> historyWithPost = [true, false];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("โปรไฟล์"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            child: FutureBuilder(
              future: pullImage(widget.informationUserUID),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.hasData) {
                  final imageUrl = snapshot.data!['profileImageUrl'] as String;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 30,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black, // สีของเส้นขอบ
                                width: 3, // ความกว้างของเส้นขอบ
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(imageUrl),
                              onBackgroundImageError: (exception, stackTrace) {
                                // การจัดการเมื่อโหลดภาพไม่สำเร็จ
                                CircularProgressIndicator();
                              },
                              backgroundColor: Colors
                                  .transparent, // สีพื้นหลังเมื่อรูปภาพโหลดไม่ได้// แสดงตัวโหลดเมื่อกำลังโหลดภาพ
                            ),
                          ),
                          const SizedBox(
                            width: 40,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                snapshot.data!['Name'] as String,
                                style: TextStyle(fontSize: 20),
                              ),
                              const Text("ดาว"),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('จำนวนโพสต์'),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("แลกเปลี่ยนสำเร็จ")
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 35,
                                  ),
                                  Text('0'),
                                  SizedBox(
                                    width: 95,
                                  ),
                                  Text("0")
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  const SizedBox(width: 30),
                                  ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.black54),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        fixedSize: MaterialStateProperty.all(
                                            const Size(130, 25)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditProfile(
                                                  informationUserUID: widget
                                                      .informationUserUID),
                                            ));
                                      },
                                      child: const Text(
                                        'แก้ไขโปรไฟล์',
                                        style: TextStyle(color: Colors.white),
                                      )),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ToggleButtons(
                        isSelected: historyWithPost,
                        onPressed: (int index) {
                          setState(() {
                            historyWithPost = [false, false];
                            historyWithPost[index] = true;
                          });
                        },
                        selectedColor: Colors.black,
                        color: Colors.grey[400],
                        fillColor: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                        selectedBorderColor: Colors.black,
                        borderColor: Colors.grey[400],
                        borderWidth: 1.0,
                        children: [
                          Container(
                            height: 40,
                            width: 160,
                            alignment: Alignment.center,
                            child: const Text(
                              "ประวัติการแลกเปลี่ยน",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 160,
                            alignment: Alignment.center,
                            child: const Text(
                              "โพสต์",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (historyWithPost[0] == true) ...[HistoryPost()],
                      if (historyWithPost[1] == true) ...[Post()],
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return const Text("No Profile found");
              },
            ),
          ),
        ),
      ),
    );
  }
}
