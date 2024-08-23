import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

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
    final text =
        lastMessage.data().containsKey('text') ? lastMessage['text'] : '';
    final uri =
        lastMessage.data().containsKey('uri') ? lastMessage['uri'] : null;
    final thumbnail = lastMessage.data().containsKey('thumbnail')
        ? lastMessage['thumbnail']
        : null;
    final sentAt = lastMessage['sentAt'];
    final isUnread = senderId != currentUser!.uid;

    String senderName = senderId == currentUser!.uid ? 'คุณ' : otherUserName;

    // แปลงเวลาให้เป็นรูปแบบที่อ่านได้ง่าย
    String formattedTime =
        DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sentAt));

    String messageText;
    if (uri != null && thumbnail == null) {
      messageText = '$senderName ได้ส่งรูปภาพ     $formattedTime';
    } else if (uri != null && thumbnail != null) {
      messageText = '$senderName ได้ส่งวิดีโอ     $formattedTime';
    } else {
      messageText = text.isNotEmpty
          ? '$text     $formattedTime'
          : 'ข้อความถูกลบ $formattedTime';
    }

    return {
      'text': messageText,
      'isUnread': isUnread,
    };
  }

  String getPostTypeText(String status) {
    if (status == 'offer') {
      return 'เสนอซื้อ';
    } else if (status == 'match') {
      return 'แมทช์';
    } else if (status == 'successfully') {
      return 'แลกเปลี่ยนสำเร็จสำเร็จ';
    } else if (status == 'unsuccessful') {
      return 'แลกเปลี่ยนไม่สำเร็จ';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.1), // ขนาดของเส้นใต้
          child: Container(
            color: Colors.grey[100], // สีของเส้นใต้
            height: 1.0,
          ),
        ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_outlined,
                    size: 40,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 130,
                  ),
                  const Text(
                    'ยังไม่มีแชท',
                    style: TextStyle(fontSize: 18),
                  )
                ],
              ),
            );
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
                final status = chatData.containsKey('status')
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
                      return Container();
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
                          return Container();
                        }
                        final lastMessage =
                            messageSnapshot.data?['text'] ?? 'แตะเพื่อแชท';
                        final isUnread =
                            messageSnapshot.data?['isUnread'] ?? false;

                        return Container(
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(otherUser!['profileImageUrl']),
                            ),
                            title: Text(
                              otherUser['Name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              lastMessage,
                              style: TextStyle(
                                color: isUnread ? Colors.black : Colors.black54,
                                fontWeight: isUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Text(
                              getPostTypeText(status),
                              style: TextStyle(
                                color: status == 'successfully'
                                    ? Colors.green
                                    : status == 'unsuccessful'
                                        ? Colors.red
                                        : Colors.blue,
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
    );
  }
}
