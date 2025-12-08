// movil/lib/dashboard_padre_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'login_page.dart';

class DashboardPadrePage extends StatefulWidget {
  const DashboardPadrePage({super.key});

  @override
  State<DashboardPadrePage> createState() => _DashboardPadrePageState();
}

class _DashboardPadrePageState extends State<DashboardPadrePage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Datos
  List<dynamic> _listaHijosJson = [];
  List<Marker> _marcadores = [];
  List<Polygon> _geocercas = [];
  Map<String, RutaHistorial> _historialPorHijo = {};
  
  bool _cargando = true;
  bool _mostrandoHistorial = false;
  String _usuarioNombre = "Tutor";
  Timer? _timerActualizacion;
  DateTime _fechaSeleccionada = DateTime.now();
  
  // Animación del historial
  AnimationController? _animController;
  AnimationController? _speedController;
  double _progresoAnimacion = 0.0;
  bool _animacionActiva = false;
  double _velocidadReproduccion = 1.0;
  
  // Vista 3D y efectos
  bool _vista3D = false;
  bool _mostrarEstadisticas = true;
  bool _mostrarHeatmap = false;
  String? _hijoSeleccionado;
  
  // Línea de tiempo interactiva
  bool _lineaTiempoExpandida = false;

  final List<Color> _colores = [
    const Color(0xFF2196F3), // Azul Material
    const Color(0xFFE91E63), // Rosa
    const Color(0xFF4CAF50), // Verde
    const Color(0xFFFF9800), // Naranja
    const Color(0xFF9C27B0), // Púrpura
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
      setState(() => _progresoAnimacion = _animController!.value);
    })..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _animacionActiva = false);
      }
    });
    
    _speedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _cargarPerfil();
    _actualizarDatos();
    _timerActualizacion = Timer.periodic(const Duration(seconds: 10), (t) => _actualizarDatos());
  }

  @override
  void dispose() {
    _timerActualizacion?.cancel();
    _animController?.dispose();
    _speedController?.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _usuarioNombre = "Padre de Familia"); 
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        if (_mostrandoHistorial) {
          _historialPorHijo.clear();
          _progresoAnimacion = 0.0;
          _cargarHistorialTodos();
        }
      });
    }
  }

  Future<void> _actualizarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    try {
      final url = Uri.parse("http://192.168.0.32:8000/api/monitoreo/dashboard-unificado/");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final List<dynamic> datosHijos = jsonDecode(response.body);
        _procesarDatosMapa(datosHijos);
        
        if (mounted) {
          setState(() {
            _listaHijosJson = datosHijos;
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print("Error red: $e");
    }
  }

  void _procesarDatosMapa(List<dynamic> hijos) {
    List<Marker> nuevosMarcadores = [];
    List<Polygon> nuevasGeocercas = [];
    int idxColor = 0;

    for (var hijo in hijos) {
      Color color = _colores[idxColor % _colores.length];
      
      if (hijo['ubicacion_actual'] != null) {
        double lat = hijo['ubicacion_actual']['lat'];
        double lng = hijo['ubicacion_actual']['lng'];
        
        nuevosMarcadores.add(
          Marker(
            point: LatLng(lat, lng),
            width: 100,
            height: 100,
            child: _UbicacionActualMarker(
              nombre: hijo['nombre'],
              color: color,
            ),
          )
        );
      }

      List<dynamic> polyCoords = hijo['poligono_kinder'];
      if (polyCoords.isNotEmpty) {
        List<LatLng> puntos = polyCoords.map((p) => LatLng(p['lat'], p['lng'])).toList();
        nuevasGeocercas.add(
          Polygon(
            points: puntos,
            color: color.withOpacity(0.15),
            borderColor: color,
            borderStrokeWidth: 3,
            label: hijo['nombre_kinder'] ?? "Zona",
            labelStyle: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              shadows: [Shadow(color: Colors.white, blurRadius: 4)],
            ),
          )
        );
      }
      idxColor++;
    }

    _marcadores = nuevosMarcadores;
    _geocercas = nuevasGeocercas;
  }

  Future<void> _toggleHistorial() async {
    if (_mostrandoHistorial) {
      setState(() {
        _historialPorHijo.clear();
        _mostrandoHistorial = false;
        _animacionActiva = false;
        _progresoAnimacion = 0.0;
        _hijoSeleccionado = null;
      });
      _animController?.stop();
    } else {
      setState(() => _mostrandoHistorial = true);
      await _cargarHistorialTodos();
      _iniciarAnimacion();
    }
  }

  void _iniciarAnimacion() {
    _animController?.duration = Duration(milliseconds: (8000 / _velocidadReproduccion).round());
    _animController?.reset();
    _animController?.forward();
    setState(() => _animacionActiva = true);
  }

  void _togglePlayPause() {
    if (_animController!.isAnimating) {
      _animController?.stop();
      setState(() => _animacionActiva = false);
    } else {
      if (_progresoAnimacion >= 1.0) {
        _iniciarAnimacion();
      } else {
        _animController?.forward();
        setState(() => _animacionActiva = true);
      }
    }
  }

  void _cambiarVelocidad() {
    setState(() {
      if (_velocidadReproduccion == 1.0) {
        _velocidadReproduccion = 2.0;
      } else if (_velocidadReproduccion == 2.0) {
        _velocidadReproduccion = 0.5;
      } else {
        _velocidadReproduccion = 1.0;
      }
      
      if (_animacionActiva) {
        final currentValue = _animController!.value;
        _animController?.duration = Duration(milliseconds: (8000 / _velocidadReproduccion).round());
        _animController?.forward(from: currentValue);
      }
    });
  }

  Future<void> _cargarHistorialTodos() async {
    int idx = 0;
    for (var hijo in _listaHijosJson) {
      await _cargarHistorialUnico(
        hijo['device_id'],
        hijo['nombre'],
        _colores[idx % _colores.length]
      );
      idx++;
    }
  }

  Future<void> _cargarHistorialUnico(String deviceId, String nombre, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    String fechaStr = "${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2,'0')}-${_fechaSeleccionada.day.toString().padLeft(2,'0')}";
    final url = Uri.parse("http://192.168.0.32:8000/api/monitoreo/historial/$deviceId/?fecha=$fechaStr");
    
    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        List<dynamic> raw = jsonDecode(response.body);
        
        if (raw.length < 2) return;

        List<PuntoHistorial> puntos = [];
        double distanciaTotal = 0.0;
        
        for (int i = 0; i < raw.length; i++) {
          final punto = PuntoHistorial(
            latLng: LatLng(raw[i]['lat'], raw[i]['lng']),
            timestamp: raw[i]['timestamp'] ?? '',
            indice: i,
            totalPuntos: raw.length,
          );
          
          if (i > 0) {
            distanciaTotal += _calcularDistancia(puntos[i-1].latLng, punto.latLng);
          }
          
          puntos.add(punto);
        }

        if (mounted) {
          setState(() {
            _historialPorHijo[nombre] = RutaHistorial(
              puntos: puntos,
              color: color,
              distanciaTotal: distanciaTotal,
              tiempoTotal: _calcularTiempoTotal(puntos),
            );
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  double _calcularDistancia(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // metros
    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final deltaLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final deltaLng = (p2.longitude - p1.longitude) * math.pi / 180;
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
              math.cos(lat1) * math.cos(lat2) *
              math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  Duration _calcularTiempoTotal(List<PuntoHistorial> puntos) {
    if (puntos.length < 2) return Duration.zero;
    try {
      final inicio = DateTime.parse(puntos.first.timestamp);
      final fin = DateTime.parse(puntos.last.timestamp);
      return fin.difference(inicio);
    } catch (e) {
      return Duration.zero;
    }
  }

  List<Widget> _construirCapasHistorial() {
    List<Widget> capas = [];
    
    _historialPorHijo.forEach((nombre, ruta) {
      // Filtrar si hay selección
      if (_hijoSeleccionado != null && _hijoSeleccionado != nombre) {
        return;
      }
      
      int puntosVisibles = (_progresoAnimacion * ruta.puntos.length).round();
      if (puntosVisibles < 2) return;
      
      List<PuntoHistorial> puntosActuales = ruta.puntos.sublist(0, puntosVisibles);
      
      // Heatmap (zonas donde pasó más tiempo)
      if (_mostrarHeatmap) {
        capas.add(_construirHeatmap(ruta, puntosActuales));
      }
      
      // Línea principal con efecto de brillo
      capas.add(
        PolylineLayer(
          polylines: [
            // Sombra/Resplandor
            Polyline(
              points: puntosActuales.map((p) => p.latLng).toList(),
              color: ruta.color.withOpacity(0.3),
              strokeWidth: 12.0,
            ),
            // Línea principal con gradiente
            Polyline(
              points: puntosActuales.map((p) => p.latLng).toList(),
              color: ruta.color,
              strokeWidth: 6.0,
              gradientColors: _generarGradienteProgresivo(ruta.color, puntosActuales.length),
            ),
          ],
        )
      );
      
      // Partículas animadas en movimiento
      if (_animacionActiva && puntosActuales.length > 2) {
        capas.add(_construirParticulas(puntosActuales, ruta.color));
      }
      
      // Marcadores
      List<Marker> marcadoresHistorial = [];
      
      // Punto inicial con animación
      if (puntosActuales.isNotEmpty) {
        marcadoresHistorial.add(_crearMarcadorInicio(puntosActuales.first, ruta.color, nombre));
      }
      
      // Puntos de interés (detenciones prolongadas)
      final puntosInteres = _detectarPuntosInteres(puntosActuales);
      for (var punto in puntosInteres) {
        marcadoresHistorial.add(_crearMarcadorInteres(punto, ruta.color));
      }
      
      // Marcador en movimiento (posición actual en la animación)
      if (puntosActuales.length > 1) {
        marcadoresHistorial.add(_crearMarcadorMovimiento(puntosActuales.last, ruta.color, nombre));
      }
      
      capas.add(MarkerLayer(markers: marcadoresHistorial));
    });
    
    return capas;
  }

  Widget _construirHeatmap(RutaHistorial ruta, List<PuntoHistorial> puntos) {
    List<CircleMarker> circles = [];
    
    for (int i = 0; i < puntos.length; i++) {
      circles.add(
        CircleMarker(
          point: puntos[i].latLng,
          radius: 20,
          useRadiusInMeter: true,
          color: ruta.color.withOpacity(0.1),
          borderColor: ruta.color.withOpacity(0.2),
          borderStrokeWidth: 1,
        ),
      );
    }
    
    return CircleLayer(circles: circles);
  }

  List<Color> _generarGradienteProgresivo(Color baseColor, int puntos) {
    List<Color> gradiente = [];
    for (int i = 0; i < puntos; i++) {
      double progress = i / puntos;
      gradiente.add(Color.lerp(
        baseColor.withOpacity(0.5),
        baseColor,
        progress,
      )!);
    }
    return gradiente;
  }

  Widget _construirParticulas(List<PuntoHistorial> puntos, Color color) {
    List<Marker> particulas = [];
    
    // Crear 3 partículas que se mueven a lo largo de la ruta
    for (int i = 0; i < 3; i++) {
      double offset = (i / 3.0 + _progresoAnimacion) % 1.0;
      int index = (offset * (puntos.length - 1)).round();
      
      if (index < puntos.length) {
        particulas.add(
          Marker(
            point: puntos[index].latLng,
            width: 20,
            height: 20,
            child: _ParticulaAnimada(color: color),
          ),
        );
      }
    }
    
    return MarkerLayer(markers: particulas);
  }

  List<PuntoHistorial> _detectarPuntosInteres(List<PuntoHistorial> puntos) {
    List<PuntoHistorial> interes = [];
    
    for (int i = 5; i < puntos.length - 5; i += 10) {
      // Detectar si estuvo quieto (baja variación de posición)
      double distancia = _calcularDistancia(puntos[i-5].latLng, puntos[i].latLng);
      if (distancia < 50) { // Menos de 50 metros en 10 puntos
        interes.add(puntos[i]);
      }
    }
    
    return interes;
  }

  Marker _crearMarcadorInicio(PuntoHistorial punto, Color color, String nombre) {
    return Marker(
      point: punto.latLng,
      width: 120,
      height: 120,
      child: _MarcadorInicioWidget(
        nombre: nombre,
        hora: _formatearHora(punto.timestamp),
        color: color,
      ),
    );
  }

  Marker _crearMarcadorInteres(PuntoHistorial punto, Color color) {
    return Marker(
      point: punto.latLng,
      width: 50,
      height: 50,
      child: _MarcadorInteresWidget(
        hora: _formatearHora(punto.timestamp),
        color: color,
      ),
    );
  }

  Marker _crearMarcadorMovimiento(PuntoHistorial punto, Color color, String nombre) {
    return Marker(
      point: punto.latLng,
      width: 140,
      height: 140,
      child: _MarcadorMovimientoWidget(
        nombre: nombre,
        hora: _formatearHora(punto.timestamp),
        color: color,
        animando: _animacionActiva,
      ),
    );
  }

  String _formatearHora(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _centrarEnHijo(dynamic hijo) {
    if (hijo['ubicacion_actual'] != null) {
      double lat = hijo['ubicacion_actual']['lat'];
      double lng = hijo['ubicacion_actual']['lng'];
      _mapController.move(LatLng(lat, lng), 16.0);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _cargando 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue.shade700),
                const SizedBox(height: 16),
                Text("Cargando datos...", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          )
        : Stack(
            children: [
              // Mapa
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-17.78, -63.18),
                  initialZoom: 13,
                  maxZoom: 18,
                  minZoom: 10,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _vista3D 
                      ? 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.movil',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolygonLayer(polygons: _geocercas),
                  if (_mostrandoHistorial) ..._construirCapasHistorial(),
                  if (!_mostrandoHistorial) MarkerLayer(markers: _marcadores),
                ],
              ),
              
              // Panel de control superior (estadísticas)
              if (_mostrandoHistorial && _mostrarEstadisticas)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildEstadisticasPanel(),
                ),
              
              // Línea de tiempo interactiva (lateral)
              if (_mostrandoHistorial)
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).size.height * 0.25,
                  bottom: 180,
                  child: _buildLineaTiempoVertical(),
                ),
              
              // Panel de control principal (inferior)
              if (_mostrandoHistorial)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildPanelControl(),
                ),
              
              // Botones flotantes de opciones
              if (_mostrandoHistorial)
                Positioned(
                  left: 16,
                  bottom: 200,
                  child: _buildBotonesOpciones(),
                ),
            ],
          ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Centro de Monitoreo", style: TextStyle(fontWeight: FontWeight.bold)),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        if (_mostrandoHistorial)
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _seleccionarFecha,
            tooltip: "Cambiar Fecha",
          ),
        IconButton(
          icon: Icon(
            _mostrandoHistorial ? Icons.map : Icons.history,
            color: _mostrandoHistorial ? Colors.yellowAccent : null,
          ),
          onPressed: _toggleHistorial,
          tooltip: _mostrandoHistorial ? "Ver Mapa en Tiempo Real" : "Ver Historial",
        )
      ],
    );
  }

  Widget _buildEstadisticasPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Estadísticas del Día",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _mostrarEstadisticas = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _historialPorHijo.entries.map((entry) {
                return _buildEstadisticaCard(entry.key, entry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaCard(String nombre, RutaHistorial ruta) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ruta.color.withOpacity(0.8), ruta.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ruta.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            nombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              const Icon(Icons.route, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                "${(ruta.distanciaTotal / 1000).toStringAsFixed(1)} km",
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                "${ruta.tiempoTotal.inHours}h ${ruta.tiempoTotal.inMinutes % 60}m",
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineaTiempoVertical() {
    if (!_lineaTiempoExpandida) {
      return GestureDetector(
        onTap: () => setState(() => _lineaTiempoExpandida = true),
        child: Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline, color: Colors.blue, size: 24),
              SizedBox(height: 8),
              RotatedBox(
                quarterTurns: 3,
                child: Text("TIMELINE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Línea de Tiempo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _lineaTiempoExpandida = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: _historialPorHijo.entries.map((entry) {
                return _buildItemLineaTiempo(entry.key, entry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemLineaTiempo(String nombre, RutaHistorial ruta) {
    bool isSeleccionado = _hijoSeleccionado == nombre;
    int puntosVisibles = (_progresoAnimacion * ruta.puntos.length).round();
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _hijoSeleccionado = isSeleccionado ? null : nombre;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSeleccionado ? ruta.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSeleccionado ? ruta.color : Colors.grey.shade300,
            width: isSeleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: ruta.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isSeleccionado ? ruta.color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$puntosVisibles/${ruta.puntos.length} puntos",
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesOpciones() {
    return Column(
      children: [
        _buildBotonOpcion(
          icon: _mostrarHeatmap ? Icons.bubble_chart : Icons.bubble_chart_outlined,
          label: "Heatmap",
          activo: _mostrarHeatmap,
          onTap: () => setState(() => _mostrarHeatmap = !_mostrarHeatmap),
        ),
        const SizedBox(height: 8),
        _buildBotonOpcion(
          icon: _vista3D ? Icons.map : Icons.terrain,
          label: "Vista",
          activo: _vista3D,
          onTap: () => setState(() => _vista3D = !_vista3D),
        ),
        const SizedBox(height: 8),
        _buildBotonOpcion(
          icon: Icons.filter_list,
          label: "Filtrar",
          activo: _hijoSeleccionado != null,
          onTap: () => setState(() => _hijoSeleccionado = null),
        ),
      ],
    );
  }

  Widget _buildBotonOpcion({
    required IconData icon,
    required String label,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: activo ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: activo ? Colors.white : Colors.grey.shade700, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: activo ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Fecha y controles
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            "${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    // Velocidad
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: GestureDetector(
                        onTap: _cambiarVelocidad,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "${_velocidadReproduccion}x",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Botón reiniciar
                    _buildControlButton(
                      icon: Icons.replay,
                      color: Colors.orange,
                      onPressed: _iniciarAnimacion,
                    ),
                    const SizedBox(width: 8),
                    
                    // Botón play/pause
                    _buildControlButton(
                      icon: _animacionActiva ? Icons.pause : Icons.play_arrow,
                      color: Colors.green,
                      onPressed: _togglePlayPause,
                      grande: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Slider de progreso mejorado
                Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.blue.shade700,
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: Colors.blue.shade700,
                        overlayColor: Colors.blue.withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: _progresoAnimacion,
                        onChanged: (value) {
                          setState(() {
                            _progresoAnimacion = value;
                            _animController?.value = value;
                          });
                        },
                        onChangeEnd: (value) {
                          if (_animacionActiva) {
                            _animController?.forward(from: value);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Inicio",
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                          Text(
                            "${(_progresoAnimacion * 100).round()}%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            "Fin",
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Leyenda de hijos
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _historialPorHijo.entries.map((entry) {
                    bool isSeleccionado = _hijoSeleccionado == entry.key;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _hijoSeleccionado = isSeleccionado ? null : entry.key;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSeleccionado 
                            ? entry.value.color.withOpacity(0.2)
                            : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSeleccionado ? entry.value.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: entry.value.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: entry.value.color.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSeleccionado ? FontWeight.bold : FontWeight.normal,
                                color: isSeleccionado ? entry.value.color : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool grande = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: grande ? 32 : 24,
        padding: EdgeInsets.all(grande ? 12 : 8),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _usuarioNombre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text("Tutor Principal"),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.family_restroom, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    "MIS HIJOS",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            ..._listaHijosJson.asMap().entries.map((entry) {
              var hijo = entry.value;
              Color color = _colores[entry.key % _colores.length];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.face, color: color, size: 24),
                  ),
                  title: Text(
                    hijo['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hijo['last_status'] ?? 'Sin datos',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.gps_fixed, color: color, size: 18),
                  ),
                  onTap: () => _centrarEnHijo(hijo),
                ),
              );
            }),
            
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text(
                "Cerrar Sesión",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: _cerrarSesion,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==================== CLASES DE DATOS ====================
class PuntoHistorial {
  final LatLng latLng;
  final String timestamp;
  final int indice;
  final int totalPuntos;

  PuntoHistorial({
    required this.latLng,
    required this.timestamp,
    required this.indice,
    required this.totalPuntos,
  });
}

class RutaHistorial {
  final List<PuntoHistorial> puntos;
  final Color color;
  final double distanciaTotal;
  final Duration tiempoTotal;

  RutaHistorial({
    required this.puntos,
    required this.color,
    required this.distanciaTotal,
    required this.tiempoTotal,
  });
}

// ==================== WIDGETS PERSONALIZADOS ====================
class _UbicacionActualMarker extends StatelessWidget {
  final String nombre;
  final Color color;

  const _UbicacionActualMarker({
    required this.nombre,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            nombre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
            Icon(Icons.person_pin_circle, color: color, size: 44),
          ],
        ),
      ],
    );
  }
}

class _MarcadorInicioWidget extends StatelessWidget {
  final String nombre;
  final String hora;
  final Color color;

  const _MarcadorInicioWidget({
    required this.nombre,
    required this.hora,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              Text(
                nombre,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Text(
                "INICIO",
                style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Text(
                hora,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(Icons.flag, color: Colors.white, size: 8),
            ),
          ],
        ),
      ],
    );
  }
}

class _MarcadorInteresWidget extends StatelessWidget {
  final String hora;
  final Color color;

  const _MarcadorInteresWidget({
    required this.hora,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause_circle, size: 10, color: color),
              const SizedBox(width: 3),
              Text(
                hora,
                style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}

class _MarcadorMovimientoWidget extends StatelessWidget {
  final String nombre;
  final String hora;
  final Color color;
  final bool animando;

  const _MarcadorMovimientoWidget({
    required this.nombre,
    required this.hora,
    required this.color,
    required this.animando,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (animando) _PulseAnimation(color: color),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "EN MOVIMIENTO",
                    style: TextStyle(fontSize: 7, color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    hora,
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  )
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Color color;
  const _PulseAnimation({required this.color});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 + (_controller.value * 1.5);
        final opacity = 0.4 * (1 - _controller.value);
        
        return Container(
          width: 40 * scale,
          height: 40 * scale,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _ParticulaAnimada extends StatefulWidget {
  final Color color;
  const _ParticulaAnimada({required this.color});

  @override
  State<_ParticulaAnimada> createState() => _ParticulaAnimadaState();
}

class _ParticulaAnimadaState extends State<_ParticulaAnimada> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12 + (8 * _controller.value),
          height: 12 + (8 * _controller.value),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.6 * (1 - _controller.value)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
        );
      },
    );
  }
}