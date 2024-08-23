import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exchange/screen/exchange/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatAdmin extends StatefulWidget {
  final String chatId, name;
  const ChatAdmin({super.key, required this.chatId, required this.name});

  @override
  State<ChatAdmin> createState() => _ChatAdminState();
}

class _ChatAdminState extends State<ChatAdmin> {
  final TextEditingController _textController = TextEditingController();
  final _user = types.User(id: FirebaseAuth.instance.currentUser!.uid);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  List<types.Message> _messages = [];
  String? _thumbnailPath;
  bool isVideo = false;
  File? _mediaFile;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('adminChat')
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

  void _addMessage(types.Message message) async {
    setState(() {
      _messages.insert(0, message);
    });

    FirebaseFirestore.instance
        .collection('adminChat')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          elevation: 1,
          toolbarHeight: 100,
          backgroundColor: Colors.white,
          title: Text(widget.name),
        ),
      ),
      body: SafeArea(
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
      )),
    );
  }
}
