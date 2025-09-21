// spotify_auth_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class SpotifyAuthWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String redirectUriScheme;
  final String expectedRedirectUriHost;

  const SpotifyAuthWebViewScreen({
    super.key,
    required this.initialUrl,
    required this.redirectUriScheme,
    required this.expectedRedirectUriHost,
  });

  @override
  State<SpotifyAuthWebViewScreen> createState() =>
      _SpotifyAuthWebViewScreenState();
}

class _SpotifyAuthWebViewScreenState extends State<SpotifyAuthWebViewScreen> {
  double _progress = 0;
  bool _isLoading = true;
  String? _errorLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spotify Login"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // User manually closed the webview
            Navigator.of(context).pop(null);
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              clearCache: true,
              useShouldOverrideUrlLoading: true,
              useOnLoadResource: true,
              cacheMode: CacheMode.LOAD_NO_CACHE,
            ),
            onWebViewCreated: (controller) {},
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
                _errorLoading = null;
              });
              if (url != null) {
                _checkUrlForCode(url.toString(), context);
              }
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
              if (url != null) {
                _checkUrlForCode(url.toString(), context);
              }
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
            onReceivedError: (controller, request, error) {
              setState(() {
                _isLoading = false;
                // _errorLoading = "Error: ${error.description}";
              });
              FirebaseCrashlytics.instance.recordError(
                  Exception(
                      "InAppWebView onReceivedError: ${error.description} for URL: ${request.url}"),
                  StackTrace.current);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri != null) {
                if (_checkUrlForCode(uri.toString(), context)) {
                  // If code found and handled, prevent further loading of this URL
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorLoading != null)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error: $_errorLoading",
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )),
          if (_progress < 1.0 && _isLoading)
            LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }

  bool _checkUrlForCode(String urlString, BuildContext currentContext) {
    try {
      final Uri uri = Uri.parse(urlString);
      // Check if the URL scheme and host match your redirect URI
      if (uri.scheme == widget.redirectUriScheme &&
          uri.host == widget.expectedRedirectUriHost) {
        final String? code = uri.queryParameters['code'];
        final String? error = uri.queryParameters['error'];

        if (error != null) {
          // Spotify returned an error
          if (mounted) Navigator.of(currentContext).pop({'error': error});
          return true;
        }

        if (code != null && code.isNotEmpty) {
          if (mounted) Navigator.of(currentContext).pop({'code': code});
          return true;
        }
      }
    } catch (e, s) {
      // Error parsing URL or other unexpected issue
      FirebaseCrashlytics.instance.recordError(
          Exception("Error in _checkUrlForCode: $e while parsing $urlString"),
          s);
    }
    return false; // URL not handled for auth code
  }
}
