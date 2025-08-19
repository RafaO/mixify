import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/auth_view.dart';
import 'package:mixafy/items_grid.dart';
import 'package:mixafy/songs_mixer.dart';
import 'package:mixafy/theme.dart';
import 'package:mixafy/token_manager.dart';
import 'package:mixafy/utils.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kReleaseMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  } else {
    // In debug/dev, print errors to console
    FlutterError.onError = FlutterError.dumpErrorToConsole;
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Error: $error\n$stack');
      return true;
    };
  }
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
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
      songsMixer: SongsMixer(),
    );
    widget._tokenManager.isTokenValid().then((valid) {
      if (valid) {
        setState(() {
          authenticated = true;
        });
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    bool valid = await widget._tokenManager.isTokenValid();

    if (mounted && !valid) {
      setState(() {
        authenticated = false;
        Navigator.popUntil(context, ModalRoute.withName('/'));
      });
    }
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
    const String scope = "playlist-read-private,"
        "user-modify-playback-state,"
        "user-read-playback-state,"
        "user-read-currently-playing,"
        "user-follow-read,"
        "user-library-read,"
        // "app-remote-control," // this doesn't work on Android at least
    ;
    try {
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
    } on Exception catch (e, s) {
      if (mounted) _showSpotifyNotInstalledDialog(context);
      FirebaseCrashlytics.instance.recordError(e, s);
    }
  }

  void _showSpotifyNotInstalledDialog(BuildContext context) {
    showMixafyDialog(
      context: context,
      title: "Couldn't authenticate",
      message: "We couldn't authenticate you in Spotify. "
          "Please check that you have the Spotify app installed, configured, and try again!",
      assetImage: 'assets/Spotify_Icon_CMYK_Black.png',
      primaryButtonText: "Get Spotify",
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        _openSpotifyStore();
      },
      secondaryButtonText: "Close",
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
        ? ItemsGrid(apiService: _apiService)
        : AuthView(onButtonPressed: authenticateWithSpotify);
  }
}
