// movil/lib/home_page.dart
import 'package:flutter/material.dart';
import 'modo_nino_page.dart';
import 'login_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _idController = TextEditingController(text: "android123");

// Notificaciones de alerta
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {      
      if (message.notification != null) {
        NotificationService().mostrarNotificacion(
          message.notification!.title ?? "ALERTA",
          message.notification!.body ?? "Atención requerida"
        );
      }
    });
  }

// Interfaz de selección de modo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("SafeKid SIG",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Campo de texto (SOLO PARA MODO NIÑO)
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "ID del Dispositivo (Solo para Niño)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 30),

            // BOTÓN MODO NIÑO
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_idController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Escribe un ID primero")),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SafeKidHome(deviceId: _idController.text),
                    ),
                  );
                },
                icon: const Icon(Icons.child_care),
                label: const Text("MODO NIÑO (Rastrear)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BOTÓN MODO PADRE
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  // AHORA REDIRIGE AL LOGIN
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings), // Icono de Admin
                label: const Text("ACCESO PADRES (Login)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
