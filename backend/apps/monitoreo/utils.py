# backend/apps/monitoreo/utils.py
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import os

# Inicializamos Firebase una sola vez de forma segura para desarrollo
if not firebase_admin._apps:
    try:
        # Ruta a tu llave descargada
        cred_path = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"\nADVERTENCIA: No se pudo inicializar Firebase Admin. Detalles: {e}")
        print("Las notificaciones push estarán desactivadas localmente. Coloca tu archivo 'serviceAccountKey.json' real para habilitarlas.\n")

def enviar_alerta_push(token_fcm, titulo, cuerpo):
    if not token_fcm:
        return
        
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=titulo,
                body=cuerpo,
            ),
            token=token_fcm,
        )
        response = messaging.send(message)
        print(f"Notificación enviada: {response}")
    except Exception as e:
        print(f"Error enviando notificación: {e}")