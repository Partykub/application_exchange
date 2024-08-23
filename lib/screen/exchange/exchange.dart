import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/ctegory.dart';
import 'package:exchange/screen/exchange/visit_detail_post.dart';
import 'package:exchange/screen/exchange/visit_profile.dart';
import 'package:exchange/screen/notificatioin/notification.dart'; // Import หน้าแจ้งเตือนที่เราเพิ่งสร้าง
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Exchange extends StatefulWidget {
  const Exchange({super.key});

  @override
  State<Exchange> createState() => _ExchangeState();
}

class _ExchangeState extends State<Exchange> {
  final auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  bool waitingReport = false;
  String? selectedReason;
  final TextEditingController _controller = TextEditingController();

  void _handleReasonTap(String reason, postId) {
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
                    'postID': postId,
                    'reason': selectedReason!,
                    'details': _controller.text,
                    'status': 'Pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
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
        color: Colors.grey[50],
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
        color: Colors.grey[50],
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

  Widget _buildReportOption(String text, postId) {
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
        _handleReasonTap(text, postId);
      },
    );
  }

  void reportDialog(BuildContext context, postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
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
                  'โพสต์สิ่งของที่ผิดกฎหมายหรือสิ่งของต้องห้าม', postId),
              _buildReportOption(
                  'โพสต์สิ่งของที่มีเนื้อหาลามกอนาจารหรือไม่เหมาะสม', postId),
              _buildReportOption(
                  'สิ่งของไม่ตรงตามคำบรรยายหรือรูปภาพที่โพสต์', postId),
              _buildReportOption(
                  'โพสต์สิ่งของที่มีความเสี่ยงต่อความปลอดภัยหรือสุขภาพ',
                  postId),
              _buildReportOption(
                  'การโพสต์เนื้อหาที่เป็นการหลอกลวงหรือฉ้อโกง', postId),
              _buildReportOption(
                  'การใช้ถ้อยคำที่ไม่เหมาะสมหรือการก่อกวนในโพสต์', postId),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> getUnreadNotificationsCount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('Notifications')
        .where('userId', isEqualTo: currentUser!.uid)
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ค้นหาสิ่งของ...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                FutureBuilder<int>(
                  future: getUnreadNotificationsCount(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const IconButton(
                        icon: Icon(
                          Icons.notifications,
                          size: 30,
                        ),
                        onPressed: null,
                      );
                    }

                    final int unreadCount = snapshot.data!;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            size: 30,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationPage(),
                              ),
                            ).then((_) {
                              setState(
                                  () {}); // Refresh icon count when returning
                            });
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 11,
                            top: 11,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Container(
              color: Colors.grey[200],
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 450,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height / 8.5,
                    width: double.infinity,
                    color: Colors.white,
                    child: Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height / 9,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            buildCategoryButton(context, 'สุขภาพและความงาม',
                                'lib/images/health_and_beauty.JPG'),
                            buildCategoryButton(context, 'เครื่องแต่งกาย',
                                'lib/images/clothing.JPG'),
                            buildCategoryButton(
                                context, 'กีฬา', 'lib/images/sport.JPG'),
                            buildCategoryButton(context, 'อิเล็กทรอนิกส์',
                                'lib/images/electronic.JPG'),
                            buildCategoryButton(context, 'เครื่องใช้ไฟฟ้า',
                                'lib/images/electrical_appliance.JPG'),
                            buildCategoryButton(context, 'อุปกรณ์สัตว์เลี้ยง',
                                'lib/images/pet_supplies.jpg'),
                            buildCategoryButton(context, 'อุปกรณ์สำนักงาน',
                                'lib/images/office_equipment.JPG'),
                            buildCategoryButton(context, 'อุปกรณ์ช่าง',
                                'lib/images/Mechanic_equipment.JPG'),
                            buildCategoryButton(context, 'บ้านและครอบครัว',
                                'lib/images/furniture.JPG'),
                            buildCategoryButton(context, 'ของเล่นและเกมส์',
                                'lib/images/Toys_and_games.JPG'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('status', isEqualTo: 'available')
                          .snapshots(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 50,
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height /
                                        130,
                                  ),
                                  const Text(
                                    "ยังไม่มีโพสต์",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final posts = snapshot.data!.docs.where((doc) {
                          return doc['UserId'] != auth.currentUser!.uid &&
                              doc['Name'].toString().contains(searchQuery);
                        }).toList();

                        return Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            color: Colors.grey[100],
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 0.5,
                                crossAxisSpacing: 0.5,
                                childAspectRatio: 0.6, // ปรับค่านี้ให้เหมาะสม
                              ),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final post = posts[index];
                                final image = List<String>.from(post['Images']);
                                final userId = post['UserId'];
                                final createdAt = post
                                        .data()
                                        .containsKey('createdAt')
                                    ? (post['createdAt'] as Timestamp).toDate()
                                    : DateTime.now();

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VisitDetailPost(postId: post.id),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                    child: Column(
                                      children: [
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('informationUser')
                                              .doc(userId)
                                              .snapshots(),
                                          builder: (context, snapshot2) {
                                            if (snapshot2.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }
                                            if (!snapshot2.hasData ||
                                                !snapshot2.data!.exists) {
                                              return const Center(
                                                  child:
                                                      Text('User not found'));
                                            }
                                            return Container(
                                              color: Colors.white,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 0, 0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    VisitProfile(
                                                                        informationUserUID:
                                                                            post['UserId']),
                                                              ),
                                                            );
                                                          },
                                                          child: CircleAvatar(
                                                            radius: 16,
                                                            backgroundImage:
                                                                CachedNetworkImageProvider(
                                                              snapshot2.data![
                                                                  'profileImageUrl'],
                                                            ),
                                                            backgroundColor:
                                                                Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              50,
                                                        ),
                                                        GestureDetector(
                                                          onTap: () =>
                                                              Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  VisitProfile(
                                                                      informationUserUID:
                                                                          post[
                                                                              'UserId']),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            snapshot2
                                                                .data!['Name'],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        15),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                    PopupMenuButton<String>(
                                                      color: Colors.white,
                                                      itemBuilder: (BuildContext
                                                              context) =>
                                                          <PopupMenuEntry<
                                                              String>>[
                                                        const PopupMenuItem<
                                                            String>(
                                                          value: 'profile',
                                                          child: ListTile(
                                                            leading: Icon(Icons
                                                                .person_pin_sharp),
                                                            title: Text(
                                                                'เยี่ยมชมโปรไฟล์'),
                                                          ),
                                                        ),
                                                        PopupMenuItem<String>(
                                                          value: 'report',
                                                          child: ListTile(
                                                            leading: Icon(
                                                                Icons.report,
                                                                color: Colors
                                                                    .red[400]),
                                                            title: Text(
                                                              'รายงาน',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                          .red[
                                                                      400]),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      offset:
                                                          const Offset(0, 50),
                                                      onSelected:
                                                          (String value) {
                                                        if (value == 'report') {
                                                          reportDialog(
                                                              context, post.id);
                                                        } else if (value ==
                                                            'profile') {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  VisitProfile(
                                                                      informationUserUID:
                                                                          post[
                                                                              'UserId']),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(0),
                                              topRight: Radius.circular(0),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: image.isNotEmpty
                                                  ? image[0]
                                                  : '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  2.5, // ปรับความสูงของรูปภาพ
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child: SizedBox(
                                                  height: 40,
                                                  width: 40,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.black,
                                                    strokeWidth: 3,
                                                  ),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          color: Colors.white,
                                          padding: const EdgeInsets.all(8.0),
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post['Name'] ?? 'No Name',
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    160,
                                              ),
                                              Text(post['Detail'] ??
                                                  'No Detail'),
                                              SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    160,
                                              ),
                                              Text(
                                                DateFormat('dd/MM/yyyy HH:mm')
                                                    .format(createdAt),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    160,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    margin: const EdgeInsets
                                                        .symmetric(vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                        post['PostCategory'] ??
                                                            'No PostCategory'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}

Widget buildCategoryButton(
  BuildContext context,
  String label,
  String imageUrl,
) {
  return Container(
    width: 160,
    margin: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height / 13,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Category(category: label),
                ),
              );
            },
            child: Container(), // To make the button itself invisible
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height / 200,
        ), // Add some spacing between the image and the label
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 13),
        ),
      ],
    ),
  );
}
