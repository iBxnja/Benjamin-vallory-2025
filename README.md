# 🏆 Survivor - Aplicación de Predicciones Deportivas

Una aplicación fullstack para un juego de supervivencia basado en predicciones deportivas, donde los jugadores deben elegir equipos ganadores para sobrevivir el mayor tiempo posible.

## 🚀 Características Principales

### 🎯 **Sistema de Juego**
- **Modo Survivor**: Supervivencia por eliminación progresiva
- **Sistema de Vidas**: 3 vidas por jugador, pierdes 1 por predicción incorrecta
- **Puntos por Acierto**: 10 puntos por predicción correcta
- **Jornadas Organizadas**: Cada liga tiene múltiples jornadas con 3 partidos cada una
- **Automatización**: Partidos se ejecutan automáticamente en tiempo real

### 🔄 **Tiempo Real**
- **Countdown Timers**: Tiempo restante hasta cada partido
- **Estados Dinámicos**: pending → in_progress → finished
- **Automatización**: Sistema cron que maneja todo automáticamente
- **Notificaciones**: Sistema completo de notificaciones push

### 📱 **Características Premium**
- **Sistema de Ranking**: Ranking global de usuarios
- **Perfiles Completos**: Estadísticas detalladas por usuario
- **Liga Completada**: Ligas se desactivan automáticamente al terminar
- **Pull-to-Refresh**: Actualización manual en todas las pantallas
- **Navegación por Jornadas**: Selector visual de jornadas

## 🛠️ Instalación y Configuración

### **📋 Prerrequisitos**
- **Docker & Docker Compose**
- **Flutter SDK** (v3.7+)
- **Git**

### **⚡ Instalación Rápida**

#### **🐳 Con Docker (Recomendado):**
```bash
# 1. Clonar el repositorio
git clone <tu-repositorio>
cd survivor

# 2. Construir y levantar servicios backend (MongoDB + Backend)
docker-compose -f backend/docker-compose.dev.yml up -d --build

# 3. Esperar a que se complete el seeding (30-60 segundos)
# Ver logs: docker-compose -f backend/docker-compose.dev.yml logs -f backend

# 4. Instalar dependencias mobile
cd mobile
flutter pub get

# 5. Ejecutar app móvil
flutter run
```

### **🚀 Iniciar Desarrollo**

#### **Backend (Docker):**
```bash
# Construir y levantar servicios
docker-compose -f backend/docker-compose.dev.yml up -d --build

# Solo levantar servicios (si ya están construidos)
docker-compose -f backend/docker-compose.dev.yml up -d

# Ver logs en tiempo real
docker-compose -f backend/docker-compose.dev.yml logs -f backend

# Reiniciar solo el backend
docker-compose -f backend/docker-compose.dev.yml restart backend

# Parar servicios
docker-compose -f backend/docker-compose.dev.yml down
```

#### **Frontend (Flutter):**
```bash
cd mobile

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release

# Limpiar y reinstalar
flutter clean
flutter pub get
```

### **🔄 Comandos Útiles**

#### **Base de Datos:**
```bash
# Ver logs de MongoDB
docker-compose -f backend/docker-compose.dev.yml logs mongo

# Acceder a MongoDB Express (Web UI)
# Abrir: http://localhost:8081

# Reiniciar solo MongoDB
docker-compose -f backend/docker-compose.dev.yml restart mongo
```

#### **Desarrollo:**
```bash
# Ver estado de contenedores
docker-compose -f backend/docker-compose.dev.yml ps

# Construir solo el backend
docker-compose -f backend/docker-compose.dev.yml build backend

# Construir y levantar todo
docker-compose -f backend/docker-compose.dev.yml up -d --build

# Ver logs de todos los servicios
docker-compose -f backend/docker-compose.dev.yml logs
```

### **📝 Configuración de Entorno**

Crear `backend/.env` basado en `backend/env.example`:
```env
MONGO_URI=mongodb://localhost:27018/survivor
PORT=4300
NODE_ENV=development
JWT_SECRET=your-super-secret-jwt-key-here
FRONTEND_URL=http://localhost:3000
```

### **🔧 Troubleshooting**

#### **Problemas Comunes:**

**❌ Error: "Port already in use"**
```bash
# Verificar qué está usando el puerto
netstat -ano | findstr :4300
# O en Linux/Mac:
lsof -i :4300

# Parar servicios Docker
docker-compose -f backend/docker-compose.dev.yml down
```

**❌ Error: "MongoDB connection failed"**
```bash
# Verificar que MongoDB esté corriendo
docker-compose -f backend/docker-compose.dev.yml ps

# Reiniciar MongoDB
docker-compose -f backend/docker-compose.dev.yml restart mongo
```

**❌ Error: "Flutter dependencies not found"**
```bash
cd mobile
flutter clean
flutter pub get
```

**❌ Error: "Backend not responding"**
```bash
# Ver logs del backend
docker-compose -f backend/docker-compose.dev.yml logs backend

# Reiniciar backend
docker-compose -f backend/docker-compose.dev.yml restart backend
```

#### **Reset Completo:**
```bash
# Parar todos los servicios
docker-compose -f backend/docker-compose.dev.yml down

# Eliminar volúmenes (CUIDADO: borra la base de datos)
docker-compose -f backend/docker-compose.dev.yml down -v

# Reconstruir y levantar
docker-compose -f backend/docker-compose.dev.yml up -d --build
```

### **🌐 URLs y Puertos**

| Servicio | URL | Puerto | Descripción |
|----------|-----|--------|-------------|
| **Backend API** | http://localhost:4300 | 4300 | API REST del juego |
| **MongoDB** | mongodb://localhost:27018 | 27018 | Base de datos |
| **MongoDB Express** | http://localhost:8081 | 8081 | Interfaz web de MongoDB |
| **Flutter App** | - | - | App móvil (debug/release) |

### **📱 Usuarios de Prueba**

El sistema se inicializa automáticamente con estos usuarios:

| Correo Electrónico | Contraseña | Vidas | Descripción |
|-------------------|------------|-------|-------------|
| `messi10@test.com` | `123456` | 1 | Usuario con 1 vida para testing |
| `ronaldo7@test.com` | `123456` | 3 | Usuario estándar |
| `neymar11@test.com` | `123456` | 3 | Usuario estándar |
| `mbappe9@test.com` | `123456` | 3 | Usuario estándar |
| `admin@test.com` | `admin123` | 3 | Administrador |

## 📁 Estructura del Proyecto

```
survivor/
├── 📊 backend/                          # Todo el backend autocontenido
│   ├── 🐳 docker-compose.dev.yml       # Servicios Docker
│   ├── 🐳 Dockerfile                   # Imagen del backend
│   ├── controllers/, models/, routes/  # Arquitectura API
│   ├── services/, middleware/          # Lógica y seguridad
│   └── seeds/, types/                  # Datos y tipos
│
├── 📱 mobile/                          # App Flutter
│   ├── lib/screens/                    # Pantallas
│   ├── lib/providers/                  # Estado (Provider)
│   ├── lib/models/                     # Modelos
│   ├── lib/services/                   # API calls
│   └── assets/                         # Imágenes
│
└── 📚 Documentación
    ├── README.md                       # Esta guía
    ├── QUICKSTART.md                   # Instalación rápida
    ├── API.md                          # Endpoints completos
    ├── COMANDOS.md                     # Comandos útiles
    └── ESTRUCTURA.md                   # Arquitectura detallada
```