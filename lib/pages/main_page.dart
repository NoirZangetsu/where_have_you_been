import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../method/methods.dart';
import '../database/database_helper_1.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widget/category_list_widget.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  LocationData? _currentLocation;
  List<CategoryInfo> _categoryList = [];
  TextEditingController _locationNameController = TextEditingController();
  int? selectedCategoryId;
  List<LocationInfo> _locationList = [];
  bool _showButtons = false;

  bool _hasInternet = false;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection().then((_) {
      if (_hasInternet) {
        _getLocation();
        _loadCategories();
      }
    });
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _hasInternet = (connectivityResult != ConnectivityResult.none);
    });

    if (_hasInternet) {
      _getLocation();
      _loadCategories();
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _currentLocation = null;
    });

    try {
      LocationData? locationData = await Methods.getLocation();
      setState(() {
        _currentLocation = locationData;
      });
    } catch (e) {
      print('Konum alınamadı: $e');
    }
  }

  Future<void> _loadCategories() async {
    List<CategoryInfo> categories = await DatabaseHelper().loadCategories();
    setState(() {
      _categoryList = categories;
    });
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




  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery
        .of(context)
        .size
        .width * 0.8;
    final double buttonHeight = MediaQuery
        .of(context)
        .size
        .height * 0.06;

    if (!_hasInternet) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mevcut Konum'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _noInternetScreen(buttonWidth, buttonHeight),
        ),
      );

    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Mevcut Konum'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildMap(),
          if (_showButtons)
            Container(
              color: Colors.black.withOpacity(0.4), // Karartma efekti
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 15.0, bottom: 15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    child: _showButtons
                        ? Column(
                      children: [
                        _actionButton(
                          onPressed: _getLocation,
                          icon: Icons.location_searching,
                          label: 'Konum Bul',
                        ),
                        _actionButton(
                          onPressed: () => _addToLocationList(context),
                          icon: Icons.add,
                          label: 'Listeye Ekle',
                        ),
                        _actionButton(
                          onPressed: () =>
                              Methods.shareLocationOnMap(
                                _currentLocation!.latitude!,
                                _currentLocation!.longitude!,
                                'Mevcut Konum',
                              ),
                          icon: Icons.share,
                          label: 'Konumu Paylaş',
                        ),
                      ],
                    )
                        : SizedBox.shrink(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _showButtons = !_showButtons;
                        });
                      },
                      backgroundColor: Colors.transparent, // Arka planı şeffaf hale getir
                      child: Icon(_showButtons ? Icons.close : Icons.menu, color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noInternetScreen(double buttonWidth, double buttonHeight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Location Cards
            if (_currentLocation != null) ...[
              _buildLocationCard('Latitude', _currentLocation!.latitude),
              _buildLocationCard('Longitude', _currentLocation!.longitude),
            ],

            SizedBox(height: 20),

            // Konum Bul Button
            _buildButton('Konum Bul', Icons.location_searching, _getLocation, buttonWidth, buttonHeight),
            SizedBox(height: 10),

            // Listeye Ekle Button
            _buildButton('Listeye Ekle', Icons.add, () => _addToLocationList(context), buttonWidth, buttonHeight),
            SizedBox(height: 10),

            if (_currentLocation != null) ...[
              // Konumu Aç Button
              _buildButton('Konumu Aç', Icons.open_in_browser, () => Methods.openLocationOnMap(_currentLocation!.latitude!, _currentLocation!.longitude!), buttonWidth, buttonHeight),
              SizedBox(height: 10),

              // Konumu Paylaş Button
              _buildButton('Konumu Paylaş', Icons.share, () => Methods.shareLocationOnMap(_currentLocation!.latitude!, _currentLocation!.longitude!, 'Mevcut Konum'), buttonWidth, buttonHeight),
            ],

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String label, double? value) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: ListTile(
        leading: Icon(Icons.location_on, color: Colors.blue),
        title: Text(
          '$label: ${value ?? ''}',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed, double buttonWidth, double buttonHeight) {
    return Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white),
            Text(text, style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(width: 10), // To align text to center
          ],
        ),
        style: ElevatedButton.styleFrom(
          primary: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }





  Widget _actionButton({required void Function() onPressed, required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FloatingActionButton(
              onPressed: onPressed,
              backgroundColor: Colors.transparent, // Arka planı şeffaf hale getir
              child: Icon(icon, color: Colors.white),
              tooltip: label,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildMap() {
    if (_currentLocation == null) {
      return Center(
        child: SpinKitFadingCube( // Özelleştirilmiş yükleyici animasyonu
          color: Colors.blue,
          size: 50.0,
        ),
      );
    } else {
      final CameraPosition initialCameraPosition = CameraPosition(
        target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        zoom: 15,
      );

      return GoogleMap(
        initialCameraPosition: initialCameraPosition,
        markers: _buildMapMarkers(),
      );
    }
  }
  Set<Marker> _buildMapMarkers() {
    return {
      Marker(
        markerId: MarkerId('current_location'),
        position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
      ),
    };
  }

  void _addToLocationList(BuildContext context) async {
    if (_currentLocation != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
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
                          'Konum Adı Girin',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _locationNameController,
                          onChanged: (value) {},
                          decoration: InputDecoration(
                            labelText: 'Konum Adı',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kategori Seçin:',
                              style: TextStyle(fontSize: 16),
                            ),
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
                                onPressed: () => _showAddCategoryBottomSheet(context),
                                child: Text(
                                  'Kategori Seçin',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        CategoryListWidget(
                          categoryList: _categoryList,
                          selectedCategoryId: selectedCategoryId,
                          onSelectCategory: (categoryId) {
                            setState(() {
                              selectedCategoryId = categoryId;
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [Colors.green.shade300, Colors.green.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();

                              LocationInfo locationInfo = Methods.createLocationInfo(
                                _currentLocation!,
                                _locationNameController.text,
                                selectedCategoryId,
                              );

                              await DatabaseHelper().saveLocation(locationInfo);

                              _locationList.add(locationInfo);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Listeye Konum Ekle'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: Text(
                              'Kaydet',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        },
      );
    }
  }



}
