# backend/apps/usuarios/urls.py
from django.urls import path
from .views import RegistrarFcmTokenView, obtener_usuario_actual

urlpatterns = [
    path('registrar-token/', RegistrarFcmTokenView.as_view(), name='registrar-token'),
    path('me/', obtener_usuario_actual, name='usuario-actual'),
]
