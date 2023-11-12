import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class CategoryInfo {
  int? id;
  String name;

  CategoryInfo({
    this.id,
    required this.name,
  });

  CategoryInfo.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int?,
        name = map['name'] as String;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class LocationInfo {
  int? id;
  String name;
  String locationString;
  double latitude;
  double longitude;
  DateTime createdAt;
  int? categoryId;

  LocationInfo({
    this.id,
    required this.name,
    required this.locationString,
    required this.latitude,
    required this.longitude,
    DateTime? createdAt,
    this.categoryId,
  }) : createdAt = createdAt ?? DateTime.now();

  LocationInfo.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int?,
        name = map['name'] as String,
        locationString = map['locationString'] as String,
        latitude = map['latitude'] as double,
        longitude = map['longitude'] as double,
        createdAt = DateTime.parse(map['createdAt'] as String),
        categoryId = map['categoryId'] as int?;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'locationString': locationString,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'categoryId': categoryId,
    };
  }
}

class DatabaseHelper {
  Future<Database> _openDatabase() async {
    Directory appDirectory = await getApplicationDocumentsDirectory();
    String dbPath = join(appDirectory.path, 'location_database.db');
    DatabaseFactory dbFactory = databaseFactoryIo;
    return await dbFactory.openDatabase(dbPath);
  }

  // Category CRUD operations

  Future<void> saveCategory(CategoryInfo categoryInfo) async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('categories');

    if (categoryInfo.id == null) {
      var finder = Finder(sortOrders: [SortOrder(Field.key, false)], limit: 1);
      var lastRecord = await store.find(db, finder: finder);
      int newId = 1;
      if (lastRecord.isNotEmpty) {
        newId = (lastRecord.first.key as int) + 1;
      }
      categoryInfo.id = newId;
    }

    await store.record(categoryInfo.id!).put(db, categoryInfo.toMap());
  }




  Future<List<CategoryInfo>> loadCategories() async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('categories');
    var snapshots = await store.find(db);
    return snapshots.map((snapshot) => CategoryInfo.fromMap(snapshot.value)).toList();
  }

  Future<void> deleteCategory(int id) async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('categories');

    var locationsWithCategory = await store.find(db, finder: Finder(filter: Filter.equals('categoryId', id)));
    if (locationsWithCategory.isNotEmpty) {
      // If locations have this category, set their categoryId to null
      for (var record in locationsWithCategory) {
        var location = LocationInfo.fromMap(record.value);
        location.categoryId = null;
        await store.record(location.id!).put(db, location.toMap());
      }
    }

    await store.record(id).delete(db);
  }

  // Location CRUD operations

  Future<void> updateLocation(LocationInfo locationInfo) async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('locations');
    await store.record(locationInfo.id!).update(db, locationInfo.toMap());
  }


  Future<void> saveLocation(LocationInfo locationInfo) async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('locations');

    if (locationInfo.id == null) {
      var finder = Finder(sortOrders: [SortOrder(Field.key, false)], limit: 1);
      var lastRecord = await store.find(db, finder: finder);
      int newId = 1;
      if (lastRecord.isNotEmpty) {
        newId = (lastRecord.first.key as int) + 1;
      }
      locationInfo.id = newId;
    }

    await store.record(locationInfo.id!).put(db, locationInfo.toMap());
  }

  Future<List<LocationInfo>> loadSavedLocations() async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('locations');
    var snapshots = await store.find(db);
    return snapshots.map((snapshot) => LocationInfo.fromMap(snapshot.value)).toList();
  }

  Future<void> deleteLocation(int id) async {
    if (id == 0) {
      return;
    }

    final db = await _openDatabase();
    var store = intMapStoreFactory.store('locations');

    await store.record(id).delete(db);
  }

  // Remove category from all locations
  Future<void> updateCategory(CategoryInfo categoryInfo) async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('categories');
    await store.record(categoryInfo.id!).update(db, categoryInfo.toMap());
  }

  Future<int> getLocationCountForCategory(int categoryId) async {
    final db = await _openDatabase();
    final store = intMapStoreFactory.store('locations');
    final finder = Finder(
      filter: Filter.equals('categoryId', categoryId),
    );
    final recordSnapshots = await store.find(db, finder: finder);
    return recordSnapshots.length;
  }

  Future<void> removeAllCategoriesFromLocations() async {
    final db = await _openDatabase();
    var store = intMapStoreFactory.store('locations');

    var finder = Finder(filter: Filter.notNull('categoryId'));
    var records = await store.find(db, finder: finder);

    for (var record in records) {
      var location = LocationInfo.fromMap(record.value);
      location.categoryId = null;
      await store.record(location.id!).put(db, location.toMap());
    }
  }
}