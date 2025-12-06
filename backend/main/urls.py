# backend/main/urls.py
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from apps.usuarios.views import login_view

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/login/', login_view, name='login'),  # Endpoint personalizado
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/', include('apps.usuarios.urls')),  # Para /api/auth/me

    path('api/monitoreo/', include('apps.monitoreo.urls')),
    path('api/usuarios/', include('apps.usuarios.urls')),
]
