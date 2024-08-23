import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/class/pull_image.dart';
import 'package:exchange/screen/exchange/visit_history_profile.dart';
import 'package:exchange/screen/exchange/visit_post_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VisitProfile extends StatefulWidget {
  final informationUserUID;
  const VisitProfile({super.key, required this.informationUserUID});

  @override
  State<VisitProfile> createState() => _VisitProfileState();
}

class _VisitProfileState extends State<VisitProfile> {
  List<bool> historyWithPost = [true, false];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final auth = FirebaseAuth.instance;

  String? selectedReason;

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

  void reportDialog(BuildContext context, userID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.grey[50],
        title: const Text(
          'รายงานโพสต์',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Text(
                'เหตุใดคุณจึงรายงานโพสต์นี้',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              _buildReportOption(
                  'โพสต์สิ่งของที่ผิดกฎหมายหรือสิ่งของต้องห้าม', userID),
              _buildReportOption(
                  'โพสต์สิ่งของที่มีเนื้อหาลามกอนาจารหรือไม่เหมาะสม', userID),
              _buildReportOption(
                  'สิ่งของไม่ตรงตามคำบรรยายหรือรูปภาพที่โพสต์', userID),
              _buildReportOption(
                  'โพสต์สิ่งของที่มีความเสี่ยงต่อความปลอดภัยหรือสุขภาพ',
                  userID),
              _buildReportOption(
                  'การโพสต์เนื้อหาที่เป็นการหลอกลวงหรือฉ้อโกง', userID),
              _buildReportOption(
                  'การใช้ถ้อยคำที่ไม่เหมาะสมหรือการก่อกวนในโพสต์', userID),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(String text, userId) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        text,
        style: const TextStyle(color: Colors.black87),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black,
      ),
      onTap: () {
        _handleReasonTap(text, userId);
      },
    );
  }

  void _handleReasonTap(String reason, userId) {
    setState(() {
      selectedReason = reason;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.grey[50],
        title: const Text(
          'รายงานโพสต์',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'คุณกำลังจะส่งรายงาน',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'เราจะลบเฉพาะเนื้อหาที่ขัดต่อมาตรฐานชุมชนของเราเท่านั้น คุณสามารถตรวจสอบหรือแก้ไขรายละเอียดรายงานของคุณได้ด้านล่าง',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              _buildReasonContainer(
                  'เหตุใดคุณจึงรายงานโพสต์นี้', selectedReason!),
              const SizedBox(height: 10),
              _buildAdditionalInfoContainer(),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final reportRef = firestore.collection('Reports').doc();

                  await reportRef.set({
                    'reportBy': auth.currentUser!.uid,
                    'userID': userId,
                    'reason': selectedReason!,
                    'details': _controller.text,
                    'status': 'Pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  fixedSize: MaterialStateProperty.all(const Size(100, 30)),
                ),
                child: const Text(
                  'ส่ง',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonContainer(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'โปรดอธิบายเพิ่มเติม',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _controller,
            maxLines: 2,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Colors.grey, width: 1), // กรอบพื้นฐาน
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Colors.grey, width: 1), // กรอบเมื่อเปิดใช้งาน
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Colors.black54, width: 1), // กรอบเมื่อมีโฟกัส
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'ระบุรายละเอียดเพิ่มเติมที่นี่...',
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            ),
          ),
        ],
      ),
    );
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
                  icon: const Icon(Icons.arrow_back_ios)),
            ),
            endDrawer: SizedBox(
              width: MediaQuery.of(context).size.width / 2.3,
              child: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const DrawerHeader(
                        decoration: BoxDecoration(color: Colors.black54),
                        child: Text(
                          'เมนู',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        )),
                    ListTile(
                      leading: const Icon(
                        Icons.report,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'รายงานปัญหา',
                        style: TextStyle(fontSize: 15, color: Colors.redAccent),
                      ),
                      onTap: () {
                        reportDialog(context, widget.informationUserUID);
                      },
                    ),
                  ],
                ),
              ),
            ),
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
                Container(
                  child: historyWithPost[0]
                      ? VisitPostProfile(userId: widget.informationUserUID)
                      : VisitHistoryPost(userId: widget.informationUserUID),
                )
              ],
            )));
  }
}
