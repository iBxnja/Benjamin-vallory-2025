# 🛠️ Comandos Útiles - Survivor

## 🐳 Docker Commands

### **Iniciar Sistema:**
```bash
# Levantar todo
docker-compose -f backend/docker-compose.dev.yml up -d

# Ver logs en tiempo real
docker-compose -f backend/docker-compose.dev.yml logs -f backend

# Ver estado de contenedores
docker-compose -f backend/docker-compose.dev.yml ps
```

### **Gestión de Base de Datos:**
```bash
# Limpiar base de datos completamente
docker-compose -f backend/docker-compose.dev.yml exec mongo mongosh survivor --eval "db.dropDatabase()"

# Conectar a MongoDB
docker-compose -f backend/docker-compose.dev.yml exec mongo mongosh survivor

# Ver datos en Mongo Express: http://localhost:8081 (admin:pass)
```

### **Restart y Rebuild:**
```bash
# Reiniciar backend solamente
docker-compose -f backend/docker-compose.dev.yml restart backend

# Rebuild completo
docker-compose -f backend/docker-compose.dev.yml down
docker-compose -f backend/docker-compose.dev.yml up --build -d

# Limpiar todo y empezar de cero
docker-compose -f backend/docker-compose.dev.yml down -v
docker system prune -f
docker-compose -f backend/docker-compose.dev.yml up --build -d
```

## 📱 Flutter Commands

### **Desarrollo:**
```bash
cd mobile

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter devices
flutter run -d android
flutter run -d chrome
```

### **Build:**
```bash
# Android APK
flutter build apk --release

# Android Bundle
flutter build appbundle --release

# Web
flutter build web --release
```

## 🔧 Backend Commands

### **Desarrollo:**
```bash
cd backend

# Instalar dependencias
npm install

# Compilar TypeScript
npm run build

# Ejecutar en desarrollo
npm run dev

# Ejecutar en producción
npm start
```

## 🧹 Limpieza

### **Limpiar Cache:**
```bash
# Flutter
cd mobile
flutter clean
flutter pub get

# Docker
docker system prune -f
docker volume prune -f
```

### **Resetear Completamente:**
```bash
# 1. Tumbar servicios
docker-compose -f backend/docker-compose.dev.yml down -v

# 2. Limpiar Docker
docker system prune -f

# 3. Limpiar Flutter
cd mobile && flutter clean && cd ..

# 4. Reinstalar
docker-compose -f backend/docker-compose.dev.yml up --build -d
cd mobile && flutter pub get
```

## 📊 Monitoreo

### **URLs de Servicios:**
- **Backend API**: http://localhost:4300
- **Health Check**: http://localhost:4300/api/health
- **Mongo Express**: http://localhost:8081 (admin:pass)
- **MongoDB**: localhost:27018

### **Estado de Partidos:**
Los logs del backend muestran cada minuto el estado completo de todas las ligas y partidos.

## 🎯 Datos de Prueba

### **Usuarios:**
- admin / admin123
- messi10 / messi123
- ronaldo7 / ronaldo123
- neymar11 / neymar123
- maradona / diego123

### **Seeding:**
El sistema crea automáticamente:
- 2 ligas con 4 jornadas cada una
- 3 partidos por jornada (12 partidos totales por liga)
- 5 usuarios de prueba
- Banners promocionales
