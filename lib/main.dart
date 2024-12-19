import 'package:flutter/material.dart';
import 'package:liveliness_checker/camera_screen.dart';
import 'package:provider/provider.dart';

import 'view_model/camera_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
    create: (_) => CameraViewModel(),
    child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CameraPage(),
    );
  }
}