import 'package:flutter/material.dart';
import 'package:mixafy/api_service.dart';
import 'package:mixafy/entities/artist.dart';
import 'package:mixafy/entities/spotify_playlist.dart';

abstract class SelectableItem {
  String get name;

  String? get imageUrl;

  String get id;

  String? get description;
}

class ItemsSelector extends StatefulWidget {
  final APIService apiService;
  final Function(List<SelectableItem>) onSelectionChanged;
  final List<SelectableItem> alreadySelectedItems;

  const ItemsSelector({
    Key? key,
    required this.apiService,
    required this.onSelectionChanged,
    required this.alreadySelectedItems,
  }) : super(key: key);

  @override
  State<ItemsSelector> createState() => _ItemsSelectorState();
}

class _ItemsSelectorState extends State<ItemsSelector> {
  late List<SelectableItem> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.alreadySelectedItems);
  }

  void _toggleSelection(SelectableItem item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
    widget.onSelectionChanged(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add things to your mix'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, selectedItems);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Artists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SelectableList<SpotifyPlaylist>(
              fetchItems: widget.apiService.fetchPlaylists,
              selectedItems: selectedItems,
              onToggleSelection: _toggleSelection,
            ),
            SelectableList<Artist>(
              fetchItems: widget.apiService.getUserSavedArtists,
              selectedItems: selectedItems,
              onToggleSelection: _toggleSelection,
            ),
          ],
        ),
      ),
    );
  }
}

class SelectableList<T extends SelectableItem> extends StatefulWidget {
  final Future<List<T>> Function() fetchItems;
  final List<SelectableItem> selectedItems;
  final Function(SelectableItem) onToggleSelection;

  const SelectableList({
    Key? key,
    required this.fetchItems,
    required this.selectedItems,
    required this.onToggleSelection,
  }) : super(key: key);

  @override
  State<SelectableList<T>> createState() => _SelectableListState<T>();
}

class _SelectableListState<T extends SelectableItem>
    extends State<SelectableList<T>> {
  late List<T> items;
  late List<T> filteredItems;
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    items = [];
    filteredItems = [];
    _fetchItems();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    final fetchedItems = await widget.fetchItems();
    setState(() {
      items = fetchedItems;
      filteredItems = fetchedItems;
      isLoading = false;
    });
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = items
          .where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            onChanged: _filterItems,
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () {
                        searchController.clear();
                        _filterItems(''); // Reset the search
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = widget.selectedItems.contains(item);
                    return ListTile(
                      leading: item.imageUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(item.imageUrl!),
                            )
                          : const Icon(Icons.music_note),
                      title: Text(item.name),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined),
                      onTap: () => widget.onToggleSelection(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
