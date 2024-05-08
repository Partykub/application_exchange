import 'package:flutter/material.dart';

Widget displayImage(String imageUrl) {
  return Image.network(
    imageUrl,
    fit: BoxFit.cover,
    loadingBuilder:
        (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
      if (loadingProgress == null) return child;
      return Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      );
    },
    errorBuilder:
        (BuildContext context, Object exception, StackTrace? stackTrace) {
      return const Text('Failed to load image');
    },
  );
}
