import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mixify/auth_view.dart';
import 'package:mixify/playlist_grid.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Mixify',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: "Mixify"));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String spotifyToken = '';
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    getTokenFromStorage().then((token) {
      setState(() {
        spotifyToken = token ?? '';
      });
    });
  }

  Future<String?> getTokenFromStorage() async {
    return await storage.read(key: 'spotifyToken');
  }

  Future<void> saveTokenToStorage(String token) async {
    await storage.write(key: 'spotifyToken', value: token);
  }

  bool isTokenValid() {
    // Implement your logic to check the token's validity here
    // For demonstration purposes, let's assume the token is valid if it's not empty
    return spotifyToken.isNotEmpty;
  }

  Future<void> authenticateWithSpotify() async {
    String clientId = dotenv.env['spotify_client_id'] ?? '';
    if (clientId.isEmpty) {
      // handle error
      return;
    }
    const redirectUri = 'mixify://callback';
    const scope =
        "playlist-read-private, user-modify-playback-state, user-read-playback-state, user-read-currently-playing";

    var accessToken = await SpotifySdk.getAccessToken(
      clientId: clientId,
      redirectUrl: redirectUri,
      scope: scope,
    );
    saveTokenToStorage(accessToken);
    setState(() {
      spotifyToken = accessToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: isTokenValid()
          ? PlaylistGrid(accessToken: spotifyToken)
          : AuthView(onButtonPressed: authenticateWithSpotify),
    );
  }
}
