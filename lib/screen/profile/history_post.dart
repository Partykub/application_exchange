import 'package:flutter/material.dart';

class HistoryPost extends StatefulWidget {
  const HistoryPost({super.key});

  @override
  State<HistoryPost> createState() => _HistoryPostState();
}

class _HistoryPostState extends State<HistoryPost> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Text('ประวัติการแลกเปลี่ยน')],
    );
  }
}
