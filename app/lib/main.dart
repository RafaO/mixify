import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mixify/api_service.dart';
import 'package:mixify/auth_view.dart';
import 'package:mixify/playlist_grid.dart';
import 'package:mixify/theme.dart';
import 'package:mixify/token_manager.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

import 'firebase_options.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mixify',
      theme: buildAppTheme(),
      home: MyHomePage(title: "Mixify"),
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
        tokenManager: widget._tokenManager);
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
      // handle error
      FirebaseCrashlytics.instance.log("clientID is empty");
      return;
    }
    const redirectUri = 'mixify://callback';
    const scope =
        "playlist-read-private, user-modify-playback-state, user-read-playback-state, user-read-currently-playing";

    try {
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
      FirebaseCrashlytics.instance.recordError(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return authenticated
        ? PlaylistGrid(apiService: _apiService)
        : AuthView(onButtonPressed: authenticateWithSpotify);
  }
}
