# backend/apps/monitoreo/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ReportarUbicacionView,
    DatosMapaPadreView,
    MisHijosListView,
    HistorialRutaView,
    DashboardPadreUnificadoView,
    NinoViewSet,
    InstitucionViewSet,
    NinosPorInstitucionView
)

# ========================================
# ROUTER PARA VIEWSETS (CRUD AUTOMÁTICO)
# ========================================
router = DefaultRouter()
router.register(r'ninos', NinoViewSet, basename='nino')  # CRUD Niños (Admin)
router.register(r'instituciones', InstitucionViewSet, basename='institucion')  # CRUD Instituciones

# ========================================
# URLS DE MONITOREO
# ========================================
urlpatterns = [
    # Endpoints especiales (no CRUD)
    path('reportar/', ReportarUbicacionView.as_view(), name='reportar-ubicacion'),
    path('mapa-padre/', DatosMapaPadreView.as_view(), name='mapa-padre'),
    path('mis-hijos/', MisHijosListView.as_view(), name='mis-hijos'),
    path('historial/<str:device_id>/', HistorialRutaView.as_view(), name='historial-ruta'),
    path('dashboard-unificado/', DashboardPadreUnificadoView.as_view(), name='dashboard-unificado'),

    # Endpoint para frontend web: listar niños por institución
    path('instituciones/<int:institucion_id>/ninos/', NinosPorInstitucionView.as_view(), name='ninos-por-institucion'),

    # Incluir URLs del router (CRUD automático)
    path('', include(router.urls)),
]
