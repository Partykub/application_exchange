import 'dart:io';

import 'package:image_picker/image_picker.dart';

Future<dynamic> pickImage() async {
  final picker = ImagePicker();
  final pickedImage = await picker.pickImage(source: ImageSource.gallery);
  if (pickedImage != null) {
    return File(pickedImage.path).readAsBytesSync();
  }
}
