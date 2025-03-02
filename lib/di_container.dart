import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:camera/camera.dart';

// Core
import 'package:attendance_app/core/network/network_info.dart';
import 'package:attendance_app/core/network/supabase_client_app.dart';
import 'package:attendance_app/core/platform/platform_info.dart';

// Data sources
import 'package:attendance_app/data/datasources/local/database_helper.dart';
import 'package:attendance_app/data/datasources/local/attendance_local_data_source.dart';
import 'package:attendance_app/data/datasources/local/auth_local_data_source.dart';
import 'package:attendance_app/data/datasources/local/location_local_data_source.dart';
import 'package:attendance_app/data/datasources/local/user_local_data_source.dart';
import 'package:attendance_app/data/datasources/remote/attendance_remote_data_source.dart';
import 'package:attendance_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:attendance_app/data/datasources/remote/location_remote_data_source.dart';
import 'package:attendance_app/data/datasources/remote/user_remote_data_source.dart';

// Repositories
import 'package:attendance_app/domain/repositories/attendance_repository.dart';
import 'package:attendance_app/domain/repositories/auth_repository.dart';
import 'package:attendance_app/domain/repositories/location_repository.dart';
import 'package:attendance_app/domain/repositories/user_repository.dart';
import 'package:attendance_app/data/repositories/attendance_repository_impl.dart';
import 'package:attendance_app/data/repositories/auth_repository_impl.dart';
import 'package:attendance_app/data/repositories/location_repository_impl.dart';
import 'package:attendance_app/data/repositories/user_repository_impl.dart';

// Use cases
// Auth
import 'package:attendance_app/domain/usecases/auth/get_current_user.dart';
import 'package:attendance_app/domain/usecases/auth/login_with_email.dart';
import 'package:attendance_app/domain/usecases/auth/login_with_google.dart';
import 'package:attendance_app/domain/usecases/auth/logout.dart';
// User
import 'package:attendance_app/domain/usecases/user/add_user.dart';
import 'package:attendance_app/domain/usecases/user/get_users.dart';
import 'package:attendance_app/domain/usecases/user/update_user.dart';
// Location
import 'package:attendance_app/domain/usecases/location/add_location.dart';
import 'package:attendance_app/domain/usecases/location/get_locations.dart';
import 'package:attendance_app/domain/usecases/location/update_location.dart';
// Attendance
import 'package:attendance_app/domain/usecases/attendance/create_attendance_record.dart';
import 'package:attendance_app/domain/usecases/attendance/get_attendance_records.dart';
import 'package:attendance_app/domain/usecases/attendance/generate_attendance_report.dart';
import 'package:attendance_app/domain/usecases/attendance/validate_attendance_location.dart';

// Blocs
import 'package:attendance_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:attendance_app/presentation/bloc/user/user_bloc.dart';
import 'package:attendance_app/presentation/bloc/location/location_bloc.dart';
import 'package:attendance_app/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:attendance_app/presentation/bloc/report/report_bloc.dart';

// Services
import 'package:attendance_app/services/face_recognition_service.dart';
import 'package:attendance_app/services/geolocation_service.dart';
import 'package:attendance_app/services/pdf_service.dart';
import 'package:attendance_app/services/report_service.dart';
import 'package:attendance_app/services/storage_service.dart';

/// Service Locator global
final sl = GetIt.instance;

/// Inicializa todas las dependencias del sistema
Future<void> init() async {
  //! Features

  //! BLoCs
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      loginWithEmail: sl(),
      loginWithGoogle: sl(),
      logout: sl(),
    ),
  );

  sl.registerFactory(
    () => UserBloc(
      getUsers: sl(),
      addUser: sl(),
      updateUser: sl(),
    ),
  );

  sl.registerFactory(
    () => LocationBloc(
      getLocations: sl(),
      addLocation: sl(),
      updateLocation: sl(),
    ),
  );

  sl.registerFactory(
    () => AttendanceBloc(
      createAttendanceRecord: sl(),
      getAttendanceRecords: sl(),
      validateAttendanceLocation: sl(),
      faceRecognitionService: sl(),
    ),
  );

  sl.registerFactory(
    () => ReportBloc(
      generateAttendanceReport: sl(),
      reportService: sl(),
    ),
  );

  //! Use cases
  // Auth
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => LoginWithEmail(sl()));
  sl.registerLazySingleton(() => LoginWithGoogle(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  // User
  sl.registerLazySingleton(() => GetUsers(sl()));
  sl.registerLazySingleton(() => AddUser(sl()));
  sl.registerLazySingleton(() => UpdateUser(sl()));

  // Location
  sl.registerLazySingleton(() => GetLocations(sl()));
  sl.registerLazySingleton(() => AddLocation(sl()));
  sl.registerLazySingleton(() => UpdateLocation(sl()));

  // Attendance
  sl.registerLazySingleton(() => CreateAttendanceRecord(sl()));
  sl.registerLazySingleton(() => GetAttendanceRecords(sl()));
  sl.registerLazySingleton(() => GenerateAttendanceReport(sl()));
  sl.registerLazySingleton(() => ValidateAttendanceLocation(sl()));

  //! Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  //! Data sources
  // Remote
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(supabaseClient: sl()),
  );

  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(supabaseClient: sl()),
  );

  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Local
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<LocationLocalDataSource>(
    () => LocationLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSourceImpl(databaseHelper: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(connectivity: sl()));
  sl.registerLazySingleton<SupabaseClientApp>(() => SupabaseClientImpl());
  sl.registerLazySingleton<PlatformInfo>(() => PlatformInfoImpl());

  //! Database
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  //! Services
  sl.registerLazySingleton<FaceRecognitionService>(
      () => FaceRecognitionServiceImpl());
  sl.registerLazySingleton<GeolocationService>(() => GeolocationServiceImpl());
  sl.registerLazySingleton<PdfService>(() => PdfServiceImpl());
  sl.registerLazySingleton<ReportService>(
      () => ReportServiceImpl(pdfService: sl()));
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => Connectivity());

  // Inicializar cámaras disponibles
  try {
    final cameras = await availableCameras();
    sl.registerLazySingleton(() => cameras);
  } catch (e) {
    sl.registerLazySingleton<List<CameraDescription>>(() => []);
    debugPrint('No se pudieron inicializar las cámaras: $e');
  }
}
