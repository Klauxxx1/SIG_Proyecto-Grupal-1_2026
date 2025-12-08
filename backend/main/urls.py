# backend/main/urls.py
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework.routers import DefaultRouter
from apps.usuarios.views import login_view, UsuarioViewSet

# Router para el CRUD de usuarios
router = DefaultRouter()
router.register(r'usuarios', UsuarioViewSet, basename='usuario')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/login/', login_view, name='login'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Mantiene las URLs existentes de auth (me, registrar-token)
    path('api/auth/', include('apps.usuarios.urls')),

    # NUEVO: CRUD de usuarios en /api/usuarios/
    path('api/', include(router.urls)),

    # Monitoreo
    path('api/monitoreo/', include('apps.monitoreo.urls')),
]
