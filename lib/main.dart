import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:attendance_app/core/constants/app_constants.dart';
import 'package:attendance_app/core/platform/platform_info.dart';
import 'package:attendance_app/di_container.dart' as di;
import 'package:attendance_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:attendance_app/presentation/pages/auth/splash_page.dart';

/// Punto de entrada principal de la aplicación
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación de la app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inicializar servicios asíncronos en paralelo
  await Future.wait([
    _initializeFirebase(),
    _initializeSupabase(),
    di.init(), // Inicializa la inyección de dependencias
  ]);

  // Ejecutar la aplicación
  runApp(const MyApp());
}

/// Inicializa Firebase para la autenticación
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }
}

/// Inicializa Supabase para la base de datos en la nube
Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Error inicializando Supabase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        // Otros proveedores de BLoC se agregarán aquí
      ],
      child: MaterialApp(
        title: 'Sistema de Asistencia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          colorScheme: const ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.lightBlue,
          ),
        ),
        themeMode: ThemeMode.system,
        home: StreamBuilder<ConnectivityResult>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            // Guardar el estado de conectividad para uso en toda la app
            if (snapshot.hasData) {
              di.sl<PlatformInfo>().updateConnectivity(snapshot.data!);
            }

            return const SplashPage();
          },
        ),
      ),
    );
  }
}
