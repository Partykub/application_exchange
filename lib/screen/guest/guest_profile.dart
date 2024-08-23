import 'package:cached_network_image/cached_network_image.dart';
import 'package:exchange/class/pull_image.dart';
import 'package:exchange/screen/guest/guest_history_profile.dart';
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

  int calculateStars(int exchangeSuccess, int numberOfPosts) {
    if (numberOfPosts == 0) return 0;
    double rate = (exchangeSuccess / numberOfPosts) * 100;
    if (rate >= 100) return 5;
    if (rate >= 80) return 4;
    if (rate >= 60) return 3;
    if (rate >= 40) return 2;
    if (rate >= 20) return 1;
    return 0;
  }

  List<Widget> buildStars(int stars) {
    List<Widget> starWidgets = [];
    for (int i = 0; i < stars; i++) {
      starWidgets.add(const Icon(Icons.star, color: Colors.yellow));
    }
    for (int i = stars; i < 5; i++) {
      starWidgets.add(const Icon(Icons.star_border, color: Colors.grey));
    }
    return starWidgets;
  }

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
                          final exchangeSuccess =
                              snapshot.data!['exchangeSuccess'] ?? 0;
                          final numberOfPosts =
                              snapshot.data!['NumberOfPosts'] ?? 0;
                          final stars =
                              calculateStars(exchangeSuccess, numberOfPosts);
                          return Column(
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height / 55,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                30,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1.5,
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
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                20,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                80,
                                          ),
                                          Text(
                                            snapshot.data!['Name'] as String,
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.002,
                                          ),
                                          Row(
                                            children: buildStars(stars),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.005,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Text('จำนวนโพสต์'),
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    20,
                                              ),
                                              const Text("แลกเปลี่ยนสำเร็จ")
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    13,
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
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    4,
                                              ),
                                              SizedBox(
                                                  child: snapshot.data![
                                                              'exchangeSuccess'] !=
                                                          null
                                                      ? Text(snapshot.data![
                                                              'exchangeSuccess']
                                                          .toString())
                                                      : const Text('0')),
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
                Container(
                  color: Colors.white,
                  height: 20,
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
                      : GuestHistoryProfile(userId: widget.informationUserUID),
                ),
              ],
            )));
  }
}
