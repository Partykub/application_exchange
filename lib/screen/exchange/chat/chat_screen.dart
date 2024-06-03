import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatScreen extends StatefulWidget {
  final String chatId, name;

  const ChatScreen({Key? key, required this.chatId, required this.name})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isSending = false;
  File? _selectedImage;
  File? _selectedVideo;
  String? _selectedImageUrl;
  String? _selectedVideoUrl;
  UploadTask? _uploadTask;
  VideoPlayerController? _videoPlayerController;
  bool checkTime = false;

  void toggleCheckTime() {
    setState(() {
      checkTime = !checkTime;
    });
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  Future<void> _sendMessage(String message,
      {String? imageUrl, String? videoUrl}) async {
    if (message.isEmpty && imageUrl == null && videoUrl == null) {
      return;
    }
    setState(() {
      _isSending = true;
    });
    await _firestore
        .collection('Chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'text': message,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'sentAt': FieldValue.serverTimestamp(),
    });
    _controller.clear();
    setState(() {
      _isSending = false;
      _selectedImage = null;
      _selectedVideo = null;
      _selectedImageUrl = null;
      _selectedVideoUrl = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
  }

  Future<void> _pickImage() async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied to access storage')),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isSending = true;
        _selectedImage = File(pickedFile.path);
        _selectedVideo = null;
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
      });
      final ref = _storage
          .ref()
          .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      _uploadTask = ref.putFile(_selectedImage!);
      _uploadTask!.then((taskSnapshot) async {
        final imageUrl = await taskSnapshot.ref.getDownloadURL();
        setState(() {
          _selectedImageUrl = imageUrl;
          _isSending = false;
        });
      }).catchError((error) {
        setState(() {
          _isSending = false;
        });
        print('Error uploading image: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $error')),
        );
      });
    }
  }

  Future<void> _pickVideo() async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied to access storage')),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      final fileSize = await pickedFile.length();
      const maxSizeInBytes = 50 * 1024 * 1024; // 50MB

      if (fileSize > maxSizeInBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Video size exceeds 50MB. Please select a smaller file.'),
          ),
        );
        return;
      }

      setState(() {
        _isSending = true;
        _selectedVideo = File(pickedFile.path);
        _selectedImage = null;
        _videoPlayerController = VideoPlayerController.file(_selectedVideo!)
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController!.setLooping(true);
            _videoPlayerController!.play();
          });
      });
      final ref = _storage
          .ref()
          .child('chat_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
      _uploadTask = ref.putFile(_selectedVideo!);
      _uploadTask!.then((taskSnapshot) async {
        final videoUrl = await taskSnapshot.ref.getDownloadURL();
        setState(() {
          _selectedVideoUrl = videoUrl;
          _isSending = false;
        });
      }).catchError((error) {
        setState(() {
          _isSending = false;
        });
        print('Error uploading video: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: $error')),
        );
      });
    }
  }

  void _cancelUpload() {
    if (_uploadTask != null) {
      _uploadTask!.cancel();
      setState(() {
        _isSending = false;
        _selectedImage = null;
        _selectedVideo = null;
        _selectedImageUrl = null;
        _selectedVideoUrl = null;
        _uploadTask = null;
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
      });
    }
  }

  Widget _buildMessage(Map<String, dynamic> message, String senderProfileUrl) {
    final isMe = message['senderId'] == currentUser!.uid;
    final messageContent = message['text'] ?? '';
    final imageUrl = message['imageUrl'];
    final videoUrl = message['videoUrl'];
    final sentAt = message['sentAt'];

    DateTime sentAtDateTime;
    if (sentAt is Timestamp) {
      sentAtDateTime = sentAt.toDate();
    } else if (sentAt is DateTime) {
      sentAtDateTime = sentAt;
    } else {
      sentAtDateTime = DateTime.now();
    }

    final formattedTime = DateFormat('HH:mm').format(sentAtDateTime);
    final formattedDate = DateFormat('dd/MM/yyyy').format(sentAtDateTime);

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (checkTime == true)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              '$formattedDate $formattedTime',
              style: const TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
          ),
        Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              CircleAvatar(
                backgroundImage: NetworkImage(senderProfileUrl),
                radius: 16,
              ),
            SizedBox(width: isMe ? 0 : 10),
            GestureDetector(
              onTap: toggleCheckTime,
              child: Container(
                margin: isMe
                    ? const EdgeInsets.only(left: 40.0)
                    : const EdgeInsets.only(right: 40.0),
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 15.0),
                decoration: BoxDecoration(
                  color: isMe ? Colors.grey[300] : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12.0),
                    topRight: const Radius.circular(12.0),
                    bottomLeft:
                        isMe ? const Radius.circular(12.0) : Radius.zero,
                    bottomRight:
                        isMe ? Radius.zero : const Radius.circular(12.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (messageContent.isNotEmpty)
                      Text(
                        messageContent,
                        style: const TextStyle(
                            color: Colors.black, fontSize: 16.0),
                      ),
                    if (imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 200.0, // Adjusted width
                        height: 200.0, // Adjusted height
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          width: 30,
                          height: 30,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    if (videoUrl != null)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoPlayerScreen(videoUrl: videoUrl),
                          ),
                        ),
                        child: FutureBuilder<Uint8List?>(
                          future: VideoThumbnail.thumbnailData(
                            video: videoUrl,
                            imageFormat: ImageFormat.JPEG,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 30,
                                height: 30,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Center(
                                child: Icon(Icons.error),
                              );
                            } else {
                              return Container(
                                width: 200.0,
                                height: 250.0,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (snapshot.hasData)
                                      Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      ),
                                    const Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white,
                                      size: 50.0,
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getMatchedPosts() async {
    try {
      final chatDoc =
          await _firestore.collection('Chats').doc(widget.chatId).get();
      final data = chatDoc.data();
      final postIds = data?['postIds'] as List<dynamic>?;
      final postType = data?['status'];
      final bidAmount = data?['bidAmount'];

      if (postIds == null || postIds.isEmpty) {
        return {};
      }

      final myPostId = postIds.length > 0 ? postIds[0] : null;
      final otherPostId = postIds.length > 1 ? postIds[1] : null;

      final myPost = myPostId != null
          ? await _firestore.collection('posts').doc(myPostId).get()
          : null;
      final otherPost = otherPostId != null
          ? await _firestore.collection('posts').doc(otherPostId).get()
          : null;

      return {
        'myPost': myPost?.data(),
        'otherPost': otherPost?.data(),
        'postType': postType,
        'bidAmount': bidAmount,
      };
    } catch (e) {
      print('Error fetching matched posts: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.name),
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _getMatchedPosts(),
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
              final postType = snapshot.data!['postType'];
              final bidAmount = snapshot.data!['bidAmount'];

              if (myPost == null && otherPost == null) {
                return const Center(
                  child: Text('No matched posts found'),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 0), // changes position of shadow
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                margin:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10.0),
                child: postType == 'match'
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (otherPost != null)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: otherPost['Images'][0],
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                    height:
                                        MediaQuery.of(context).size.height / 9,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  otherPost['Name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          const Icon(Icons.swap_horiz, size: 40),
                          if (myPost != null)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: myPost['Images'][0],
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                    height:
                                        MediaQuery.of(context).size.height / 9,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
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
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'จำนวนเงินที่เสนอ $bidAmount บาท',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('Chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container();
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final senderId = message['senderId'];
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('informationUser')
                          .doc(senderId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container();
                        }
                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          return const ListTile(
                            title: Text('User not found'),
                          );
                        }
                        final senderProfileUrl =
                            userSnapshot.data!['profileImageUrl'];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                          child: _buildMessage(message, senderProfileUrl),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: 100,
                    height: 100,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: _cancelUpload,
                  ),
                ],
              ),
            ),
          if (_selectedVideo != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (_videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Transform.rotate(
                        angle: Platform.isAndroid ? 3.14 : 0,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: _cancelUpload,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: _pickVideo,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(labelText: 'ส่งข้อความ...'),
                  ),
                ),
                _isSending
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _sendMessage(_controller.text,
                            imageUrl: _selectedImageUrl,
                            videoUrl: _selectedVideoUrl),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isAndroid = Platform.isAndroid;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.videoUrl)
        ..initialize().then((_) {
          setState(() {
            _controller.play();
            _isPlaying = true;
          });
          _controller.setLooping(false);
          _controller.setPlaybackSpeed(1.0);
          _controller.seekTo(Duration.zero);

          _controller.addListener(() {
            if (_controller.value.position >= _controller.value.duration) {
              setState(() {
                _isPlaying = false;
              });
            }
          });
        });
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        if (_controller.value.position >= _controller.value.duration) {
          _controller.seekTo(Duration.zero);
        }
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _replayVideo() {
    setState(() {
      _controller.seekTo(Duration.zero);
      _controller.play();
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: _controller.value.isInitialized
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Transform.rotate(
                          angle: (_isAndroid &&
                                  _controller.value.size.width >
                                      _controller.value.size.height)
                              ? 3.14
                              : 0,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: SizedBox(
                        height: 13,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.white70,
                            backgroundColor: Colors.black38,
                            bufferedColor: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause
                              : (_controller.value.position >=
                                      _controller.value.duration
                                  ? Icons.replay
                                  : Icons.play_arrow),
                        ),
                        onPressed: () {
                          if (_controller.value.position >=
                              _controller.value.duration) {
                            _replayVideo();
                          } else {
                            _togglePlayPause();
                          }
                        },
                        iconSize: 50.0,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                )
              : const CircularProgressIndicator(
                  color: Colors.white70,
                ),
        ),
      ),
    );
  }
}
