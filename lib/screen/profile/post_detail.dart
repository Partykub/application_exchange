import 'package:cached_network_image/cached_network_image.dart';
import 'package:exchange/screen/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;

  const PostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final itemNameController = TextEditingController();
  final itemDetailController = TextEditingController();
  final formKeyItemName = GlobalKey<FormState>();
  final formKeyItemDetail = GlobalKey<FormState>();

  final auth = FirebaseAuth.instance;
  late int indexPage;
  bool editPost = false;
  bool isLoading = false;
  bool isLoadingDelete = false;

  Future<void> updateDetailPost(String postId) async {
    try {
      String newNamePost = itemNameController.text;
      String newDetailPost = itemDetailController.text;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference postRaf = firestore.collection('posts').doc(postId);
      if (newNamePost.isNotEmpty) {
        await postRaf.update({'Name': newNamePost});
      }
      if (newDetailPost.isNotEmpty) {
        await postRaf.update({'Detail': newDetailPost});
      }
    } catch (error) {
      print("Error updating username: $error");
    } finally {
      setState(() {
        editPost = false;
      });
    }
  }

  Future<void> deletePost(postId, userId) async {
    try {
      isLoadingDelete = true;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference postRef = firestore.collection('posts').doc(postId);
      await postRef.delete();
      DocumentReference userDocRef =
          firestore.collection('informationUser').doc(userId);
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot userDocSnapshot = await transaction.get(userDocRef);

        if (!userDocSnapshot.exists ||
            userDocSnapshot.data() is! Map<String, dynamic> ||
            !(userDocSnapshot.data() as Map<String, dynamic>)
                .containsKey('NumberOfPosts')) {
          transaction.set(
              userDocRef, {'NumberOfPosts': 1}, SetOptions(merge: true));
        } else {
          int currentNumberOfPosts = (userDocSnapshot.data()
              as Map<String, dynamic>)['NumberOfPosts'] as int;
          transaction
              .update(userDocRef, {'NumberOfPosts': currentNumberOfPosts - 1});
        }
      });
    } catch (e) {
      print('Error Delete Post: $e');
    } finally {
      setState(() {
        isLoadingDelete = false;
      });
    }
  }

  void showDeleteConfirmationDialog(String postId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('ยืนยันการลบ'),
          content: const Text(
            'แน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            MaterialButton(
              onPressed: isLoadingDelete
                  ? null
                  : () async {
                      try {
                        await deletePost(postId, userId);
                        Navigator.of(context).pop();
                      } catch (e) {
                        print('Remove unsuccessful: $e');
                      } finally {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MainScreen(initialTabIndex: 4),
                          ),
                        );
                      }
                    },
              child: isLoadingDelete
                  ? const CircularProgressIndicator(
                      color: Colors.black,
                    )
                  : const Text(
                      'ลบ',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'ยกเลิก',
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: editPost ? const Text("แก้ไขโพสต์") : const Text('โพสต์'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 0.4,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post not found'));
          }

          if (snapshot.hasError) {
            print(snapshot.error);
          }

          final post = snapshot.data!;
          final images = List<String>.from(post['Images']);
          final userId = post['UserId'];
          final createdAt = (post['createdAt'] as Timestamp?)?.toDate();

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
                    builder: (BuildContext context, AsyncSnapshot snapshot2) {
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
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: CachedNetworkImageProvider(
                                    snapshot2.data['profileImageUrl'],
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 100,
                                ),
                                Text(
                                  snapshot2.data['Name'],
                                  style: const TextStyle(fontSize: 17),
                                ),
                              ],
                            ),
                          ),
                          editPost
                              ? TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          try {
                                            await updateDetailPost(post.id);
                                          } catch (error) {
                                            print(
                                                'Error edit Post Detail: $error');
                                          } finally {
                                            itemDetailController.clear();
                                            itemNameController.clear();
                                          }
                                        },
                                  child: const Text(
                                    "เสร็จสิ้น",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ))
                              : PopupMenuButton<String>(
                                  color: Colors.white,
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text(
                                          'แก้ไข',
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete,
                                            color: Colors.red[400]),
                                        title: Text('ลบ',
                                            style: TextStyle(
                                                color: Colors.red[400])),
                                      ),
                                    ),
                                  ],
                                  offset: const Offset(0, 50),
                                  onSelected: (String value) {
                                    if (value == 'edit') {
                                      setState(() {
                                        editPost = true;
                                      });
                                    } else if (value == 'delete') {
                                      showDeleteConfirmationDialog(
                                          post.id, userId);
                                    }
                                  },
                                ),
                        ],
                      );
                    },
                  ),
                  SizedBox(
                    height: 500, // กำหนดความสูงของ Container
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
                              padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(images.length,
                                    (int indexDots) {
                                  return Container(
                                    height: 7,
                                    width: 7,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: index == indexDots
                                            ? Colors.black
                                            : Colors.black26),
                                  );
                                }),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: editPost
                        ? Column(
                            children: [
                              Form(
                                key: formKeyItemName,
                                child: TextFormField(
                                  controller: itemNameController,
                                  maxLength: 25,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    labelText: post['Name'],
                                    labelStyle:
                                        const TextStyle(color: Colors.black38),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        width: 2,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Form(
                                key: formKeyItemDetail,
                                child: TextFormField(
                                  controller: itemDetailController,
                                  maxLines: 2,
                                  maxLength: 40,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    labelText: post['Detail'],
                                    labelStyle:
                                        const TextStyle(color: Colors.black38),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        width: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        width: 2,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : DetailPost(post: post, createdAt: createdAt),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DetailPost extends StatefulWidget {
  final post;
  final DateTime? createdAt;
  const DetailPost({super.key, required this.post, this.createdAt});

  @override
  State<DetailPost> createState() => _DetailPostState();
}

class _DetailPostState extends State<DetailPost> {
  bool isFavorite = false; // ตัวแปรสำหรับเก็บสถานะการกดไอคอนหัวใจ

  @override
  Widget build(BuildContext context) {
    final mediaQuerySize = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.post['Name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  widget.post['PostCategory'] ?? 'No PostCategory',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
            height: mediaQuerySize.height / 60,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: mediaQuerySize.width / 1.7,
                child: Text(
                  widget.post['Detail'] ?? 'No Detail',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
            height: mediaQuerySize.height / 60,
          ),
          if (widget.createdAt != null)
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(widget.createdAt!),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}
