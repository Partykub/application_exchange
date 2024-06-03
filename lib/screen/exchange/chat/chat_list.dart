import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>> getLastMessage(
      DocumentSnapshot chat, String otherUserName) async {
    final messagesQuery = await chat.reference
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();
    if (messagesQuery.docs.isEmpty) {
      return {
        'text': 'แตะเพื่อแชท',
        'isUnread': false,
      };
    }

    final lastMessage = messagesQuery.docs.first;
    final senderId = lastMessage['senderId'];
    final text = lastMessage['text'] ?? '';
    final imageUrl = lastMessage['imageUrl'];
    final videoUrl = lastMessage['videoUrl'];
    final isUnread = senderId != currentUser!.uid;

    String senderName = senderId == currentUser!.uid ? 'คุณ' : otherUserName;

    String messageText;
    if (imageUrl != null) {
      messageText = '$senderName ได้ส่งรูปภาพ';
    } else if (videoUrl != null) {
      messageText = '$senderName ได้ส่งวิดีโอ';
    } else {
      messageText = text.isNotEmpty ? '$senderName $text' : 'ข้อความถูกลบ';
    }

    return {
      'text': messageText,
      'isUnread': isUnread,
    };
  }

  String getPostTypeText(String postType) {
    if (postType == 'offer') {
      return 'เสนอซื้อ';
    } else if (postType == 'match') {
      return 'แมทช์';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.grey[300],
      home: Scaffold(
        appBar: AppBar(
          elevation: 1,
          backgroundColor: Colors.white,
          title: const Text('แชท'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Chats')
              .where('userIds', arrayContains: currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                color: Colors.black,
              ));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No chats yet'));
            }
            final chats = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
              child: ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final chatData =
                      chat.data() as Map<String, dynamic>; // แปลงเป็น Map
                  final otherUserId = chatData['userIds']
                      .firstWhere((id) => id != currentUser!.uid);
                  final postType = chatData.containsKey('status')
                      ? chatData['status']
                      : ''; // กำหนดค่าเริ่มต้นให้ postType

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('informationUser')
                        .doc(otherUserId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('Loading...'),
                        );
                      }
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const ListTile(
                          title: Text('User not found'),
                        );
                      }
                      final otherUser = userSnapshot.data;

                      return StreamBuilder<Map<String, dynamic>>(
                        stream: chat.reference
                            .collection('messages')
                            .orderBy('sentAt', descending: true)
                            .limit(1)
                            .snapshots()
                            .asyncMap((snapshot) =>
                                getLastMessage(chat, otherUser!['Name'])),
                        builder: (context, messageSnapshot) {
                          if (messageSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Loading...'),
                            );
                          }
                          final lastMessage =
                              messageSnapshot.data!['text'] ?? '';
                          final isUnread =
                              messageSnapshot.data!['isUnread'] ?? false;

                          return Container(
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(otherUser!['profileImageUrl']),
                              ),
                              title: Text(
                                otherUser['Name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                lastMessage,
                                style: TextStyle(
                                  color:
                                      isUnread ? Colors.black : Colors.black54,
                                  fontWeight: isUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: Text(
                                getPostTypeText(postType),
                                style: TextStyle(
                                  color: postType == 'offer'
                                      ? Colors.blue
                                      : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatId: chat.id,
                                      name: otherUser['Name'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
