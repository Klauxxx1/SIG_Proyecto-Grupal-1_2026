# 📚 CRUD DE NIÑOS - Documentación de Endpoints

## 🔒 Permisos

- **Solo ADMIN** puede usar estos endpoints
- Requiere login con usuario administrador
- Token JWT válido en el header `Authorization: Bearer {TOKEN}`

---

## 1️⃣ LISTAR TODOS LOS NIÑOS

**Endpoint:**
```
GET /api/monitoreo/ninos/
```

**Headers:**
```
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "nombre": "Juan Pérez",
    "device_id": "android123",
    "tutor": 5,
    "institucion": 1,
    "activo": true,
    "last_status": "Dentro del Kinder",
    "ultima_ubicacion": {
      "lat": -17.7838,
      "lng": -63.1821
    },
    "ultima_actualizacion": "2025-12-08T15:30:00Z"
  },
  {
    "id": 2,
    "nombre": "María García",
    "device_id": "android456",
    "tutor": 6,
    "institucion": 1,
    "activo": true,
    "last_status": "Fuera de zona",
    "ultima_ubicacion": {
      "lat": -17.7900,
      "lng": -63.1750
    },
    "ultima_actualizacion": "2025-12-08T15:25:00Z"
  }
]
```

---

## 2️⃣ CREAR UN NUEVO NIÑO

**Endpoint:**
```
POST /api/monitoreo/ninos/
```

**Headers:**
```
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json
```

**Body:**
```json
{
  "nombre": "Pedro López",
  "device_id": "android789",
  "tutor": 7,
  "institucion": 2
}
```

**Validaciones:**
- `nombre`: obligatorio, máximo 100 caracteres
- `device_id`: obligatorio, único (no puede repetirse)
- `tutor`: obligatorio, debe ser ID de un usuario existente
- `institucion`: obligatorio, debe ser ID de una institución existente

**Response (201 Created):**
```json
{
  "id": 3,
  "nombre": "Pedro López",
  "device_id": "android789",
  "tutor": 7,
  "institucion": 2,
  "activo": true,
  "last_status": "Seguro",
  "ultima_ubicacion": null,
  "ultima_actualizacion": "2025-12-08T16:00:00Z"
}
```

**Response (400 Bad Request) - Error:**
```json
{
  "device_id": ["Este campo debe ser único."],
  "tutor": ["Usuario no existe."]
}
```

---

## 3️⃣ VER UN NIÑO ESPECÍFICO

**Endpoint:**
```
GET /api/monitoreo/ninos/{id}/
```

**Ejemplo:**
```
GET /api/monitoreo/ninos/1/
```

**Headers:**
```
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "device_id": "android123",
  "tutor": 5,
  "institucion": 1,
  "activo": true,
  "last_status": "Dentro del Kinder",
  "ultima_ubicacion": {
    "lat": -17.7838,
    "lng": -63.1821
  },
  "ultima_actualizacion": "2025-12-08T15:30:00Z"
}
```

**Response (404 Not Found):**
```json
{
  "detail": "No encontrado."
}
```

---

## 4️⃣ EDITAR UN NIÑO COMPLETAMENTE (PUT)

**Endpoint:**
```
PUT /api/monitoreo/ninos/{id}/
```

**Ejemplo:**
```
PUT /api/monitoreo/ninos/1/
```

**Headers:**
```
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json
```

**Body (todos los campos):**
```json
{
  "nombre": "Juan Pérez Actualizado",
  "device_id": "android123",
  "tutor": 5,
  "institucion": 2,
  "activo": true
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "nombre": "Juan Pérez Actualizado",
  "device_id": "android123",
  "tutor": 5,
  "institucion": 2,
  "activo": true,
  "last_status": "Dentro del Kinder",
  "ultima_ubicacion": {
    "lat": -17.7838,
    "lng": -63.1821
  },
  "ultima_actualizacion": "2025-12-08T16:30:00Z"
}
```

---

## 5️⃣ EDITAR UN NIÑO PARCIALMENTE (PATCH)

**Endpoint:**
```
PATCH /api/monitoreo/ninos/{id}/
```

**Ejemplo:**
```
PATCH /api/monitoreo/ninos/1/
```

**Headers:**
```
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json
```

**Body (solo los campos que cambias):**
```json
{
  "nombre": "Juan José Pérez",
  "institucion": 2
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "nombre": "Juan José Pérez",
  "device_id": "android123",
  "tutor": 5,
  "institucion": 2,
  "activo": true,
  "last_status": "Dentro del Kinder",
  "ultima_ubicacion": {
    "lat": -17.7838,
    "lng": -63.1821
  },
  "ultima_actualizacion": "2025-12-08T16:45:00Z"
}
```

---

## 6️⃣ ELIMINAR UN NIÑO

**Endpoint:**
```
DELETE /api/monitoreo/ninos/{id}/
```

**Ejemplo:**
```
DELETE /api/monitoreo/ninos/1/
```

**Headers:**
```
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json
```

**Response (204 No Content):**
```
(Sin contenido)
```

**Response (404 Not Found):**
```json
{
  "detail": "No encontrado."
}
```

---

## 🔐 Códigos de Error

| Código | Significado |
|--------|------------|
| 200 | OK - Solicitud exitosa |
| 201 | Created - Recurso creado |
| 204 | No Content - Eliminado exitosamente |
| 400 | Bad Request - Datos inválidos |
| 401 | Unauthorized - Token inválido o ausente |
| 403 | Forbidden - No tienes permisos (no eres admin) |
| 404 | Not Found - El niño no existe |

---

## 📝 Notas Importantes

1. **device_id es único**: No puedes crear dos niños con el mismo device_id
2. **Solo Admin**: Los padres NO pueden acceder a estos endpoints
3. **Tutor inmutable**: Una vez creado el niño con un tutor, no se recomienda cambiar
4. **Campos que NO deben cambiar**: `device_id` (lo usa el dispositivo)
5. **Historia preservada**: Al eliminar un niño, su historial se mantiene en la BD

---

## 🧪 Ejemplo Completo en JavaScript

```javascript
const API_URL = "http://localhost:8000/api/monitoreo";
const ADMIN_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGc..."; // Token del admin

// 1. Listar todos los niños
async function listarNinos() {
  const res = await fetch(`${API_URL}/ninos/`, {
    headers: { "Authorization": `Bearer ${ADMIN_TOKEN}` }
  });
  return await res.json();
}

// 2. Crear un niño
async function crearNino(nombre, deviceId, tutorId, institucionId) {
  const res = await fetch(`${API_URL}/ninos/`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${ADMIN_TOKEN}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      nombre,
      device_id: deviceId,
      tutor: tutorId,
      institucion: institucionId
    })
  });
  return await res.json();
}

// 3. Editar un niño
async function editarNino(ninoId, datos) {
  const res = await fetch(`${API_URL}/ninos/${ninoId}/`, {
    method: "PATCH",
    headers: {
      "Authorization": `Bearer ${ADMIN_TOKEN}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(datos)
  });
  return await res.json();
}

// 4. Eliminar un niño
async function eliminarNino(ninoId) {
  const res = await fetch(`${API_URL}/ninos/${ninoId}/`, {
    method: "DELETE",
    headers: { "Authorization": `Bearer ${ADMIN_TOKEN}` }
  });
  return res.status === 204;
}

// Ejemplo de uso:
// crearNino("Carlos Rodríguez", "android999", 8, 1);
// editarNino(1, { nombre: "Nuevo nombre" });
// eliminarNino(1);
```

---

## ✅ Está listo para usar en tu web
