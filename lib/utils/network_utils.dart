// lib/utils/network_utils.dart
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkUtils {
  /// Test basic internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final response =
          await http.get(Uri.parse('https://www.google.com/generate_204'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Test Supabase connection
  static Future<bool> canConnectToSupabase() async {
    try {
      final response =
          await http.get(Uri.parse('https://www.google.com/generate_204'));
      return response.statusCode == 200;
    } catch (e) {
      print('Cannot connect to Supabase: $e');
      return false;
    }
  }
}
