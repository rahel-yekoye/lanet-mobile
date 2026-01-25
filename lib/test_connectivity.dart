// Simple test script to verify connectivity
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testConnectivity() async {
  print('Testing internet connectivity...');
  
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✓ Internet connection: OK');
    } else {
      print('✗ Internet connection: FAILED');
      return;
    }
  } on SocketException {
    print('✗ Internet connection: FAILED');
    return;
  }

  print('\nTesting Supabase initialization...');
  try {
    await Supabase.initialize(
      url: 'https://dvjwoggpbhxygrhfraut.supabase.co',
      anonKey: 'sb_publishable_gmm2eBcmqVtPQYgC6ibQJA_zKApKLxv',
    );
    print('✓ Supabase initialization: OK');
  } catch (e) {
    print('✗ Supabase initialization: FAILED - $e');
    return;
  }

  print('\nTesting Supabase authentication endpoint...');
  try {
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    print('✓ Supabase authentication endpoint: Accessible');
  } catch (e) {
    print('✗ Supabase authentication endpoint: FAILED - $e');
  }

  print('\nTest completed!');
}

void main() {
  testConnectivity();
}