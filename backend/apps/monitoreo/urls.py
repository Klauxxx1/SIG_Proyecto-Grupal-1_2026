# backend/apps/monitoreo/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ReportarUbicacionView,
    DatosMapaPadreView,
    MisHijosListView,
    HistorialRutaView,
    DashboardPadreUnificadoView,
    InstitucionViewSet
)

# Router para ViewSets (CRUD automático)
router = DefaultRouter()
router.register(r'instituciones', InstitucionViewSet, basename='institucion')

urlpatterns = [
    path('reportar/', ReportarUbicacionView.as_view(), name='reportar-ubicacion'),
    path('mapa-padre/', DatosMapaPadreView.as_view(), name='mapa-padre'),
    path('mis-hijos/', MisHijosListView.as_view()),
    path('historial/<str:device_id>/', HistorialRutaView.as_view()),
    path('dashboard-unificado/', DashboardPadreUnificadoView.as_view()),

    # Incluir rutas del router (CRUD instituciones)
    path('', include(router.urls)),
]
