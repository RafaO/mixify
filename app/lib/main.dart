import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/auth_view.dart';
import 'package:mixafy/playlist_grid.dart';
import 'package:mixafy/theme.dart';
import 'package:mixafy/token_manager.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      developer.log(
        'general error:',
        name: 'com.keller.mixafy',
        error: error,
      );
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mixafy',
      theme: buildAppTheme(),
      home: MyHomePage(title: "Mixafy"),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final TokenManager _tokenManager = TokenManager();
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final APIService _apiService;

  bool authenticated = false;

  @override
  void initState() {
    super.initState();
    _apiService = APIService(
      onUnauthorised: () {
        // Navigate to the auth screen
        setState(() {
          authenticated = false;
          Navigator.popUntil(context, ModalRoute.withName('/'));
        });
      },
      tokenManager: widget._tokenManager,
    );
    widget._tokenManager.getTokenFromStorage().then((token) {
      if (token != null && token.isNotEmpty) {
        setState(() {
          authenticated = true;
        });
      }
    });
  }

  Future<void> authenticateWithSpotify() async {
    String clientId = dotenv.env['spotify_client_id'] ?? '';
    if (clientId.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        Exception("clientID is empty"),
        null,
      );
      return;
    }
    const redirectUri = 'mixafy://callback';
    const scope =
        "playlist-read-private, user-modify-playback-state, user-read-playback-state, user-read-currently-playing, user-library-read";

    try {
      // Check if Spotify is installed
      bool isInstalled = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUri,
      ).then((_) => true).catchError((_) => false);

      if (isInstalled) {
        // If installed, use Spotify SDK authentication
        var accessToken = await SpotifySdk.getAccessToken(
          clientId: clientId,
          redirectUrl: redirectUri,
          scope: scope,
        );
        widget._tokenManager.tokenReceived(accessToken);
        setState(() {
          authenticated = true;
        });
      } else {
        if (mounted) _showSpotifyNotInstalledDialog(context);
      }
    } on Exception catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s);
    }
  }

  void _showSpotifyNotInstalledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset(
              'assets/Spotify_Icon_CMYK_Black.png',
              height: 24,
            ),
            // Ensure this image exists
            const SizedBox(width: 10),
            const Text("Spotify app not found"),
          ],
        ),
        content: const Text(
          "Mixafy requires the Spotify app to function properly. "
          "Please install it and try again!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Spotify theme color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _openSpotifyStore();
            },
            child: const Text("Get Spotify"),
          ),
        ],
      ),
    );
  }

  Future<void> _openSpotifyStore() async {
    const url = 'https://www.spotify.com/download/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      FirebaseCrashlytics.instance.recordError(
        Exception("Failed to open Spotify store link"),
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return authenticated
        ? PlaylistGrid(apiService: _apiService)
        : AuthView(onButtonPressed: authenticateWithSpotify);
  }
}
