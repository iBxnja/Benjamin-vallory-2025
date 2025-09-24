# ⚡ Quick Start - Survivor

## 🚀 Instalación en 3 Pasos

### **1️⃣ Levantar Backend**
```bash
docker-compose -f backend/docker-compose.dev.yml up -d
```

### **2️⃣ Instalar Flutter**
```bash
cd mobile
flutter pub get
```

### **3️⃣ Ejecutar App**
```bash
flutter run
```

## ✅ Verificación

### **🔍 Health Check**
```bash
curl http://localhost:4300/api/health
```

### **📊 Servicios Activos**
- **Backend**: http://localhost:4300
- **MongoDB**: localhost:27018
- **Mongo Express**: http://localhost:8081 (admin:pass)

## 🎮 Usuarios de Prueba

```
admin / admin123
messi10 / messi123
ronaldo7 / ronaldo123
neymar11 / neymar123
maradona / diego123
```

## 🛠️ Comandos Esenciales

### **🔄 Reiniciar Backend**
```bash
docker-compose -f backend/docker-compose.dev.yml restart backend
```

### **🧹 Limpiar Base de Datos**
```bash
docker-compose -f backend/docker-compose.dev.yml exec mongo mongosh survivor --eval "db.dropDatabase()"
docker-compose -f backend/docker-compose.dev.yml restart backend
```

### **📱 Flutter Hot Reload**
```bash
# En la terminal donde corre flutter run:
r     # Hot reload
R     # Hot restart
q     # Quit
```

### **🐳 Tumbar Todo**
```bash
docker-compose -f backend/docker-compose.dev.yml down
```

---
