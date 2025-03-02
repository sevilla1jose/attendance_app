/// Contiene todas las constantes utilizadas en la aplicación
class AppConstants {
  // Supabase
  static const String supabaseUrl = 'https://your-supabase-url.supabase.co';
  static const String supabaseAnonKey = 'your-supabase-anon-key';

  // Tablas de Supabase
  static const String usersTable = 'users';
  static const String locationsTable = 'locations';
  static const String attendanceTable = 'attendance_records';

  // Rutas de almacenamiento
  static const String profileImagesBucket = 'profile_images';
  static const String signaturesBucket = 'signatures';
  static const String attendancePhotosBucket = 'attendance_photos';

  // Configuración de geolocalización
  static const int maxLocationAgeInMinutes = 1;
  static const double locationAccuracyInMeters = 50.0;
  static const int locationValidityRadiusInMeters = 100;

  // Tiempos de espera
  static const int networkTimeoutInSeconds = 30;
  static const int databaseQueryTimeoutInSeconds = 10;

  // Roles de usuario
  static const String roleAdmin = 'admin';
  static const String roleSupervisor = 'supervisor';
  static const String roleAssistant = 'assistant';

  // Tipos de registro de asistencia
  static const String checkInType = 'check_in';
  static const String checkOutType = 'check_out';
  static const String lunchOutType = 'lunch_out';
  static const String lunchInType = 'lunch_in';

  // Configuración de la base de datos local
  static const String databaseName = 'attendance_app.db';
  static const int databaseVersion = 1;

  // Formatos de fecha
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Configuración de reconocimiento facial
  static const double faceMatchThreshold = 0.9; // 90% de confianza

  // Configuración de sincronización
  static const int syncIntervalInMinutes = 15;

  // Mensajes de error
  static const String networkErrorMessage =
      'No hay conexión a internet. Los datos se guardarán localmente y se sincronizarán cuando vuelva la conexión.';
  static const String locationErrorMessage =
      'No se pudo obtener la ubicación. Verifica que el GPS esté activado y que tengas permisos de ubicación.';
  static const String cameraErrorMessage =
      'No se pudo acceder a la cámara. Verifica que tengas permisos de cámara.';
  static const String authErrorMessage =
      'Error de autenticación. Por favor, inicia sesión nuevamente.';
  static const String faceRecognitionErrorMessage =
      'No se pudo verificar la identidad. Por favor, intenta nuevamente con mejor iluminación.';
  static const String generalErrorMessage =
      'Ocurrió un error. Por favor, intenta nuevamente.';

  // Claves para SharedPreferences
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String lastSyncTimeKey = 'last_sync_time';
  static const String themePreferenceKey = 'theme_preference';
  static const String onboardingCompletedKey = 'onboarding_completed';
}
