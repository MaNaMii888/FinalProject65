import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project01/models/post.dart';

class PostProvider with ChangeNotifier {
  static const int _pageSize = 15;

  final List<Post> _lostPosts = [];
  final List<Post> _foundPosts = [];

  bool _isLoadingLost = true;
  bool _isLoadingFound = true;
  bool _isLoadingMoreLost = false;
  bool _isLoadingMoreFound = false;

  bool _hasMoreLost = true;
  bool _hasMoreFound = true;

  DocumentSnapshot? _lastLostDocument;
  DocumentSnapshot? _lastFoundDocument;

  int _totalLostCount = 0;
  int _totalFoundCount = 0;

  String _searchQuery = '';
  String? _selectedCategory;

  // Cache for user names
  final Map<String, String> _userNameCache = {};

  // Getters
  bool get isLoadingLost => _isLoadingLost;
  bool get isLoadingFound => _isLoadingFound;
  bool get isLoadingMoreLost => _isLoadingMoreLost;
  bool get isLoadingMoreFound => _isLoadingMoreFound;
  int get totalLostCount => _totalLostCount;
  int get totalFoundCount => _totalFoundCount;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  List<Post> get lostPosts => _applyLocalFilters(_lostPosts);
  List<Post> get foundPosts => _applyLocalFilters(_foundPosts);

  PostProvider() {
    refreshAll();
  }

  void refreshAll() {
    _updateTotalCounts();
    loadPosts(isLostItems: true, isRefresh: true);
    loadPosts(isLostItems: false, isRefresh: true);
  }

  String normalize(String input) => input.replaceAll(' ', '').toLowerCase();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    _selectedCategory = categoryId;

    // When category changes, we should ideally refresh from firestore to apply the filter
    // at the database level to get a true paginated list.
    loadPosts(isLostItems: true, isRefresh: true);
    loadPosts(isLostItems: false, isRefresh: true);
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    loadPosts(isLostItems: true, isRefresh: true);
    loadPosts(isLostItems: false, isRefresh: true);
  }

  List<Post> _applyLocalFilters(List<Post> sourceList) {
    final normalizedQuery = normalize(_searchQuery);
    return sourceList.where((post) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          normalize(post.title).contains(normalizedQuery) ||
          normalize(post.description).contains(normalizedQuery) ||
          normalize(post.building).contains(normalizedQuery) ||
          normalize(post.location).contains(normalizedQuery);
      return matchesSearch;
    }).toList();
  }

  Future<void> _updateTotalCounts() async {
    try {
      final lostCountQuery =
          await FirebaseFirestore.instance
              .collection('lost_found_items')
              .where('isLostItem', isEqualTo: true)
              .count()
              .get();
      final foundCountQuery =
          await FirebaseFirestore.instance
              .collection('lost_found_items')
              .where('isLostItem', isEqualTo: false)
              .count()
              .get();

      _totalLostCount = lostCountQuery.count ?? 0;
      _totalFoundCount = foundCountQuery.count ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading counts: $e");
    }
  }

  Future<void> loadPosts({
    required bool isLostItems,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      if (isLostItems) {
        _isLoadingLost = true;
        _hasMoreLost = true;
        _lastLostDocument = null;
        _lostPosts.clear();
      } else {
        _isLoadingFound = true;
        _hasMoreFound = true;
        _lastFoundDocument = null;
        _foundPosts.clear();
      }
      notifyListeners();
    } else {
      if (isLostItems && (!_hasMoreLost || _isLoadingMoreLost)) return;
      if (!isLostItems && (!_hasMoreFound || _isLoadingMoreFound)) return;

      if (isLostItems) {
        _isLoadingMoreLost = true;
      } else {
        _isLoadingMoreFound = true;
      }
      notifyListeners();
    }

    try {
      var query = FirebaseFirestore.instance
          .collection('lost_found_items')
          .where('isLostItem', isEqualTo: isLostItems);

      // Apply category filter at the database level if selected
      if (_selectedCategory != null && _selectedCategory != 'all') {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      query = query.orderBy('createdAt', descending: true).limit(_pageSize);

      DocumentSnapshot? currentLastDoc =
          isLostItems ? _lastLostDocument : _lastFoundDocument;

      if (currentLastDoc != null && !isRefresh) {
        query = query.startAfterDocument(currentLastDoc);
      }

      final snapshot = await query.get();

      final List<Post> loadedPosts = [];
      for (var doc in snapshot.docs) {
        try {
          loadedPosts.add(Post.fromJson({...doc.data(), 'id': doc.id}));
        } catch (e) {
          debugPrint("Parse Error ID ${doc.id}: $e");
        }
      }

      if (isLostItems) {
        _lostPosts.addAll(loadedPosts);
        _hasMoreLost = snapshot.docs.length == _pageSize;
        if (snapshot.docs.isNotEmpty) _lastLostDocument = snapshot.docs.last;
        _isLoadingLost = false;
        _isLoadingMoreLost = false;
      } else {
        _foundPosts.addAll(loadedPosts);
        _hasMoreFound = snapshot.docs.length == _pageSize;
        if (snapshot.docs.isNotEmpty) _lastFoundDocument = snapshot.docs.last;
        _isLoadingFound = false;
        _isLoadingMoreFound = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load Error: $e');
      if (isLostItems) {
        _isLoadingLost = false;
        _isLoadingMoreLost = false;
      } else {
        _isLoadingFound = false;
        _isLoadingMoreFound = false;
      }
      notifyListeners();
    }
  }

  Future<String> getUserName(String? userId) async {
    if (userId == null || userId.trim().isEmpty) return 'ไม่ระบุผู้โพสต์';
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId]!;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final data = doc.data();
      final name =
          (data != null &&
                  data['name'] != null &&
                  (data['name'] as String).trim().isNotEmpty)
              ? data['name'] as String
              : 'ไม่ระบุผู้โพสต์';
      _userNameCache[userId] = name;
      return name;
    } catch (e) {
      return 'ไม่ระบุผู้โพสต์';
    }
  }
}
