import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// A reusable widget for displaying a searchable list of items.
class SearchableList extends StatefulWidget {
  final List<String> items; // Items to be displayed in list.
  final Function(String) onSelect; 
  final String hintText; //Text to be displayed in search bar as a hint.

  const SearchableList({
    required this.items,
    required this.onSelect,
    this.hintText = "Search...",
    super.key,
  });

  @override
  _SearchableListState createState() => _SearchableListState();
}

class _SearchableListState extends State<SearchableList> {
  late List<String> _filteredItems; // Filtered items based on search query.
  final TextEditingController _searchController = TextEditingController();
  // Manages search bar text.

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  /// Filters the list of medications based on user input.
  ///
  /// - Converts search query and items  to lowercase to ensure case-insensitive search.
  /// - Updates `_filteredItems` list dynamically.
  void _filterItems() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query))
            // Any item that contains the search query as a substring will be included in the filtered results.
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Search bar.
        Padding(
          padding: EdgeInsets.all(5.w),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: widget.hintText,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
            ),
          ),
        ),

        // List of items.
        Expanded(
          child: ListView.builder(
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_filteredItems[index], style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => widget.onSelect(_filteredItems[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
