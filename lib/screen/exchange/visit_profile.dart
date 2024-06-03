import 'package:cached_network_image/cached_network_image.dart';
import 'package:exchange/class/pull_image.dart';
import 'package:exchange/screen/exchange/visit_history_profile.dart';
import 'package:exchange/screen/exchange/visit_post_profile.dart';
import 'package:flutter/material.dart';

class VisitProfile extends StatefulWidget {
  final informationUserUID;
  const VisitProfile({super.key, required this.informationUserUID});

  @override
  State<VisitProfile> createState() => _VisitProfileState();
}

class _VisitProfileState extends State<VisitProfile> {
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
                                          Row(
                                            children: buildStars(stars),
                                          ),
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
                Container(
                  child: historyWithPost[0]
                      ? VisitPostProfile(userId: widget.informationUserUID)
                      : VisitHistoryPost(),
                )
              ],
            )));
  }
}
