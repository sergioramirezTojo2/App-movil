import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'location_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller; //se inicia en nulo cuando carga se guarda aqui lo del mapa
  // queda así para hacer otras cosas luego

  final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-17.783279, -63.182174),
    zoom: 10,
  );

  final Set<Marker> _markers = {
    Marker(
      markerId: MarkerId("PepitoDaigual"),
      position: LatLng(-17.783279, -63.182174),
      infoWindow: InfoWindow(title: "Mi Restaurante")
    )
    //marcador de ubicación
  };

  List<Location> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList('locations');
    if (locationsJson != null) {
      _locations = locationsJson.map((json) => Location.fromJson(json as Map<String, dynamic>)).toList();
      setState(() {
        _markers = _locations.map((location) => Marker(
          markerId: MarkerId(location.toString()),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(title: location.title),
        )).toSet();
      });
    }
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = _locations.map((location) => location.toJson()).toList();
    await prefs.setStringList('locations', locationsJson.map((json) => json.toString()).toList());
  }

  void addMarker(LatLng latLong) async {
    TextEditingController _textController = TextEditingController();  //capturar el texto textfiles
    String? title = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pon un título"),
          content: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: "Restaurante LA CASONA"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text("Cancelar")),
            TextButton(onPressed: () => Navigator.of(context).pop(_textController.text), child: Text("Guardar")),
          ],
        );
      },
    );

    if (title != null && title.isNotEmpty) {
      setState(() {
        final newLocation = Location(latitude: latLong.latitude, longitude: latLong.longitude, title: title);
        _locations.add(newLocation);
        _markers.add(Marker(
          markerId: MarkerId(latLong.toString()),
          position: latLong,
          infoWindow: InfoWindow(title: title),
        ));
      });
      _saveLocations();
    }
  }

  void removeMarker(MarkerId markerId) {
    setState(() {
      final locationToRemove = _locations.firstWhere((location) => location.toString() == markerId.value);
      _locations.remove(locationToRemove);
      _markers.removeWhere((marker) => marker.markerId.value == markerId.value);
    });
    _saveLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa guapardo"),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (controller) {
          _controller = controller;
        },
        mapType: MapType.normal, //modo satélite ciudad satelital
        markers: _markers,
        onTap: (LatLng) => addMarker(LatLng),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveLocations,
        child: Icon(Icons.save),
      ),
    );
  }
}