import 'package:flutter/material.dart';
import '../database/database_helper_1.dart';
import '../method/methods.dart';
import '../widget/category_list_widget.dart';

class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<LocationInfo> _locationList = [];
  List<CategoryInfo> _categoryList = [];
  int? _selectedCategoryId;
  TextEditingController _locationNameController = TextEditingController();
  bool _showDeleteIcons = false;
  bool _isSelecting = false;
  List<LocationInfo> _selectedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
    _loadCategories();
  }

  void _showAddCategoryBottomSheet(BuildContext context) {
    Methods.showAddCategoryBottomSheet(context, _onAddCategory);
  }

  void _onAddCategory(CategoryInfo categoryInfo) {
    setState(() {
      categoryInfo.id = DateTime.now().millisecondsSinceEpoch;
      _categoryList.add(categoryInfo);
    });
  }

  Future<void> _loadSavedLocations() async {
    List<LocationInfo> savedLocations = await DatabaseHelper().loadSavedLocations();
    setState(() {
      _locationList = savedLocations;
    });
  }

  Future<void> _loadCategories() async {
    List<CategoryInfo> categories = await DatabaseHelper().loadCategories();
    setState(() {
      _categoryList = categories;
    });
  }

  void _startSelecting() {
    setState(() {
      _isSelecting = true;
      _selectedLocations = [];
    });
  }

  void _stopSelecting() {
    setState(() {
      _isSelecting = false;
      _selectedLocations = [];
    });
  }

  void _toggleSelecting(LocationInfo locationInfo) {
    setState(() {
      if (_selectedLocations.contains(locationInfo)) {
        _selectedLocations.remove(locationInfo);
      } else {
        _selectedLocations.add(locationInfo);
      }
    });
  }

  void _moveSelectedLocations(int? newCategoryId) async {
    int selectedCount = _selectedLocations.length;

    if (newCategoryId == -1) {
      _showAddCategoryBottomSheet(context);
      return;
    }
    for (var location in _selectedLocations) {
      location.categoryId = newCategoryId;
      await DatabaseHelper().updateLocation(location);
    }
    _loadSavedLocations();
    _stopSelecting();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$selectedCount konum taşındı'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kayıtlı Konumlar'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (!_isSelecting)
            IconButton(
              onPressed: () => _showAddCategoryBottomSheet(context),
              icon: Icon(Icons.add),
            ),
          if (_isSelecting)
            IconButton(
              onPressed: _stopSelecting,
              icon: Icon(Icons.cancel),
            ),
          if (_isSelecting)
            PopupMenuButton<int>(
              onSelected: (categoryId) => _moveSelectedLocations(categoryId),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: null,
                    child: Text('General'),
                  ),
                  ..._categoryList.map(
                        (category) => PopupMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                  PopupMenuItem(
                    value: -1,
                    child: Text('New Category'),
                  ),
                ];
              },
              icon: Icon(Icons.move_to_inbox),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            CategoryListWidget(
              categoryList: _categoryList,
              selectedCategoryId: _selectedCategoryId,
              onSelectCategory: (categoryId) {
                setState(() {
                  _selectedCategoryId = categoryId;
                });
              },
            ),
            Expanded(child: _buildLocationList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationList() {
    List<LocationInfo> filteredLocations;
    if (_selectedCategoryId == null) {
      filteredLocations = _locationList;
    } else if (_selectedCategoryId == 0) {
      filteredLocations = _locationList.where((location) => location.categoryId == null).toList();
    } else {
      filteredLocations = _locationList.where((location) => location.categoryId == _selectedCategoryId).toList();
    }

    return ListView.builder(
      itemCount: filteredLocations.length,
      itemBuilder: (context, index) {
        final locationInfo = filteredLocations[index];
        return Dismissible(
          key: Key(locationInfo.id.toString()),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              await Methods.deleteLocationFromList(context, locationInfo, _locationList, () {
                setState(() {});
              });
            } else if (direction == DismissDirection.startToEnd) {
              _editLocation(context, locationInfo);
            }
            return false;
          },
          background: Container(
            color: Colors.green,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white),
                    Text(' Düzenle', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Sil ', style: TextStyle(color: Colors.white)),
                    Icon(Icons.delete, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            decoration: BoxDecoration(
              color: _selectedLocations.contains(locationInfo) ? Colors.grey[300] : Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: _isSelecting ? () => _toggleSelecting(locationInfo) : null,
              onLongPress: () {
                if (!_isSelecting) {
                  _startSelecting();
                  _toggleSelecting(locationInfo);
                }
              },
              title: Text(
                locationInfo.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Enlem: ${locationInfo.latitude.toStringAsFixed(2)}, Boylam: ${locationInfo.longitude.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => Methods.openLocationOnMap(locationInfo.latitude, locationInfo.longitude),
                    icon: Icon(Icons.map, color: Colors.blue),
                  ),
                  IconButton(
                    onPressed: () => Methods.shareLocationOnMap(locationInfo.latitude, locationInfo.longitude, locationInfo.name),
                    icon: Icon(Icons.share, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editLocation(BuildContext context, LocationInfo locationInfo) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        _locationNameController.text = locationInfo.name;
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konumu Düzenle',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _locationNameController,
                    decoration: InputDecoration(
                      labelText: 'Konum Adı',
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _updateLocation(context, locationInfo);
                      },
                      child: Text('Güncelle', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  void _updateLocation(BuildContext context, LocationInfo locationInfo) async {
    String locationName = _locationNameController.text;
    if (locationName.isNotEmpty) {
      locationInfo.name = locationName;
      await DatabaseHelper().updateLocation(locationInfo);
      _loadSavedLocations();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Konum güncellendi'),
      ));
    }
    Navigator.pop(context);
  }
}
