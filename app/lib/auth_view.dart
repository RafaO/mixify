import 'package:flutter/material.dart';

class AuthView extends StatelessWidget {
  final Future<void> Function() onButtonPressed;

  const AuthView({super.key, required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.jpeg'),
          fit: BoxFit.fitHeight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/Spotify_Icon_CMYK_Black.png',
              width: 100.0,
              height: 100.0,
            ),
            const SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                onPressed: () => onButtonPressed(),
                child: const Text('Authenticate with Spotify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
