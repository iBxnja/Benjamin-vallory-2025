class AppConfig {
  // URL base de la API
  // Para emulador Android: 10.0.2.2 apunta al localhost del host
  // Para dispositivo físico: usar la IP real de tu máquina
  static const String apiBaseUrl = 'http://10.0.2.2:4300/api';
  
  // Configuración de la aplicación
  static const String appName = 'Survivor';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos
  
  // URLs específicas
  static String get loginUrl => '$apiBaseUrl/users/login';
  static String get registerUrl => '$apiBaseUrl/users/register';
  static String get gamesUrl => '$apiBaseUrl/games';
  static String get participationsUrl => '$apiBaseUrl/participations';
}
