import 'package:flutter/material.dart';
import 'package:mixafy/entities/mix.dart';

class MixListScreen extends StatelessWidget {
  final List<Mix> mixes;
  final Function(Mix) onMixSelected;

  const MixListScreen({Key? key, required this.mixes, required this.onMixSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Mixes'),
      ),
      body: mixes.isEmpty
          ? const Center(child: Text('No saved mixes yet!'))
          : ListView.builder(
        itemCount: mixes.length,
        itemBuilder: (context, index) {
          final mix = mixes[index];
          return ListTile(
            title: Text(mix.mixName),
            subtitle: Text('Songs added in the last: ${mix.timeRange}'),
            onTap: () {
              onMixSelected(mix);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
