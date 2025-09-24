# 📁 Estructura del Proyecto - Survivor

## 🏗️ Organización General

```
survivor/
├── 📊 backend/                          # Todo el backend contenido aquí
│   ├── 🐳 docker-compose.dev.yml       # Servicios Docker (MongoDB, Mongo Express, Backend)
│   ├── 🐳 Dockerfile                   # Imagen del backend
│   ├── 📝 package.json                 # Dependencias Node.js
│   ├── ⚙️ tsconfig.json                # Configuración TypeScript
│   ├── 🔧 env.example                  # Ejemplo de variables de entorno
│   │
│   ├── 🎮 controllers/                 # Controladores de rutas API
│   │   ├── UserController.ts           # Autenticación y perfiles
│   │   ├── GameController.ts           # CRUD de ligas
│   │   ├── ParticipationController.ts  # Participaciones y predicciones
│   │   ├── NotificationController.ts   # Sistema de notificaciones
│   │   └── BannerController.ts         # Banners promocionales
│   │
│   ├── 💾 models/                      # Esquemas MongoDB (Mongoose)
│   │   ├── User.ts                     # Usuarios
│   │   ├── Game.ts                     # Ligas con jornadas
│   │   ├── Participation.ts            # Participaciones
│   │   ├── Notification.ts             # Notificaciones
│   │   └── Banner.ts                   # Banners
│   │
│   ├── 🚦 routes/                      # Definición de rutas
│   │   ├── userRoutes.ts               # /api/users/*
│   │   ├── gameRoutes.ts               # /api/games/*
│   │   ├── participationRoutes.ts      # /api/participations/*
│   │   ├── notificationRoutes.ts       # /api/notifications/*
│   │   ├── bannerRoutes.ts             # /api/banners/*
│   │   └── survivorRoutes.ts           # /api/survivor/* (compatibilidad)
│   │
│   ├── ⚙️ services/                    # Lógica de negocio
│   │   ├── UserService.ts              # Gestión de usuarios
│   │   ├── GameService.ts              # Gestión de ligas
│   │   ├── ParticipationService.ts     # Gestión de participaciones
│   │   ├── NotificationService.ts      # Gestión de notificaciones
│   │   ├── MatchAutomationService.ts   # 🤖 Automatización de partidos
│   │   └── BannerService.ts            # Gestión de banners
│   │
│   ├── 🔐 middleware/                  # Middlewares de seguridad
│   │   ├── auth.ts                     # Autenticación JWT
│   │   └── validation.ts               # Validaciones de entrada
│   │
│   ├── 🌱 seeds/                       # Datos de prueba
│   │   └── seedData.ts                 # Seeding con jornadas
│   │
│   ├── 📝 types/dto/                   # Tipos TypeScript
│   │   ├── UserDto.ts                  # DTOs de usuario
│   │   ├── GameDto.ts                  # DTOs de juego
│   │   └── ParticipationDto.ts         # DTOs de participación
│   │
│   ├── 📁 dist/                        # Código compilado (generado)
│   └── 🚀 server.ts                    # Punto de entrada principal
│
├── 📱 mobile/                          # Aplicación Flutter
│   ├── 📱 lib/                         # Código fuente Dart
│   │   ├── screens/                    # Pantallas de la aplicación
│   │   │   ├── auth/                   # Login y registro
│   │   │   ├── home/                   # Pantalla principal con tabs
│   │   │   ├── games/                  # Ligas, partidos y predicciones
│   │   │   ├── profile/                # Perfil y ranking
│   │   │   ├── notifications/          # Sistema de notificaciones
│   │   │   └── splash_screen.dart      # Pantalla de carga
│   │   │
│   │   ├── providers/                  # Gestión de estado (Provider)
│   │   │   ├── auth_provider.dart      # Estado de autenticación
│   │   │   ├── game_provider.dart      # Estado de juegos
│   │   │   ├── participation_provider.dart # Estado de participaciones
│   │   │   └── banner_provider.dart    # Estado de banners
│   │   │
│   │   ├── models/                     # Modelos de datos Flutter
│   │   │   ├── user.dart               # Modelo de usuario
│   │   │   ├── game.dart               # Modelo de liga
│   │   │   ├── match.dart              # Modelo de partido
│   │   │   ├── participation.dart      # Modelo de participación
│   │   │   ├── prediction.dart         # Modelo de predicción
│   │   │   ├── team.dart               # Modelo de equipo
│   │   │   └── banner.dart             # Modelo de banner
│   │   │
│   │   ├── services/                   # Cliente HTTP
│   │   │   └── api_service.dart        # Todas las llamadas a la API
│   │   │
│   │   ├── config/                     # Configuración
│   │   │   └── app_config.dart         # URLs y configuración base
│   │   │
│   │   └── main.dart                   # Punto de entrada Flutter
│   │
│   ├── 🖼️ assets/                      # Recursos estáticos
│   │   ├── image1.jpg                  # Liga Premier
│   │   ├── iamge2.jpg                  # La Liga  
│   │   ├── image3.jpeg                 # Champions League
│   │   └── image4.jpg                  # Default
│   │
│   ├── 📦 pubspec.yaml                 # Dependencias Flutter
│   ├── 🤖 android/                     # Configuración Android
│   ├── 🍎 ios/                         # Configuración iOS
│   ├── 🌐 web/                         # Configuración Web
│   └── 💻 windows/                     # Configuración Windows
│
├── 📚 Documentación
│   ├── README.md                       # Documentación principal
│   ├── API.md                          # Documentación completa de API
│   ├── COMANDOS.md                     # Comandos útiles
│   ├── ESTRUCTURA.md                   # Este archivo
│   └── pruebaTecnicaPenka.md           # Prueba técnica original
│
└── 📄 Prueba Técnica Penka.pdf         # Documento original de la prueba
```

