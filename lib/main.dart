import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/auth_viewmodel.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/viewmodels/notification_viewmodel.dart';
import 'package:pda_handheld/views/splash_screen.dart';
import 'package:pda_handheld/services/storage_service.dart';
import 'package:pda_handheld/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(ApiService(), StorageService()),
        ),
        ChangeNotifierProvider(create: (_) => OrderViewModel(ApiService())),
        ChangeNotifierProvider(create: (_) => RobotViewModel(ApiService())),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: MaterialApp(
        title: 'PDA v1.0.0',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
