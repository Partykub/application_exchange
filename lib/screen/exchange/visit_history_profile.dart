import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VisitHistoryPost extends StatefulWidget {
  const VisitHistoryPost({super.key});

  @override
  State<VisitHistoryPost> createState() => _HistoryPostState();
}

class _HistoryPostState extends State<VisitHistoryPost> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.grey[200],
        child: Center(
          child: CachedNetworkImage(
            imageUrl:
                'https://aithailand.co.th/uploads/texteditor/Doraemon-th_1630640671.jpg',
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}
