# backend/main/settings.py
from pathlib import Path
import os
from dotenv import load_dotenv
from datetime import timedelta

load_dotenv()

# Configuración específica para Windows y QGIS (DESHABILITADO TEMPORALMENTE)
if os.name == 'nt':
    QGIS_BIN_PATH = os.getenv('QGIS_BIN_PATH')

    if QGIS_BIN_PATH and os.path.exists(QGIS_BIN_PATH):
        # 2. Agregamos la carpeta al sistema temporalmente para que Windows encuentre las dependencias
        os.environ['PATH'] = QGIS_BIN_PATH + ";" + os.environ['PATH']

        # 2. [NUEVO] Calculamos la ruta a la carpeta 'share/proj' de QGIS
        # Si la ruta bin es "C:/.../bin", subimos un nivel para hallar "share"
        qgis_root = os.path.dirname(QGIS_BIN_PATH)
        proj_lib_path = os.path.join(qgis_root, "share", "proj")

        # Forzamos a que use ESTA ruta para las proyecciones
        os.environ['PROJ_LIB'] = proj_lib_path

        # 3. Apuntamos al archivo DLL.
        GDAL_LIBRARY_PATH = os.path.join(QGIS_BIN_PATH, "gdal311.dll")
    else:
        print("ADVERTENCIA: No se encontró la variable QGIS_BIN_PATH en el .env o la ruta no existe.")

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.getenv('SECRET_KEY')
DEBUG = True

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    'django.contrib.postgres',
    'django.contrib.gis',
    'rest_framework',
    'rest_framework_gis',
    'firebase_admin',
    'rest_framework_simplejwt',
    'django_filters',
    'corsheaders',

    'apps.monitoreo',
    'apps.usuarios',
]

AUTH_USER_MODEL = 'usuarios.Usuario'

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'main.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'main.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT'),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',},
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_FILTER_BACKENDS': ['django_filters.rest_framework.DjangoFilterBackend'],
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=30), # Sesión larga para la app
}

# CORS Configuration
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:3039",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:3039",
]
CORS_ALLOW_CREDENTIALS = True

LANGUAGE_CODE = 'en-us'
TIME_ZONE = os.getenv('TIME_ZONE')
USE_I18N = True
USE_TZ = True
STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
