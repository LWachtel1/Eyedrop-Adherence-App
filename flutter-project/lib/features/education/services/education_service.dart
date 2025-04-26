import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyedrop/features/education/models/education_resource.dart';

class EducationService {
  static const String _favoritesKey = 'education_favourites';
  static const String _recentKey = 'education_recent';
  static const String _readKey = 'education_read';

  final List<EducationResource> _resources = [
    EducationResource(
      id: '1',
      title: 'All Eye Conditions',
      url: 'https://www.moorfields.nhs.uk/eye-conditions',
      description: 'Comprehensive guide to various eye conditions',
      type: ResourceType.website,
      category: ResourceCategory.general,
      icon: EducationResource.getIconForType(ResourceType.website),
      color: EducationResource.getColorForCategory(ResourceCategory.general),
    ),
    EducationResource(
      id: '2',
      title: 'Eyedrop instillation technique',
      url: 'https://www.ouh.nhs.uk/patient-guide/leaflets/files/73435instil.pdf',
      description: 'Step-by-step guide to proper eyedrop administration',
      type: ResourceType.text,
      category: ResourceCategory.techniques,
      icon: EducationResource.getIconForType(ResourceType.text),
      color: EducationResource.getColorForCategory(ResourceCategory.techniques),
    ),
    EducationResource(
      id: '3',
      title: 'Glaucoma (text content)',
      url: 'https://www.moorfields.nhs.uk/eye-conditions/glaucoma',
      description: 'Detailed information about glaucoma',
      type: ResourceType.text,
      category: ResourceCategory.conditions,
      icon: EducationResource.getIconForType(ResourceType.text),
      color: EducationResource.getColorForCategory(ResourceCategory.conditions),
    ),
    EducationResource(
      id: '4',
      title: 'Glaucoma (video content)',
      url: 'https://www.youtube.com/@willseyeglaucomaapp5431/featured',
      description: 'Video content about glaucoma management',
      type: ResourceType.video,
      category: ResourceCategory.conditions,
      icon: EducationResource.getIconForType(ResourceType.video),
      color: EducationResource.getColorForCategory(ResourceCategory.conditions),
    ),
    EducationResource(
      id: '5',
      title: 'Dry Eye',
      url: 'https://www.uhsussex.nhs.uk/resources/dry-eyes/',
      description: 'Information about dry eye condition and treatments',
      type: ResourceType.text,
      category: ResourceCategory.conditions,
      icon: EducationResource.getIconForType(ResourceType.text),
      color: EducationResource.getColorForCategory(ResourceCategory.conditions),
    ),
    EducationResource(
      id: '6',
      title: 'Microbial Keratitis',
      url: 'https://www.moorfields.nhs.uk/eye-conditions/microbial-keratitis',
      description: 'Information about microbial keratitis',
      type: ResourceType.text,
      category: ResourceCategory.conditions,
      icon: EducationResource.getIconForType(ResourceType.text),
      color: EducationResource.getColorForCategory(ResourceCategory.conditions),
    ),
    EducationResource(
      id: '7',
      title: 'Acanthamoeba keratitis',
      url: 'https://www.moorfields.nhs.uk/eye-conditions/acanthamoeba-keratitis',
      description: 'Information about acanthamoeba keratitis',
      type: ResourceType.text,
      category: ResourceCategory.conditions,
      icon: EducationResource.getIconForType(ResourceType.text),
      color: EducationResource.getColorForCategory(ResourceCategory.conditions),
    ),
    EducationResource(
      id: '8',
      title: 'Herpes Simplex Virus Keratitis',
      url: 'https://www.moorfields.nhs.uk/for-patients/information-hub/herpes-simplex-virus-keratitis',
      description: 'Information about herpes simplex virus keratitis',
      type: ResourceType.text,
      category: ResourceCategory.conditions,
      icon: EducationResource.getIconForType(ResourceType.text),
      color: EducationResource.getColorForCategory(ResourceCategory.conditions),
    ),
  ];

  Future<void> toggleFavorite(String resourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    
    if (favorites.contains(resourceId)) {
      favorites.remove(resourceId);
    } else {
      favorites.add(resourceId);
    }
    
    await prefs.setStringList(_favoritesKey, favorites);
  }

  Future<void> markAsRead(String resourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readKey) ?? [];
    
    if (!read.contains(resourceId)) {
      read.add(resourceId);
      await prefs.setStringList(_readKey, read);
    }
  }

  Future<void> updateLastAccessed(String resourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_recentKey) ?? [];
    
    recent.remove(resourceId);
    recent.insert(0, resourceId);
    
    // Keep only the 10 most recent items
    if (recent.length > 10) {
      recent.removeLast();
    }
    
    await prefs.setStringList(_recentKey, recent);
  }

  Future<List<EducationResource>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    return _resources.where((r) => favorites.contains(r.id)).toList();
  }

  Future<List<EducationResource>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_recentKey) ?? [];
    return recent
        .map((id) => _resources.firstWhere((r) => r.id == id))
        .toList();
  }

  List<EducationResource> getResourcesByCategory(ResourceCategory category) {
    return _resources.where((r) => r.category == category).toList();
  }

  List<EducationResource> searchResources(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _resources.where((r) =>
        r.title.toLowerCase().contains(lowercaseQuery) ||
        (r.description?.toLowerCase().contains(lowercaseQuery) ?? false)).toList();
  }

  Future<bool> isFavorite(String resourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites.contains(resourceId);
  }

  Future<bool> isRead(String resourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readKey) ?? [];
    return read.contains(resourceId);
  }
} 