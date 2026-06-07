import 'package:flutter/material.dart';
import 'package:tetris/ad_service.dart';
import 'board.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Ads BEFORE the app starts
  // This ensures the "busy period" happens during the splash screen
  // instead of during the first few seconds of gameplay.
  await AdService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameBoard()
    );
  }
}