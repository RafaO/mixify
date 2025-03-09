import 'package:flutter/material.dart';
import 'package:mixafy/entities/selectable_item.dart';

class ItemCard extends StatefulWidget {
  final SelectableItem item;
  final Function(dynamic) onRemove;

  const ItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  ItemCardState createState() => ItemCardState();
}

class ItemCardState extends State<ItemCard> {
  bool featureFlagPercentage = false;
  double percentage = 50.0; // Default percentage

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Stack(
        children: [
          if (widget.item.imageUrl != null)
            Image.network(
              widget.item.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.topRight,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: () => widget.onRemove(widget.item),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          featureFlagPercentage
              ? Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      _showSettingsDialog(context);
                    },
                  ),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        double tempPercentage =
            percentage; // Temporary variable to hold the slider value

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Set Percentage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempPercentage,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${tempPercentage.round()}%',
                    onChanged: (value) {
                      setState(() {
                        tempPercentage = value;
                      });
                    },
                  ),
                  Text('${tempPercentage.round()}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      percentage =
                          tempPercentage; // Update the main state with the new value
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
