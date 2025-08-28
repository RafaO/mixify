import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/auth_view.dart';
import 'package:mixafy/items_grid.dart';
import 'package:mixafy/songs_mixer.dart';
import 'package:mixafy/spotify_auth.dart';
import 'package:mixafy/theme.dart';
import 'package:mixafy/token_manager.dart';
import 'package:mixafy/utils.dart';
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

    final AppLinks appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri uri) async {
      debugPrint("Received deep link: $uri");
      if (uri.host == "callback") {
        final code = uri.queryParameters['code'];
        if (code != null) {
          debugPrint("code: $code");
          final response = await fetchSpotifyToken(code);
          final token = response['access_token'] as String;
          debugPrint('token from web auth: $token');
          widget._tokenManager.tokenReceived(token);
          setState(() {
            authenticated = true;
          });
        }
      }
    });

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
    // check spotify app is installed
    final spotifyUri = Uri.parse('spotify://');
    if (!await canLaunchUrl(spotifyUri)) {
      authenticateWithSpotifyWeb();
    } else {
      authenticateWithSpotifyApp(
        (token) {
          widget._tokenManager.tokenReceived(token);
          setState(() {
            authenticated = true;
          });
        },
        (e, s) {
          if (mounted) _showSpotifyNotInstalledDialog(context);
          FirebaseCrashlytics.instance.recordError(e, s);
        },
      );
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
