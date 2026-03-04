import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:go_router/go_router.dart';

import 'role.dart';
import 'server/server_app.dart';
import 'client/client_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1500, 950), // The starting size of the app
    minimumSize: Size(1500, 950), // Prevents users from resizing it too small
    center: true, // Opens the app in the middle of the screen
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Federated Fraud Detection',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const RoleSelect();
      },
    ),
    GoRoute(
      path: '/server', 
      builder: (BuildContext context, GoRouterState state) {
        return const ServerApp();
      },
    ),
    GoRoute(
      path: '/client', 
      builder: (BuildContext context, GoRouterState state) {
        return const ClientApp();
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
