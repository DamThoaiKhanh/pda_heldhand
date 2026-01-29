import 'package:get_it/get_it.dart';

import '../services/websocket_service.dart';
import '../services/api_service.dart'; // adjust if your api service file name differs

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  // ✅ Register REST service (singleton)
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // ✅ Register WebSocket service (singleton)
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());
}
