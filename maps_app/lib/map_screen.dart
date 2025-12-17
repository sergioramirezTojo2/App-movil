import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/api_service.dart';
 
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final CameraPosition _initialPosition =
      const CameraPosition(target: LatLng(-17.783179, -63.182218), zoom: 18);

  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _puntos = [];
  bool _huboError = false; // bandera para controlar Snackbar de error

  @override
  void initState() {
    super.initState();
    _cargarPuntos();
  }

  // ======================================
  // Cargar todos los puntos desde backend
  // ======================================
  Future<void> _cargarPuntos() async {
    try {
      final data = await ApiService.obtenerPuntos(); // Trae datos del backend

      setState(() {
        _puntos = data;

        _markers = data.map((p) {
          return Marker(
            markerId: MarkerId(p['nombre']),
            position: LatLng(p['lat'], p['lng']),
            infoWindow: InfoWindow(title: p['nombre']),
          );
        }).toSet();

        _huboError = false; // Resetear flag si carga bien
      });
    } catch (e) {
      // Solo mostrar Snackbar si hay error real de conexión
      if (!_huboError) {
        _huboError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PROBLEMA DE CONEXION")),
        );
      }
    }
  }

  // ===========================
  // Agregar un punto nuevo
  // ===========================
  Future<void> _agregarPunto(LatLng latLong) async {
    TextEditingController _textController = TextEditingController();

    String? nombre = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Añade un título"),
          content: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: "Nombre de referencia...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _textController.text.trim()),
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );

    if (nombre != null && nombre.isNotEmpty) {
      bool ok = await ApiService.guardarPunto(
          latLong.latitude, latLong.longitude, nombre);

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Punto guardado correctamente")),
        );
        _cargarPunto(nombre, latLong);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al guardar el punto")),
        );
      }
    }
  }

  void _cargarPunto(String nombre, LatLng latLong) {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId(nombre),
          position: latLong,
          infoWindow: InfoWindow(title: nombre)));
      _puntos.add({
        'nombre': nombre,
        'lat': latLong.latitude,
        'lng': latLong.longitude,
      });
    });
  }

  // ===========================
  // Eliminar punto
  // ===========================
  Future<void> _eliminarPunto(String nombre) async {
    bool ok = await ApiService.eliminarPunto(nombre);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Punto '$nombre' eliminado")),
      );
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == nombre);
        _puntos.removeWhere((punto) => punto['nombre'] == nombre);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar '$nombre'")),
      );
    }
  }

  // ===========================
  // Centrar mapa en ubicación
  // ===========================
  void _irAUbicacion(LatLng latLong) {
    _controller?.animateCamera(CameraUpdate.newLatLng(latLong));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MAPA APP"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPuntos,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              child: Text("Puntos de Interés",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _puntos.length,
                itemBuilder: (context, index) {
                  final p = _puntos[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(p['nombre'] ?? 'Sin nombre'),
                    subtitle: Text(
                        "(${p['lat']?.toStringAsFixed(4) ?? '0'}, ${p['lng']?.toStringAsFixed(4) ?? '0'})"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarPunto(p['nombre']),
                    ),
                    onTap: () {
                      _irAUbicacion(LatLng(p['lat'], p['lng']));
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (controller) => _controller = controller,
        mapType: MapType.normal,
        markers: _markers,
        onTap: _agregarPunto,
      ),
    );
  }
}