## 🎯 Decisiones de Arquitectura

### **📊 ¿Por qué Backend Autocontenido?**
- ✅ **Separación clara**: Todo lo relacionado al backend en un directorio
- ✅ **Docker compose local**: Servicios del backend juntos
- ✅ **Despliegue independiente**: Backend puede desplegarse solo
- ✅ **Escalabilidad**: Fácil añadir microservicios

### **📱 ¿Por qué Mobile Separado?**
- ✅ **Tecnología diferente**: Flutter vs Node.js
- ✅ **Equipos diferentes**: Frontend vs Backend devs
- ✅ **Build independiente**: Ciclos de desarrollo separados
- ✅ **Deploy diferente**: App stores vs servidores

### **📚 ¿Por qué Documentación en la Raíz?**
- ✅ **Acceso fácil**: Documentación visible desde el inicio
- ✅ **Comandos claros**: Instrucciones directas sin scripts
- ✅ **Cross-platform**: Comandos que funcionan en cualquier OS
- ✅ **Flexibilidad**: Cada desarrollador puede adaptar según su entorno

## 🔄 Flujo de Desarrollo

### **1. Instalación Inicial**
```bash
# 1. Levantar backend con Docker
docker-compose -f backend/docker-compose.dev.yml up -d

# 2. Instalar dependencias Flutter
cd mobile && flutter pub get

# 3. Verificar que todo funciona
curl http://localhost:4300/api/health
```

### **2. Desarrollo Diario**
```bash
# Backend (Docker)
docker-compose -f backend/docker-compose.dev.yml up -d

# Frontend (Flutter)
cd mobile && flutter run
```

### **3. Gestión de Base de Datos**
```bash
# Limpiar DB y reiniciar
docker-compose -f backend/docker-compose.dev.yml exec mongo mongosh survivor --eval "db.dropDatabase()"
docker-compose -f backend/docker-compose.dev.yml restart backend
```

## 📦 Puertos y Servicios

### **🚀 Servicios Backend:**
- **Backend API**: http://localhost:4300
- **MongoDB**: localhost:27018 
- **Mongo Express**: http://localhost:8081 (admin:pass)

### **📱 Frontend:**
- **Flutter Dev**: Se define al ejecutar `flutter run`
- **Flutter Web**: http://localhost:3000 (si se usa web)

## 🎯 Beneficios de Esta Estructura

### **👨‍💻 Para Desarrolladores:**
- ✅ **Separación clara** de responsabilidades
- ✅ **Docker autocontenido** para backend
- ✅ **Scripts automatizados** para setup
- ✅ **Documentación completa** de cada parte

### **🚀 Para Despliegue:**
- ✅ **Backend independiente** con Docker
- ✅ **Mobile builds** separados por plataforma
- ✅ **Configuración centralizada** por servicio
- ✅ **Escalabilidad** horizontal

### **📚 Para Mantenimiento:**
- ✅ **Código organizado** por responsabilidad
- ✅ **Dependencias claras** entre servicios
- ✅ **Documentación actualizada** automáticamente
- ✅ **Scripts de limpieza** incluidos

---

