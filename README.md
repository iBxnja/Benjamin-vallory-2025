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
# 1. Levantar servicios backend
docker-compose -f backend/docker-compose.dev.yml up -d

# 2. Instalar dependencias mobile
cd mobile
flutter pub get

# 3. Ejecutar app móvil
flutter run
```

### **🚀 Iniciar Desarrollo**

#### **Backend (Docker):**
```bash
docker-compose -f backend/docker-compose.dev.yml up -d
```

#### **Frontend (Flutter):**
```bash
cd mobile
flutter run
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