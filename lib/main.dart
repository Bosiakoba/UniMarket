import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/util/web_loader.dart';
import 'core/api/api_client.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize API Cache
  await ApiClient.initCache();
  
  // Set preferred orientations for web to allow all orientations
  if (kIsWeb) {
    // Web-specific configurations
  } else {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // Lock orientation to portrait for mobile
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  runApp(const UniMarketApp());

  // Remove the HTML loading spinner once the first frame is drawn
  WidgetsBinding.instance.addPostFrameCallback((_) {
    removeWebLoader();
  });
}
