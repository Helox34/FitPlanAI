import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get openRouterApiKey => 
      dotenv.env['OPENROUTER_API_KEY'] ?? '';
  
  static bool get hasApiKey => openRouterApiKey.isNotEmpty;
}
