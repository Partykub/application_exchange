import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/Login/main_login.dart';
import 'package:exchange/screen/authLogin%20Test/login_main.dart';
import 'package:exchange/screen/guest/guest_ctegory.dart';
import 'package:exchange/screen/guest/guest_detail_exchange.dart';
import 'package:exchange/screen/guest/guest_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuestExchange extends StatefulWidget {
  const GuestExchange({super.key});

  @override
  State<GuestExchange> createState() => _GuestExchangeState();
}

class _GuestExchangeState extends State<GuestExchange> {
  final auth = FirebaseAuth.instance;
  String searchQuery = '';

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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.black87),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainLogin()
                            // const LoginScreen(),
                            ));
                  },
                  child: const Text(
                    "เข้าสู่ระบบ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ))
            ],
          ),
        ),
        body: Container(
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                                height:
                                    MediaQuery.of(context).size.height / 130,
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
                      return doc['Name']
                          .toString()
                          .contains(searchQuery); // กรองโพสต์ตามคำค้นหา
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
                            childAspectRatio: 0.6,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final image = List<String>.from(post['Images']);
                            final userId = post['UserId'];
                            final createdAt =
                                post.data().containsKey('createdAt') &&
                                        post['createdAt'] != null
                                    ? (post['createdAt'] as Timestamp).toDate()
                                    : DateTime.now();

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          GuestDetailExchange(postId: post.id),
                                    ));
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
                                              child: Text('User not found'));
                                        }
                                        return Container(
                                          color: Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                10, 0, 0, 0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    GuestProfile(
                                                                        informationUserUID:
                                                                            post['UserId'])));
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
                                                      width:
                                                          MediaQuery.of(context)
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
                                                                    GuestProfile(
                                                                        informationUserUID:
                                                                            post['UserId']),
                                                              )),
                                                      child: Text(
                                                        snapshot2.data!['Name'],
                                                        style: const TextStyle(
                                                            fontSize: 15),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                PopupMenuButton<String>(
                                                  color: Colors.white,
                                                  itemBuilder: (BuildContext
                                                          context) =>
                                                      <PopupMenuEntry<String>>[
                                                    const PopupMenuItem<String>(
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
                                                          'รายงานปัญหา',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .red[400]),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  offset: const Offset(0, 50),
                                                  onSelected: (String value) {
                                                    if (value == 'report') {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const LoginScreen(),
                                                          ));
                                                    } else if (value ==
                                                        'profile') {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                GuestProfile(
                                                                    informationUserUID:
                                                                        post[
                                                                            'UserId']),
                                                          ));
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
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(0),
                                          topRight: Radius.circular(0),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              image.isNotEmpty ? image[0] : '',
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
                                              child: CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 3,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
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
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                160,
                                          ),
                                          Text(post['Detail'] ?? 'No Detail'),
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
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
      ),
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
                    builder: (context) => GuestCategory(category: label),
                  ));
            },
            child: Container(), // To make the button itself invisible
          ),
        ),
        SizedBox(
            height: MediaQuery.of(context).size.height /
                200), // Add some spacing between the image and the label
        Text(
          label,
          style: const TextStyle(
              color: Colors.black, fontSize: 13), // Change text color if needed
        ),
      ],
    ),
  );
}
