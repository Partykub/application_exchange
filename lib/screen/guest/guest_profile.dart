import 'package:cached_network_image/cached_network_image.dart';
import 'package:exchange/class/pull_image.dart';
import 'package:exchange/screen/guest/guest_post_profile.dart';
import 'package:flutter/material.dart';

class GuestProfile extends StatefulWidget {
  final String informationUserUID;
  const GuestProfile({super.key, required this.informationUserUID});

  @override
  State<GuestProfile> createState() => _GuestProfileState();
}

class _GuestProfileState extends State<GuestProfile> {
  List<bool> historyWithPost = [true, false];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        color: Colors.grey[200],
        home: Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text("เยี่ยมชมโปรไฟล์"),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.0),
                  child: Container(
                    color: Colors.grey[300],
                    height: 0.4,
                  ),
                ),
                leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios))),
            body: Column(
              children: [
                Expanded(
                  flex: 0,
                  child: Container(
                    color: Colors.white,
                    child: FutureBuilder(
                      future: pullImage(widget.informationUserUID),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }
                        if (snapshot.hasData) {
                          final imageUrl =
                              snapshot.data!['profileImageUrl'] as String;
                          return Column(
                            children: [
                              Column(
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 25,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black, // สีของเส้นขอบ
                                            width: 1.5, // ความกว้างของเส้นขอบ
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 70,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  imageUrl),
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            snapshot.data!['Name'] as String,
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                          const Text("ดาว"),
                                          const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('จำนวนโพสต์'),
                                              SizedBox(
                                                width: 20,
                                              ),
                                              Text("แลกเปลี่ยนสำเร็จ")
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 35,
                                              ),
                                              SizedBox(
                                                child: snapshot.data![
                                                            'NumberOfPosts'] !=
                                                        null
                                                    ? Text(snapshot
                                                        .data!['NumberOfPosts']
                                                        .toString())
                                                    : const Text('0'),
                                              ),
                                              const SizedBox(
                                                width: 95,
                                              ),
                                              const Text("0")
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return const Text("No Profile found");
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: ToggleButtons(
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
                          borderRadius: BorderRadius.circular(0),
                          selectedBorderColor: Colors.black,
                          borderColor: Colors.grey[400],
                          borderWidth: 1.0,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: ((MediaQuery.of(context).size.width / 2) -
                                  1.5),
                              child: const Text(
                                "โพสต์",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: ((MediaQuery.of(context).size.width / 2) -
                                  1.5),
                              child: const Text(
                                "ประวัติการแลกเปลี่ยน",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: historyWithPost[0]
                      ? GuestPostProfile(userId: widget.informationUserUID)
                      : VisitHistoryPost(
                          informationUserUID: widget.informationUserUID),
                ),
              ],
            )));
  }
}

class VisitHistoryPost extends StatelessWidget {
  final String informationUserUID;

  const VisitHistoryPost({required this.informationUserUID});

  @override
  Widget build(BuildContext context) {
    // Implement the widget that shows the user's exchange history
    return Container(
      color: Colors.green[50],
      child: Center(
        child: Text("ประวัติการแลกเปลี่ยนของผู้ใช้: $informationUserUID"),
      ),
    );
  }
}
