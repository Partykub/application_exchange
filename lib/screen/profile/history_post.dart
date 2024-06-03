import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPost extends StatefulWidget {
  const HistoryPost({super.key});

  @override
  State<HistoryPost> createState() => _HistoryPostState();
}

class _HistoryPostState extends State<HistoryPost> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.grey[200],
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('UserId', isEqualTo: currentUser!.uid)
              .where('status',
                  isEqualTo: 'exchanged') // Filter for exchanged posts
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('ประวัติการแลกเปลี่ยน'));
            }
            final posts = snapshot.data!.docs;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index].data() as Map<String, dynamic>;
                final postTitle = post['Name'] ?? 'ไม่มีชื่อ';
                final postImage =
                    post['Images'] != null && post['Images'].isNotEmpty
                        ? post['Images'][0]
                        : '';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: postImage.isNotEmpty
                        ? Image.network(postImage,
                            width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported),
                    title: Text(postTitle),
                    subtitle: Text('แลกเปลี่ยนสำเร็จ'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
