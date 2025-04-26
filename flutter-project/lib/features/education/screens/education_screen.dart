import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eyedrop/features/education/models/education_resource.dart';
import 'package:eyedrop/features/education/services/education_service.dart';
import 'package:provider/provider.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';

class EducationScreen extends StatefulWidget {
  static const String id = 'education_screen';

  @override
  _EducationScreenState createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final EducationService _educationService = EducationService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ResourceCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = null;
              });
            },
          ),
          const SizedBox(width: 8.0),
          ...ResourceCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(category.toString().split('.').last),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResourceCard(EducationResource resource) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () async {
          await _launchUrl(resource.url);
          await _educationService.updateLastAccessed(resource.id);
          await _educationService.markAsRead(resource.id);
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(resource.icon, color: resource.color),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      resource.title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FutureBuilder<bool>(
                    future: _educationService.isFavorite(resource.id),
                    builder: (context, snapshot) {
                      return IconButton(
                        icon: Icon(
                          snapshot.data == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: snapshot.data == true ? Colors.red : null,
                        ),
                        onPressed: () async {
                          await _educationService.toggleFavorite(resource.id);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ],
              ),
              if (resource.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    resource.description!,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: resource.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      resource.category.toString().split('.').last,
                      style: TextStyle(
                        color: resource.color,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FutureBuilder<bool>(
                    future: _educationService.isRead(resource.id),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return const Text(
                          'Read',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12.0,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<EducationResource> _filterResources(List<EducationResource> resources) {
    return resources.where((resource) {
      final matchesSearch = _searchQuery.isEmpty ||
          resource.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (resource.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _selectedCategory == null || resource.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Favourites'),
                Tab(text: 'Recent'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search resources...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            _buildCategoryChips(),
            const SizedBox(height: 8.0),
            Expanded(
              child: TabBarView(
                children: [
                  // All Resources Tab
                  _buildResourcesList(
                    _filterResources(_educationService.searchResources('')),
                  ),
                  // Favourites Tab
                  FutureBuilder<List<EducationResource>>(
                    future: _educationService.getFavorites(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      return _buildResourcesList(
                        _filterResources(snapshot.data ?? []),
                      );
                    },
                  ),
                  // Recent Tab
                  FutureBuilder<List<EducationResource>>(
                    future: _educationService.getRecent(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      return _buildResourcesList(
                        _filterResources(snapshot.data ?? []),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesList(List<EducationResource> resources) {
    if (resources.isEmpty) {
      return const Center(
        child: Text('No resources found'),
      );
    }

    return ListView.builder(
      itemCount: resources.length,
      itemBuilder: (context, index) {
        return _buildResourceCard(resources[index]);
      },
    );
  }
}
