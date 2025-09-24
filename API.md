# 📡 API Endpoints - Survivor

## 🔐 Autenticación

### **Registro e Inicio de Sesión**
```http
POST /api/users/register
Content-Type: application/json

{
  "username": "messi10",
  "email": "messi@example.com", 
  "password": "messi123",
  "firstName": "Lionel",
  "lastName": "Messi"
}
```

```http
POST /api/users/login
Content-Type: application/json

{
  "emailOrUsername": "messi10",
  "password": "messi123"
}
```

### **Perfil de Usuario**
```http
GET /api/users/profile
Authorization: Bearer <token>

PUT /api/users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "firstName": "Lionel",
  "lastName": "Messi",
  "email": "messi@example.com"
}
```

### **Ranking Global**
```http
GET /api/users/ranking/global
Authorization: Bearer <token>
```

## 🏟️ Ligas y Juegos

### **Obtener Ligas**
```http
GET /api/games
GET /api/games?active=true      # Solo ligas activas

GET /api/games/:id              # Liga específica
Authorization: Bearer <token>
```

### **Crear Liga** (Admin)
```http
POST /api/games
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Liga Premier 2025",
  "maxLives": 3,
  "totalWeeks": 4,
  "maxParticipants": 20
}
```

## 🎯 Participaciones y Predicciones

### **Unirse a Liga**
```http
POST /api/participations/join/:gameId
Authorization: Bearer <token>
```

### **Mis Participaciones**
```http
GET /api/participations/user
Authorization: Bearer <token>
```

### **Hacer Predicción**
```http
POST /api/participations/predict
Authorization: Bearer <token>
Content-Type: application/json

{
  "gameId": "64f7b1a2c8d9e1f2a3b4c5d6",
  "week": 1,
  "matchId": "1_1", 
  "selectedTeam": "home"
}
```

### **Estadísticas de Partido**
```http
GET /api/participations/stats/:gameId/:matchId
Authorization: Bearer <token>
```

### **Participantes de Liga**
```http
GET /api/participations/game/:gameId
Authorization: Bearer <token>
```

## 🔔 Notificaciones

### **Obtener Notificaciones**
```http
GET /api/notifications
GET /api/notifications?limit=10&offset=0&unreadOnly=true
Authorization: Bearer <token>
```

### **Contador No Leídas**
```http
GET /api/notifications/unread-count
Authorization: Bearer <token>
```

### **Marcar como Leída**
```http
PUT /api/notifications/:notificationId/read
Authorization: Bearer <token>

PUT /api/notifications/mark-all-read
Authorization: Bearer <token>
```

## 📢 Banners

```http
GET /api/banners                # Banners promocionales
```

## 🔧 Compatibilidad (Prueba Técnica)

### **Rutas Originales Requeridas**
```http
GET  /api/survivor              # → /api/games
POST /api/survivor/join/:id     # → /api/participations/join/:id  
POST /api/survivor/pick         # → /api/participations/predict
```

## 💊 Sistema

```http
GET /api/health                 # Health check
```

## 📊 Respuestas de la API

### **✅ Respuesta Exitosa**
```json
{
  "success": true,
  "data": { ... },
  "message": "Operación exitosa" // Opcional
}
```

### **❌ Respuesta de Error**
```json
{
  "success": false,
  "message": "Descripción del error"
}
```

## 🔐 Autenticación JWT

### **Header Requerido**
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### **Token Payload**
```json
{
  "_id": "64f7b1a2c8d9e1f2a3b4c5d6",
  "username": "messi10",
  "iat": 1693920000,
  "exp": 1694006400
}
```

## 🎮 Flujo de Juego via API

### **1. Autenticación**
```http
POST /api/users/login → Obtener token
```

### **2. Explorar Ligas**
```http
GET /api/games → Ver ligas disponibles
```

### **3. Unirse a Liga**
```http
POST /api/participations/join/:gameId → Crear participación
```

### **4. Hacer Predicciones**
```http
POST /api/participations/predict → Apostar por equipo
```

### **5. Monitorear Progreso**
```http
GET /api/participations/user → Ver mis estadísticas
GET /api/notifications → Ver resultados
GET /api/users/ranking/global → Ver ranking
```

## 🤖 Automatización del Sistema

### **Cron Jobs Activos**
- **Cada 10 segundos**: Verificar y actualizar estado de partidos
- **Cada 1 minuto**: Log completo de estado de todas las ligas
- **Automático**: Generación de resultados 2 minutos después del inicio

### **Estados de Partido**
1. **pending**: Esperando hora de inicio
2. **in_progress**: Partido en curso (2 minutos)
3. **finished**: Partido terminado con resultado

### **Notificaciones Automáticas**
- **Resultado de Partido**: A todos los participantes
- **Predicción Correcta**: +10 puntos
- **Predicción Incorrecta**: -1 vida
- **Eliminación**: Cuando llega a 0 vidas
