from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from rest_framework import status, viewsets, permissions
from .models import Usuario
from .serializers import UsuarioSerializer

class RegistrarFcmTokenView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        fcm_token = request.data.get('fcm_token')

        if not fcm_token:
            return Response({"error": "Falta el token"}, status=400)

        user = request.user
        user.fcm_token = fcm_token
        user.save()

        print(f"Token FCM actualizado para {user.username}")
        return Response({"status": "Token actualizado correctamente"})


@api_view(['POST'])
def login_view(request):
    """
    Endpoint personalizado para login que devuelve el formato esperado por el frontend
    """
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response(
            {"detail": "Se requiere username y password"},
            status=status.HTTP_400_BAD_REQUEST
        )

    user = authenticate(username=username, password=password)

    if user is None:
        return Response(
            {"detail": "Credenciales inválidas"},
            status=status.HTTP_401_UNAUTHORIZED
        )

    if not user.is_active:
        return Response(
            {"detail": "Usuario inactivo"},
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Generar token JWT
    refresh = RefreshToken.for_user(user)
    access_token = str(refresh.access_token)

    # Calcular tiempo de expiración (30 días en segundos)
    expires_in = 30 * 24 * 60 * 60  # 30 días

    return Response({
        "access_token": access_token,
        "token_type": "Bearer",
        "expires_in": expires_in
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def obtener_usuario_actual(request):
    """
    Endpoint GET /api/auth/me para obtener datos del usuario autenticado
    """
    usuario = request.user

    return Response({
        "id": str(usuario.id),
        "email": usuario.email or "",
        "full_name": f"{usuario.first_name} {usuario.last_name}".strip() or usuario.username,
        "phone": usuario.telefono or None,
        "is_active": usuario.is_active,
        "created_at": usuario.date_joined.isoformat(),
        # Campos adicionales del modelo Usuario
        "username": usuario.username,
        "first_name": usuario.first_name,
        "last_name": usuario.last_name,
        "es_tutor": usuario.es_tutor,
        "es_admin_institucion": usuario.es_admin_institucion,
    }, status=status.HTTP_200_OK)


class UsuarioViewSet(viewsets.ModelViewSet):
    """
    CRUD completo de usuarios/tutores

    Endpoints:
    - GET /api/usuarios/ - Listar todos
    - POST /api/usuarios/ - Crear nuevo
    - GET /api/usuarios/{id}/ - Ver detalle
    - PUT /api/usuarios/{id}/ - Editar completo
    - PATCH /api/usuarios/{id}/ - Editar parcial
    - DELETE /api/usuarios/{id}/ - Eliminar

    Filtros:
    - ?es_tutor=true - Solo tutores
    - ?es_admin_institucion=true - Solo admins de institución
    """
    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Usuario.objects.all()

        # Filtros opcionales desde query params
        es_tutor = self.request.query_params.get('es_tutor', None)
        es_admin = self.request.query_params.get('es_admin_institucion', None)

        if es_tutor is not None:
            queryset = queryset.filter(es_tutor=es_tutor.lower() == 'true')

        if es_admin is not None:
            queryset = queryset.filter(es_admin_institucion=es_admin.lower() == 'true')

        return queryset.order_by('-date_joined')
