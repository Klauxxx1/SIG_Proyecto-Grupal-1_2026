import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern (para usar la misma instancia siempre)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Configuración para Android
    // @mipmap/ic_launcher es el icono por defecto de tu app
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> mostrarNotificacion(String titulo, String cuerpo) async {
    // Configuración de la Alerta (Sonido, Vibración, Importancia Máxima)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // ID del canal
      'Alertas de Seguridad', // Nombre del canal visible para el usuario
      channelDescription: 'Canal para alertas críticas de zona segura',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Mostrar la notificación
    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      titulo,
      cuerpo,
      platformChannelSpecifics,
    );
  }
}