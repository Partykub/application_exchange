import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/chat/exchange_utils.dart';
import 'package:exchange/screen/exchange/chat/unsuccessful_exchange.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String name;

  const ChatScreen({required this.chatId, required this.name, Key? key})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  List<types.Message> _messages = [];
  final _user = types.User(id: FirebaseAuth.instance.currentUser!.uid);
  File? _mediaFile;
  String? _thumbnailPath;
  final TextEditingController _textController = TextEditingController();
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  bool isVideo = false;
  String? otherPostId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      List<types.Message> messages = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];

        // ดึงข้อมูลผู้ใช้จาก Firestore
        final userSnapshot = await FirebaseFirestore.instance
            .collection('informationUser')
            .doc(senderId)
            .get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.data();
          final user = types.User(
            id: senderId,
            firstName: userData?['firstName'],
            lastName: userData?['lastName'],
            imageUrl: userData?['profileImageUrl'],
          );

          if (data['type'] == 'text') {
            messages.add(types.TextMessage(
              author: user,
              createdAt: data['sentAt'],
              id: doc.id,
              text: data['text'],
            ));
          } else if (data['type'] == 'image') {
            messages.add(types.ImageMessage(
              author: user,
              createdAt: data['sentAt'],
              id: doc.id,
              name: data['name'],
              size: data['size'],
              uri: data['uri'],
            ));
          } else if (data['type'] == 'video') {
            messages.add(types.VideoMessage(
              author: user,
              createdAt: data['sentAt'],
              id: doc.id,
              name: data['name'],
              size: data['size'],
              uri: data['uri'],
              metadata: {'thumbnail': data['thumbnail']},
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    });
  }

  void _addMessage(types.Message message) async {
    setState(() {
      _messages.insert(0, message);
    });

    FirebaseFirestore.instance
        .collection('Chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': _user.id,
      'sentAt': message.createdAt,
      'text': message is types.TextMessage ? message.text : null,
      'uri': message is types.VideoMessage || message is types.ImageMessage
          ? (message as dynamic).uri
          : null,
      'name': message is types.VideoMessage || message is types.ImageMessage
          ? (message as dynamic).name
          : null,
      'size': message is types.VideoMessage || message is types.ImageMessage
          ? (message as dynamic).size
          : null,
      'thumbnail': message is types.VideoMessage
          ? (message.metadata?['thumbnail'] as String?)
          : null,
      'type': message is types.TextMessage
          ? 'text'
          : message is types.ImageMessage
              ? 'image'
              : 'video',
    });
  }

  Future<String?> preViewThumbnail(String videoUrl) async {
    final tempDir = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 100,
      quality: 75,
    );

    if (thumbnailPath != null) {
      final thumbnailFile = File(thumbnailPath);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('thumbnails/${DateTime.now().millisecondsSinceEpoch}.png');
      final uploadTask = storageRef.putFile(thumbnailFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Debug: Check if thumbnail creation and upload was successful
      print('Thumbnail created at path: $thumbnailPath');
      print('Thumbnail uploaded to URL: $downloadUrl');

      return downloadUrl;
    }

    // Debug: Check if thumbnail creation failed
    print('Failed to create thumbnail for video at URL: $videoUrl');
    return null;
  }

  Future<String?> _generateThumbnail(String videoUrl) async {
    final tempDir = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 100,
      quality: 75,
    );

    if (thumbnailPath != null) {
      final thumbnailFile = File(thumbnailPath);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('thumbnails/${DateTime.now().millisecondsSinceEpoch}.png');
      final uploadTask = storageRef.putFile(thumbnailFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Debug: Check if thumbnail creation and upload was successful
      print('Thumbnail created at path: $thumbnailPath');
      print('Thumbnail uploaded to URL: $downloadUrl');

      return downloadUrl;
    }

    // Debug: Check if thumbnail creation failed
    print('Failed to create thumbnail for video at URL: $videoUrl');
    return null;
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height / 5.5,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'รูปภาพ',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleVideoSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child:
                      Text('วิดีโอ', style: TextStyle(color: Colors.black87)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child:
                      Text('ยกเลิก', style: TextStyle(color: Colors.black87)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleVideoSelection() async {
    final result = await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        _mediaFile = File(result.path);
        isVideo = true;
      });
      final thumbnailPath = await preViewThumbnail(result.path);
      if (mounted) {
        setState(() {
          _thumbnailPath = thumbnailPath;
        });
      }
      print('thumbnailPath: $_thumbnailPath');
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      setState(() {
        _mediaFile = File(result.path);
        isVideo = false;
      });
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    if (!mounted) return;

    isLoading.value = true;

    if (_mediaFile != null) {
      final storageRef = FirebaseStorage.instance.ref().child(
          'chat_media/${DateTime.now().millisecondsSinceEpoch}_${_mediaFile!.path.split('/').last}');
      final bytes = _mediaFile!.readAsBytesSync();
      final uploadTask = storageRef.putData(bytes);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (isVideo) {
        final thumbnailUrl = await _generateThumbnail(downloadUrl);

        final videoMessage = types.VideoMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          name: _mediaFile!.path.split('/').last,
          size: bytes.length,
          uri: downloadUrl,
          metadata: {'thumbnail': thumbnailUrl},
        );

        _addMessage(videoMessage);
      } else {
        final image = await decodeImageFromList(bytes);

        final imageMessage = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          height: image.height.toDouble(),
          id: const Uuid().v4(),
          name: _mediaFile!.path.split('/').last,
          size: bytes.length,
          uri: downloadUrl,
          width: image.width.toDouble(),
        );

        _addMessage(imageMessage);
      }

      setState(() {
        _mediaFile = null;
      });
    } else {
      final text = message.text;
      if (text.isNotEmpty) {
        final textMessage = types.TextMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: text,
        );

        _addMessage(textMessage);
      }
    }

    isLoading.value = false;
  }

  Widget _buildInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      // height: MediaQuery.of(context).size.height / 9,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              // border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(16.0),
              color: Colors.grey[300],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      size: 30, color: Colors.black87),
                  onPressed: _handleAttachmentPressed,
                ),
                if (_mediaFile != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      isVideo
                          ? Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey,
                              child: _thumbnailPath == null
                                  ? const Icon(
                                      Icons.videocam,
                                      size: 20,
                                    )
                                  : Image.network(
                                      _thumbnailPath!,
                                      width: 50,
                                      height: 20,
                                      fit: BoxFit.cover,
                                    ) //
                              )
                          : Image.file(
                              _mediaFile!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _mediaFile = null;
                          });
                        },
                        child: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      focusColor: Colors.black87,
                      hintText: 'ส่งข้อความ...',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        _handleSendPressed(types.PartialText(text: text));
                        _textController.clear();
                      }
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, value, child) {
                    return IconButton(
                      icon: value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black87,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.black87),
                      onPressed: value
                          ? null
                          : () {
                              final text = _textController.text;
                              if (text.isNotEmpty || _mediaFile != null) {
                                _handleSendPressed(
                                    types.PartialText(text: text));
                                _textController.clear();
                              }
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessageTap(BuildContext context, types.Message message) {
    if (message is types.VideoMessage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoUrl: message.uri),
        ),
      );
    }
  }

  Future<ui.Image> _getImage(String uri) async {
    Completer<ui.Image> completer = Completer();
    final networkImage = NetworkImage(uri);
    final imageStream = networkImage.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        completer.complete(info.image);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception);
      },
    );
    imageStream.addListener(listener);
    return completer.future;
  }

  Widget customImageBuilder(
    types.Message message, {
    required int messageWidth,
  }) {
    if (message is types.ImageMessage) {
      return FutureBuilder<ui.Image>(
        future: _getImage(message.uri),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final image = snapshot.data!;
            final isLandscape = image.width > image.height;

            return Image.network(
              message.uri,
              width: isLandscape
                  ? messageWidth.toDouble() / 1.3
                  : messageWidth.toDouble() / 2,
              height: isLandscape
                  ? messageWidth.toDouble() / 2
                  : messageWidth.toDouble() / 1.3,
              fit: BoxFit.cover,
            );
          } else {
            return Container();
          }
        },
      );
    }
    return Container();
  }

  Widget customVideoBuilder(types.Message message,
      {required int messageWidth}) {
    if (message is types.VideoMessage) {
      return GestureDetector(
        onTap: () => _handleMessageTap(context, message),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.metadata != null &&
                message.metadata!['thumbnail'] != null)
              FutureBuilder<ui.Image>(
                future: _getImage(message.metadata!['thumbnail']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    final image = snapshot.data!;
                    final isLandscape = image.width > image.height;

                    return Stack(
                      children: [
                        Container(
                          color: Colors.grey[100],
                          child: Image.network(
                            message.metadata!['thumbnail'],
                            width: isLandscape
                                ? messageWidth.toDouble() / 1.3
                                : messageWidth.toDouble() / 2,
                            height: isLandscape
                                ? messageWidth.toDouble() / 2
                                : messageWidth.toDouble() / 1.3,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Positioned.fill(
                          child: Center(
                            child: Icon(Icons.play_circle_fill,
                                color: Colors.white, size: 50),
                          ),
                        ),
                      ],
                    );
                  }
                  return Container();
                },
              ),
          ],
        ),
      );
    }

    return Container();
  }

  Widget _avatarBuilder(dynamic user) {
    if (user is String) {
      if (user != _user.id) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
          child: FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('informationUser')
                  .doc(user)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  );
                } else if (snapshot.hasError) {
                  return const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.error, color: Colors.white),
                  );
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  );
                } else {
                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  var profileImageUrl = userData['profileImageUrl'];
                  if (profileImageUrl != null) {
                    return CircleAvatar(
                      radius: 17,
                      backgroundImage:
                          CachedNetworkImageProvider(profileImageUrl),
                      backgroundColor: Colors.grey,
                    );
                  } else {
                    return const CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  }
                }
              }),
        );
      }
    }

    return const SizedBox.shrink();
  }

  Future<Map<String, dynamic>> _getMatchedPost() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatId)
          .get();
      final data = chatDoc.data();

      if (data == null) {
        print('No data found for chatId: ${widget.chatId}');
        return {};
      }

      final postIds = data['postIds'] as List<dynamic>?;
      final matchType = data['matchType']; // ใช้บอกว่าเป็นการ match แบบไหน
      final statusType = data['status']; // ใช้เปลี่ยนสถานะของchat
      final bidAmount = data['bidAmount'];
      final userIds = data['userIds'] as List<dynamic>?;

      if (postIds == null || userIds == null || userIds.length != 2) {
        print('Invalid postIds or userIds');
        return {};
      }

      final oppositeUserId = userIds.firstWhere((id) => id != currentUser!.uid);

      String? myPostId;
      String? otherPostId;
      DocumentSnapshot<Map<String, dynamic>>? myPost;
      DocumentSnapshot<Map<String, dynamic>>? otherPost;
      DocumentSnapshot<Map<String, dynamic>>? postId;

      if (matchType == 'match') {
        final findOwnerPostRef1 = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postIds[0])
            .get();
        final findOwnerPostData1 = findOwnerPostRef1.data();
        final findOwnerPostId1 = findOwnerPostData1?['UserId'];

        final findOwnerPostRef2 = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postIds[1])
            .get();
        final findOwnerPostData2 = findOwnerPostRef2.data();
        final findOwnerPostId2 = findOwnerPostData2?['UserId'];

        myPostId =
            findOwnerPostId1 == currentUser!.uid ? postIds[1] : postIds[0];
        otherPostId =
            findOwnerPostId2 == currentUser!.uid ? postIds[1] : postIds[0];

        if (myPostId != null) {
          myPost = await FirebaseFirestore.instance
              .collection('posts')
              .doc(myPostId)
              .get();
        }

        if (otherPostId != null) {
          otherPost = await FirebaseFirestore.instance
              .collection('posts')
              .doc(otherPostId)
              .get();
        }
      } else if (matchType == 'offer') {
        postId = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postIds[0])
            .get();
      }

      return {
        'myPost': myPost?.data(), // ใช้แสดงข้อมูล post ในหน้า chat
        'otherPost': otherPost?.data(), // ใช้แสดงข้อมูล post ในหน้า chat
        'otherPostId': otherPostId, // ใช้เป็นรูปอ่้างอิงว่าเรารีวิว post ไหน
        'myPostId': myPostId,
        'statusType': statusType,
        'matchType': matchType,
        'oppositeUserId': oppositeUserId,
        'bidAmount': bidAmount,
        'postId': postId?.data(),
        'postIdData': postIds[0]
      };
    } catch (e) {
      print('Error fetching matched posts: $e');
      return {};
    }
  }

  void showResultSuccess(BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('ยืนยันการแลกเปลี่ยน'),
            content: SizedBox(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[400],
                    size: 100,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("ยืนยันการแลกเปลี่ยนสำเร็จ"),
                  )
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "ตกลง",
                            style: TextStyle(color: Colors.green),
                          )))
                ],
              )
            ],
          );
        });
  }

  void showResultUnsuccess(BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('ยืนยันการแลกเปลี่ยน'),
            content: SizedBox(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[400],
                    size: 100,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("ยืนยันการแลกเปลี่ยนไม่สำเร็จ"),
                  )
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "ตกลง",
                            style: TextStyle(color: Colors.green),
                          )))
                ],
              )
            ],
          );
        });
  }

  void showResultDialog(BuildContext context) async {
    final matchedPosts = await _getMatchedPost();
    if (mounted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'ผลการแลกเปลี่ยน',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'โปรดเลือกเหตุการณ์ที่เกิดขึ้น',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.grey,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          waiting = false;
                        },
                      ),
                      const Text('ยกเลิก',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 30,
                        ),
                        onPressed: () {
                          waiting = false;
                          Navigator.of(context).pop();
                          showUnsuccessfulExchangeDialog(context);
                        },
                      ),
                      const Text('ไม่สำเร็จ',
                          style: TextStyle(color: Colors.red, fontSize: 15)),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 30,
                        ),
                        onPressed: () {
                          waiting = false;
                          Navigator.of(context).pop();
                          showReviewDialog(
                              context,
                              matchedPosts['matchType'] == 'offer'
                                  ? matchedPosts['postIdData']
                                  : matchedPosts['otherPostId'],
                              matchedPosts['oppositeUserId'],
                              matchedPosts['bidAmount']);
                        },
                      ),
                      const Text('สำเร็จ',
                          style: TextStyle(color: Colors.green, fontSize: 15)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 60),
            ],
          ),
        ),
      );
    }
  }

  void showUnsuccessfulExchangeDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 30,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 60,
            ),
            const Text(
              'แลกเปลี่ยนไม่สำเร็จ',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.w100,
              ),
            ),
          ],
        ),
        content: const Text(
          'การแลกเปลี่ยนนี้ไม่สำเร็จ',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              UnsuccessfulUtils utils = UnsuccessfulUtils();
              await utils.unsuccessfulExchange(widget.chatId, context);
              if (mounted) {
                Navigator.of(context).pop();
                showResultUnsuccess(context);
              }
            },
            child: const Text(
              'ตกลง',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'ยกเลิก',
              style:
                  TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void showReviewDialog(
      BuildContext context, otherPostId, oppositeUserId, bidAmount) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        String reviewText = '';
        File? reviewImage;
        double rating = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                'รีวิวการแลกเปลี่ยน',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w100,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'โปรดให้รีวิวการแลกเปลี่ยนของคุณ',
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'ให้คะแนน: ',
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                        RatingBar.builder(
                          initialRating: 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 25.0, // ลดขนาดดาว
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 2.0),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (ratingValue) {
                            setState(() {
                              rating = ratingValue;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'เขียนรีวิว',
                            labelStyle:
                                TextStyle(fontSize: 14, color: Colors.black54),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.black54), // เปลี่ยนสีขอบที่นี่
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.black54), // เปลี่ยนสีขอบที่นี่
                            ),
                          ),
                          maxLines: 1,
                          onChanged: (value) {
                            reviewText = value;
                          },
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: reviewImage != null
                              ? Image.file(
                                  reviewImage!,
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                )
                              : IconButton(
                                  icon: const Icon(
                                      Icons.add_photo_alternate_outlined),
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      setState(() {
                                        reviewImage = File(pickedFile.path);
                                      });
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ),
                //// ยืนยัน ////
                rating <= 0
                    ? const Text(
                        'ยืนยัน',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w500),
                      )
                    : TextButton(
                        onPressed: () async {
                          if (reviewText.isNotEmpty ||
                              reviewImage != null ||
                              rating > 0) {
                            if (reviewImage != null) {
                              //เพิ่มรูปภาพรีวิว
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(
                                      'review_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                              await storageRef.putFile(reviewImage!);
                              final reviewImageUrl =
                                  await storageRef.getDownloadURL();

                              // Save review data to Firestore
                              final reviewData = {
                                'text': reviewText,
                                'rating': rating,
                                'imageUrl': reviewImageUrl,
                                'otherPostId': otherPostId,
                                'recipientReview': oppositeUserId,
                                'reviewer': currentUser!.uid,
                                'timestamp': FieldValue.serverTimestamp(),
                              };
                              await FirebaseFirestore.instance
                                  .collection('reviews')
                                  .add(reviewData);
                            } else {
                              // Save review text and rating only
                              final reviewData = {
                                'text': reviewText,
                                'rating': rating,
                                'otherPostId': otherPostId,
                                'recipientReview': oppositeUserId,
                                'reviewer': currentUser!.uid,
                                'timestamp': FieldValue.serverTimestamp(),
                              };
                              await FirebaseFirestore.instance
                                  .collection('reviews')
                                  .add(reviewData);
                            }
                          } else if (rating <= 0) {
                            null;
                          }

                          ExchangeUtils exchangeUtils = ExchangeUtils();

                          if (mounted) {
                            exchangeUtils.confirmExchange(
                                widget.chatId, context);
                            Navigator.of(context).pop();
                            showResultSuccess(context);
                          }
                        },
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500),
                        )),
              ],
            );
          },
        );
      },
    );
  }

  bool waiting = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.1), // ขนาดของเส้นใต้
            child: Container(
              color: Colors.grey[100], // สีของเส้นใต้
              height: 1.0,
            ),
          ),
          actions: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: FutureBuilder(
                future: _getMatchedPost(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No matched posts found'),
                    );
                  }

                  final status = snapshot.data!['statusType'];
                  final matchType = snapshot.data!['matchType'];
                  final postId = snapshot.data!['postId'];

                  final myPost = snapshot.data!['postId'];
                  final otherPost = snapshot.data!['postId'];

                  return matchType == 'offer'
                      ? ElevatedButton(
                          onPressed: () {
                            if (waiting) {
                              null;
                            } else {
                              if (status == 'successfully' ||
                                  status == 'unsuccessful' ||
                                  myPost['status'] == 'successfully' ||
                                  otherPost['status'] == 'successfully' ||
                                  postId['status'] == 'successfully') {
                                null;
                              } else {
                                waiting = true;
                                showResultDialog(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: status == 'successfully' ||
                                    postId['status'] == 'successfully'
                                ? Colors.green
                                : status == 'unsuccessful'
                                    ? Colors.red
                                    : Colors.blue, // เปลี่ยนสีพื้นหลังของปุ่ม
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0), // ขนาดของ padding ในปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // ปรับมุมโค้งของปุ่ม
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14, // ขนาดตัวอักษรในปุ่ม
                              fontWeight:
                                  FontWeight.bold, // น้ำหนักตัวอักษรในปุ่ม
                            ),
                          ),
                          child: Text(status == 'successfully' ||
                                  postId['status'] == 'successfully'
                              ? 'แลกเปลี่ยนสำเร็จแล้ว'
                              : status == 'unsuccessful'
                                  ? 'แลกเปลี่ยนไม่สำเร็จ'
                                  : 'ยืนยันการแลกเปลี่ยน'),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            if (waiting) {
                              null;
                            } else {
                              if (status == 'successfully' ||
                                  status == 'unsuccessful') {
                                null;
                              } else {
                                waiting = true;
                                showResultDialog(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: status == 'successfully'
                                ? Colors.green
                                : status == 'unsuccessful'
                                    ? Colors.red
                                    : Colors.blue, // เปลี่ยนสีพื้นหลังของปุ่ม
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0), // ขนาดของ padding ในปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // ปรับมุมโค้งของปุ่ม
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14, // ขนาดตัวอักษรในปุ่ม
                              fontWeight:
                                  FontWeight.bold, // น้ำหนักตัวอักษรในปุ่ม
                            ),
                          ),
                          child: Text(status == 'successfully'
                              ? 'แลกเปลี่ยนสำเร็จแล้ว'
                              : status == 'unsuccessful'
                                  ? 'แลกเปลี่ยนไม่สำเร็จ'
                                  : 'ยืนยันการแลกเปลี่ยน'),
                        );
                },
              ),
            ),
          ],
          title: Text(
            widget.name,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: FutureBuilder(
                    future: _getMatchedPost(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator(
                          color: Colors.black,
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No matched posts found'),
                        );
                      }
                      final myPost = snapshot.data!['myPost'];
                      final otherPost = snapshot.data!['otherPost'];
                      final matchType = snapshot.data!['matchType'];
                      final bidAmount = snapshot.data!['bidAmount'];
                      final postId = snapshot.data!['postId'];

                      return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(
                                    0, 0), // changes position of shadow
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6.0),
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10.0),
                          child: matchType == 'match'
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    if (otherPost != null)
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: CachedNetworkImage(
                                              imageUrl: otherPost['Images'][0],
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  9,
                                              fit: BoxFit.cover,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            otherPost['Name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        ],
                                      ),
                                    const Icon(Icons.swap_horiz, size: 40),
                                    if (myPost != null)
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: CachedNetworkImage(
                                              imageUrl: myPost['Images'][0],
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  9,
                                              fit: BoxFit.cover,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            myPost['Name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: CachedNetworkImage(
                                            imageUrl: postId['Images'][0],
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                4,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                9,
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          postId['Name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 20.0),
                                    Text('จำนวนเงินที่เสนอ $bidAmount บาท',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ],
                                ));
                    },
                  ),
                ),
                Expanded(
                  child: Chat(
                    messages: _messages,
                    onAttachmentPressed: _handleAttachmentPressed,
                    onSendPressed: (types.PartialText message) =>
                        _handleSendPressed(message),
                    user: _user,
                    customBottomWidget: _buildInput(),
                    onMessageTap: _handleMessageTap,
                    videoMessageBuilder: customVideoBuilder,
                    imageMessageBuilder: customImageBuilder,
                    avatarBuilder: _avatarBuilder,
                    showUserAvatars: true,
                    theme: const DefaultChatTheme(
                      primaryColor: Colors.black26,
                      emptyChatPlaceholderTextStyle: TextStyle(
                        fontSize: 0,
                      ),
                    ),
                    dateFormat: DateFormat('dd/MM/yyyy HH:mm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    try {
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
      );
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing video player: $error';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white70,
          ),
        ),
      ),
      body: Container(
        color: Colors.black87,
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white70)
              : _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70),
                    )
                  : _chewieController != null
                      ? Platform.isAndroid &&
                              _videoPlayerController.value.size.width >
                                  _videoPlayerController.value.size.height
                          ? Transform.rotate(
                              angle: 3.14,
                              child: Chewie(
                                controller: ChewieController(
                                  materialProgressColors: ChewieProgressColors(
                                      playedColor: Colors.white70,
                                      bufferedColor: Colors.grey),
                                  videoPlayerController: _videoPlayerController,
                                  autoPlay: true,
                                  looping: false,
                                  customControls: Platform.isAndroid &&
                                          _videoPlayerController
                                                  .value.size.width >
                                              _videoPlayerController
                                                  .value.size.height
                                      ? Transform.rotate(
                                          angle: 3.14,
                                          child: const MaterialControls(),
                                        )
                                      : null,
                                ),
                              ),
                            )
                          : Chewie(
                              controller: ChewieController(
                                videoPlayerController: _videoPlayerController,
                                autoPlay: true,
                                looping: false,
                                materialProgressColors: ChewieProgressColors(
                                    playedColor: Colors.white70,
                                    bufferedColor: Colors.grey),
                                customControls: Platform.isAndroid &&
                                        _videoPlayerController
                                                .value.size.width >
                                            _videoPlayerController
                                                .value.size.height
                                    ? Transform.rotate(
                                        angle: 3.14,
                                        child: const MaterialControls(),
                                      )
                                    : null,
                              ),
                            )
                      : const CircularProgressIndicator(
                          color: Colors.white70,
                        ),
        ),
      ),
    ));
  }
}
