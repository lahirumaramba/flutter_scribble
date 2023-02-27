// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scribble/blocs/app_cubit.dart';
import 'package:flutter_scribble/firebase_options.dart';
import 'package:flutter_scribble/repository/prediction_repo.dart';
import 'package:flutter_scribble/services/backend_service.dart';
import 'package:flutter_scribble/ui/home/home_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_scribble/ui/result/result_page.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await injectDependencies();

  // if (kDebugMode) {
  //   try {
  //     FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  //     FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  //   } catch (e) {
  //     // ignore: avoid_print
  //     print(e);
  //   }
  // }

  runApp(
    BlocProvider(
      create: (_) => AppCubit()..init(),
      child: const MyApp(),
    ),
  );
}

Future<void> injectDependencies() async {
  getIt.registerLazySingleton<PredictionRepository>(
      () => PredictionRepositoryImpl());
  getIt.registerLazySingleton<BackendService>(() => BackendServiceImpl());
}

// GoRouter configuration
final _router = GoRouter(
  routes: [
    GoRoute(
        path: '/',
        builder: (context, state) =>
            const HomePage(title: 'Scribble Diffusion with Flutter'),
        routes: [
          GoRoute(
            path: 'share/:id',
            builder: (context, state) =>
                ResultPage(id: state.params['id'] ?? ''),
          )
        ]),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '🐦🖼️ Flutter Scribble',
      theme: ThemeData(
        primaryColorDark: Colors.blueGrey,
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      routerConfig: _router,
    );
  }
}
