import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// A reusable widget for displaying a searchable list of items.
class SearchableList<T> extends StatefulWidget {
  final List<T> items; // List of any type of items
  final String Function(T) getSearchString; // Function to extract search string from item
  final Widget Function(T, int) itemBuilder; // Function to build widget for each item
  final Function(T) onSelect; // Callback when item is selected
  final String hintText; // Text to be displayed in search bar as a hint

  const SearchableList({
    required this.items,
    required this.getSearchString,
    required this.itemBuilder,
    required this.onSelect,
    this.hintText = "Search...",
    super.key,
  });

  @override
  _SearchableListState<T> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<SearchableList<T>> {
  late List<T> _filteredItems; // Filtered items based on search query
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }
  
  @override
  void didUpdateWidget(SearchableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filterItems();
    }
  }

  /// Filters the list of items based on user input.
  void _filterItems() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) => widget.getSearchString(item)
              .toLowerCase()
              .contains(query))
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
        // Search bar
        Padding(
          padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 0.h, bottom: 2.h),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: widget.hintText,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.w)),
            ),
          ),
        ),

        // List of items
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(child: Text("No items found"))
              : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => widget.onSelect(_filteredItems[index]),
                      child: widget.itemBuilder(_filteredItems[index], index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
