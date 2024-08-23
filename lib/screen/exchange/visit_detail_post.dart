import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/match_utils.dart';
import 'package:exchange/screen/exchange/visit_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VisitDetailPost extends StatefulWidget {
  final String postId;
  const VisitDetailPost({super.key, required this.postId});

  @override
  State<VisitDetailPost> createState() => _VisitDetailPostState();
}

class _VisitDetailPostState extends State<VisitDetailPost> {
  TextEditingController bidController = TextEditingController();
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  bool isFavorite = false;
  bool isLoading = false;
  bool waitingReport = false;
  String? selectedReason;

  @override
  void initState() {
    super.initState();
    checkIfLiked();
  }

  Future<void> checkIfLiked() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final postSnapshot = await postRef.get();

    if (postSnapshot.exists && postSnapshot.data()!.containsKey('likes')) {
      final likes = List<String>.from(postSnapshot.data()!['likes']);
      setState(() {
        isFavorite = likes.contains(currentUserId);
      });
    }
  }

  Future<void> handleLikePost(String postId) async {
    setState(() {
      isLoading = true;
    });

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);

      if (!postSnapshot.exists) {
        throw Exception("Post does not exist!");
      }

      List<String> likes;
      if (postSnapshot.data()!.containsKey('likes')) {
        likes = List<String>.from(postSnapshot.data()!['likes']);
      } else {
        likes = [];
      }

      if (isFavorite) {
        likes.remove(currentUserId);
        transaction.update(postRef, {'likes': likes});
        setState(() {
          isFavorite = false;
        });
      } else if (postSnapshot.data()!['status'] == 'available') {
        likes.add(currentUserId);
        transaction.update(postRef, {'likes': likes});
        await MatchUtils.checkMatch(postSnapshot, currentUserId, transaction);

        if (postSnapshot.data()!.containsKey('matchedUserId') &&
            postSnapshot.data()!['matchedUserId'] == currentUserId) {
          transaction.update(postRef, {'status': 'matched'});
        }
        setState(() {
          isFavorite = true;
        });
      }
    });

    setState(() {
      isLoading = false;
    });
  }

  Future<void> showBidDialog(String postId, String userId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'เสนอราคา',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'ใส่ราคาที่คุณต้องการเสนอ (บาท):',
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "ราคาเสนอ",
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black54),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('ยกเลิก', style: TextStyle(color: Colors.black54)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('เสนอ', style: TextStyle(color: Colors.black54)),
              onPressed: () {
                createChat(postId, userId, bidController.text);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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

  Future<void> createChat(
      String postId, String userId, String bidAmount) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final docRef = await FirebaseFirestore.instance.collection('Chats').add({
        'matchType': 'offer',
        'status': 'offer',
        'postIds': [postId],
        'userIds': [userId, currentUserId],
        'createdAt': Timestamp.now(),
        'isExchanged': false,
        'bidAmount': bidAmount,
      });

      final chatId = docRef.id;
      print('Chat created successfully with id: $chatId');

      await sendNotification(chatId, userId, currentUserId, bidAmount);
    } catch (e) {
      print('Failed to create chat: $e');
    }
  }

  Future<void> sendNotification(String chatId, String userId,
      String currentUserId, String bidAmount) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final notificationRef = firestore.collection('Notifications').doc();

    await notificationRef.set({
      'userId': userId,
      'title': 'มีการเสนอซื้อสิ่งของ',
      'message': 'เสนอซื้อสิ่งของ ของคุณในราคา',
      'type': 'offer',
      'bidAmount': bidAmount,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'currentUserId': currentUserId
    });

    print('Notification sent successfully');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !isLoading, // Prevent back navigation if loading
      child: MaterialApp(
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
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              icon: const Icon(Icons.arrow_back_ios),
            ),
          ),
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
              final postData = post.data() as Map<String, dynamic>;
              final images = List<String>.from(postData['Images']);
              final userId = postData['UserId'];
              final postCategory = postData['PostCategory'];
              final createdAt = postData.containsKey('createdAt')
                  ? (postData['createdAt'] as Timestamp).toDate()
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
                                            builder: (context) => VisitProfile(
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
                                      width: MediaQuery.of(context).size.width /
                                          100,
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VisitProfile(
                                                informationUserUID:
                                                    post['UserId']),
                                          )),
                                      child: Text(
                                        snapshot2.data!['Name'],
                                        style: const TextStyle(fontSize: 17),
                                      ),
                                    ),
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
                                    reportDialog(context, widget.postId);
                                  } else {
                                    null;
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
                                  padding:
                                      const EdgeInsets.fromLTRB(3, 6, 16, 7),
                                  child: SizedBox(
                                    height: 6,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                            if (postCategory == 'ขายเท่านั้น') ...[
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.black54),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  "เสนอซื้อ",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                onPressed: () {
                                  showBidDialog(post.id, userId);
                                },
                              ),
                            ] else if (postCategory ==
                                    'แลกเปลี่ยนสิ่งของเท่านั้น' ||
                                postCategory == 'แลกเปลี่ยนและขาย') ...[
                              IconButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        handleLikePost(widget.postId);
                                      },
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 35,
                                  color: isFavorite ? Colors.red : Colors.black,
                                ),
                              ),
                              if (postCategory == 'แลกเปลี่ยนและขาย')
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
                                  ),
                                  child: const Text(
                                    "เสนอซื้อ",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                  onPressed: () {
                                    showBidDialog(post.id, userId);
                                  },
                                ),
                            ],
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.symmetric(vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.grey[350],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                postCategory ?? 'No PostCategory',
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
                              ],
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 100,
                            ),
                            Text(
                              post['Detail'] ?? 'No Detail',
                              style: const TextStyle(
                                fontSize: 16,
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
      ),
    );
  }
}
