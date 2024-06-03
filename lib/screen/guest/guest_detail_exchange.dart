import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/authLogin/login_main.dart';
import 'package:exchange/screen/guest/guest_profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuestDetailExchange extends StatefulWidget {
  final postId;
  const GuestDetailExchange({super.key, required this.postId});

  @override
  State<GuestDetailExchange> createState() => _GuestDetailExchangeState();
}

class _GuestDetailExchangeState extends State<GuestDetailExchange> {
  bool isFavorite = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('โพสต์'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: Colors.grey[200],
                height: 0.4,
              ),
            ),
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios))),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Post not found'));
            }
            final post = snapshot.data!;
            final images = List<String>.from(post['Images']);
            final userId = post['UserId'];
            final createdAt = post.data().containsKey('createdAt')
                ? (post['createdAt'] as Timestamp).toDate()
                : DateTime.now();

            return Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: CircularProgressIndicator(
                            color: Colors.black,
                          ));
                        }
                        if (!snapshot2.hasData || !snapshot2.data!.exists) {
                          return const Center(child: Text('User not found'));
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GuestProfile(
                                              informationUserUID:
                                                  post['UserId']),
                                        )),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                        snapshot2.data!['profileImageUrl'],
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 100,
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GuestProfile(
                                              informationUserUID:
                                                  post['UserId']),
                                        )),
                                    child: Text(
                                      snapshot2.data!['Name'],
                                      style: const TextStyle(fontSize: 17),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              color: Colors.white,
                              itemBuilder: (context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'report',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.report,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'รายงาน',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'report') {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ));
                                }
                              },
                            )
                          ],
                        );
                      },
                    ),
                    SizedBox(
                      height: 500,
                      child: PageView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Expanded(
                                  child: CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(
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
                              )),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(3, 6, 16, 7),
                                child: SizedBox(
                                  height: 6,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List<Widget>.generate(
                                        images.length, (int indexDots) {
                                      return Container(
                                        height: 7,
                                        width: 7,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            color: index == indexDots
                                                ? Colors.black
                                                : Colors.black26),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ));
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 35,
                              color: isFavorite ? Colors.red : Colors.black,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.symmetric(vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey[350],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              post['PostCategory'] ?? 'No PostCategory',
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 3, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                post['Name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (post['PostCategory'] == 'ขายเท่านั้น' ||
                                  post['PostCategory'] ==
                                      'แลกเปลี่ยนและขาย') ...[
                                ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.black54),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    // fixedSize: MaterialStateProperty.all(const Size(100, 30)),
                                  ),
                                  child: const Text(
                                    "เสนอซื้อ",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ));
                                  },
                                ),
                              ],
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 100,
                          ),
                          Text(
                            post['Detail'] ?? 'No Detail',
                            style: const TextStyle(
                              fontSize: 16,
                              // fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 100,
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
