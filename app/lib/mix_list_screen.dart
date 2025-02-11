import 'package:flutter/material.dart';
import 'package:mixafy/entities/mix.dart';

class MixListScreen extends StatelessWidget {
  final List<Mix> mixes;

  const MixListScreen({Key? key, required this.mixes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Mixes"),
      ),
      body: mixes.isEmpty
          ? const Center(child: Text("No mixes saved yet!"))
          : ListView.builder(
        itemCount: mixes.length,
        itemBuilder: (context, index) {
          final mix = mixes[index];
          return ListTile(
            title: Text(mix.mixName),
            subtitle: Text('Songs added in the last: ${mix.timeRange}'),
            onTap: () {
              // You can add logic here to view the mix details or play it
            },
          );
        },
      ),
    );
  }
}
