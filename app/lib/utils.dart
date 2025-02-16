import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openSpotify() async {
  const spotifyUri = "spotify://";

  if (await canLaunchUrl(Uri.parse(spotifyUri))) {
    await launchUrl(Uri.parse(spotifyUri));
    return true;
  }
  return false;
}

void showMixafyDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? assetImage,
  String primaryButtonText = "OK",
  VoidCallback? onPrimaryPressed,
  String? secondaryButtonText,
  VoidCallback? onSecondaryPressed,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (assetImage != null)
            Image.asset(assetImage, height: 24),
          if (assetImage != null) const SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (secondaryButtonText != null)
          TextButton(
            onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
            child: Text(secondaryButtonText),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
          child: Text(primaryButtonText),
        ),
      ],
    ),
  );
}

