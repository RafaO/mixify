import 'package:url_launcher/url_launcher.dart';

Future<bool> openSpotify() async {
  const spotifyUri = "spotify://";

  if (await canLaunchUrl(Uri.parse(spotifyUri))) {
    await launchUrl(Uri.parse(spotifyUri));
    return true;
  }
  return false;
}
