import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../database/database_helper_1.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

class Methods {
  static TextEditingController _locationNameController = TextEditingController();

  static Future<LocationData?> getLocation() async {
    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

  static Future<void> shareLocationOnMap(double latitude, double longitude, String locationName) async {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
        String shareText = 'Location Name: $locationName\n\n$mapsUrl';
        print('Share location with Google Maps: $shareText');
        await Share.share(shareText);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        String mapsUrl = 'https://maps.apple.com/?q=$latitude,$longitude';
        String shareText = 'Location Name: $locationName\n\n$mapsUrl';
        print('Share location with Apple Maps: $shareText');
        await Share.share(shareText);
      }
    } else {
      String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      String shareText = 'Location Name: $locationName\n\n$mapsUrl';
      print('Share location with Google Maps on Web: $shareText');
      await Share.share(shareText);
    }
  }

  static LocationInfo createLocationInfo(LocationData currentLocation, String locationName, int? selectedCategoryId) {
    String locationString = 'Latitude: ${currentLocation.latitude}, Longitude: ${currentLocation.longitude}';
    // Generate a unique id using the current timestamp in milliseconds
    int uniqueId = DateTime.now().millisecondsSinceEpoch;
    return LocationInfo(
      id: uniqueId,
      name: locationName,
      locationString: locationString,
      latitude: currentLocation.latitude!,
      longitude: currentLocation.longitude!,
      categoryId: selectedCategoryId,
    );
  }

  static void openLocationOnMap(double latitude, double longitude) {
    if (!kIsWeb) {
      MapsLauncher.launchCoordinates(latitude, longitude);
    } else {
      String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      print('Open Google Maps with URL: $mapsUrl');
    }
  }

  static void showAddCategoryBottomSheet(BuildContext context, Function(CategoryInfo) onAddCategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori Oluştur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _locationNameController,
                    decoration: InputDecoration(
                      labelText: 'Kategori Adı',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 160),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _addCategory(context, onAddCategory);
                      },
                      child: Text(
                        'Ekle',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  static void _addCategory(BuildContext context, Function(CategoryInfo) onAddCategory) async {
    String categoryName = _locationNameController.text;
    if (categoryName.isNotEmpty) {
      // Generate a unique id using the current timestamp in milliseconds
      int uniqueId = DateTime.now().millisecondsSinceEpoch;
      CategoryInfo categoryInfo = CategoryInfo(id: uniqueId, name: categoryName); // Assign the unique id here
      await DatabaseHelper().saveCategory(categoryInfo);
      onAddCategory(categoryInfo); // Callback to notify the category is added
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kategori eklendi'),
      ));
    }
    Navigator.pop(context);
  }


  // Inside Methods class
  static Future<void> deleteLocationFromList(BuildContext context, LocationInfo locationInfo, List<LocationInfo> locationList, Function() refreshState) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Emin misiniz?'),
          content: Text('Bu konumu silmek istediğinize emin misiniz?'),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('İptal', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(backgroundColor: Colors.transparent),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                gradient: LinearGradient(
                  colors: [Colors.red.shade300, Colors.red.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Sil', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.transparent, // Arka planı şeffaf hale getir
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmDelete == true) {
      if (locationInfo.id != null) {
        try {
          await DatabaseHelper().deleteLocation(locationInfo.id!);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Silindi'),
          ));

          // Silme işlemi başarılı olduktan sonra _locationList'ten de kaldırın
          locationList.remove(locationInfo);
          refreshState(); // Call setState here
        } catch (e) {
          print('Silme hatası: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Silinemedi'),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Silinemedi: Geçersiz ID'),
        ));
      }
    }
  }



}
