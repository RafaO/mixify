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
import 'package:mixafy/spotify_auth_web_view_screen.dart';
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
  bool _isAuthFlowActive = false;

  @override
  void initState() {
    super.initState();

    final AppLinks appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri uri) async {
      debugPrint("Received deep link: $uri");
      if (uri.host == "callback") {
        final code = uri.queryParameters['code'];
        if (code != null) {
          _handleCode(code);
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
    if (state == AppLifecycleState.resumed && !_isAuthFlowActive) {
      _checkAuth();
    }
  }

  void _handleCode(String code) async {
    debugPrint("code: $code");
    final response = await fetchSpotifyToken(code);
    final token = response['access_token'] as String;
    debugPrint('token from web auth: $token');
    widget._tokenManager.tokenReceived(token);
    setState(() {
      authenticated = true;
    });
  }

  Future<void> _checkAuth() async {
    if (_isAuthFlowActive) return;

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
      final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': scopes,
        'show_dialog': 'true',
      });

      if (!mounted) return;
      setState(() {
        _isAuthFlowActive = true;
      });

      Map<String, String?>? result;
      try {
        result = await Navigator.of(context).push<Map<String, String?>>(
          MaterialPageRoute(
            builder: (context) => SpotifyAuthWebViewScreen(
              initialUrl: authUrl.toString(),
              redirectUriScheme: 'mixafy',
              expectedRedirectUriHost: 'callback',
            ),
            fullscreenDialog: true,
          ),
        );

        // Handle the result
        if (result != null) {
          if (result.containsKey('error')) {
            final error = result['error'];
            debugPrint("Spotify Auth Error from WebView: $error");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Spotify Login Failed: $error")));
            }
          } else if (result.containsKey('code')) {
            final code = result['code'];
            if (code != null && code.isNotEmpty) {
              _handleCode(code);
            } else {
              // TODO log error in firebase
              debugPrint("Received null or empty code from WebView");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Spotify Login Failed: Invalid code received.")));
              }
            }
          }
        } else {
          // User cancelled the WebView
          debugPrint("Spotify Auth WebView was cancelled by user.");
        }
      } catch (e, s) {
        debugPrint(
            "Error during Spotify WebView navigation or handling: $e\n$s");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("An error occurred during login.")));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAuthFlowActive = false;
          });
          // If auth wasn't successful after the flow, re-check.
          // This allows _checkAuth to potentially pop to root if needed.
          if (!authenticated) {
            _checkAuth();
          }
        }
      }
    } else {
      // ----- SPOTIFY SDK AUTH LOGIC -----
      if (!mounted) return;
      setState(() {
        _isAuthFlowActive = true;
      });
      authenticateWithSpotifyApp(
        (token) {
          // onTokenReceived
          widget._tokenManager.tokenReceived(token);
          if (mounted) {
            setState(() {
              authenticated = true;
              _isAuthFlowActive = false;
            });
          }
        },
        (e, s) {
          // onException
          if (mounted) {
            _showSpotifyNotInstalledDialog(context);
            FirebaseCrashlytics.instance.recordError(e, s);
            setState(() {
              _isAuthFlowActive = false;
            });
            _checkAuth();
          }
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
