# backend/apps/monitoreo/models.py
from django.contrib.gis.db import models 
from django.conf import settings
from django.contrib.postgres.indexes import GistIndex

class Institucion(models.Model):
    nombre = models.CharField(max_length=100)
    direccion = models.CharField(max_length=200, blank=True)
    area = models.PolygonField(srid=4326) 

    def __str__(self):
        return self.nombre
    
    class Meta:
        indexes = [
            GistIndex(fields=['area']), 
        ]


class Nino(models.Model):
    nombre = models.CharField(max_length=100)
    tutor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE, 
        related_name='ninos'
    )
    device_id = models.CharField(max_length=100, unique=True, help_text="ID único del dispositivo del niño")
    activo = models.BooleanField(default=True)
    last_status = models.CharField(max_length=50, blank=True, help_text="Último estado reportado", null=True)

    institucion = models.ForeignKey(Institucion, on_delete=models.SET_NULL, null=True, related_name='alumnos')
    
    ultima_ubicacion = models.PointField(srid=4326, blank=True, null=True)
    ultima_actualizacion = models.DateTimeField(auto_now=True, null=True)

    def __str__(self):
        return self.nombre
    

class HistorialUbicacion(models.Model):
    nino = models.ForeignKey(Nino, on_delete=models.CASCADE, related_name='historial')
    ubicacion = models.PointField(srid=4326)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    fuera_de_zona = models.BooleanField(default=False)
    bateria = models.IntegerField(null=True, blank=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['timestamp']),
            models.Index(fields=['fuera_de_zona']),
            GistIndex(fields=['ubicacion']),
        ]