import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../config/supabase_config.dart';

/// Service for uploading media files to Supabase Storage
class MediaUploadService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Upload a file to Supabase Storage
  /// Returns the storage path and signed URL
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String bucketName,
    String? customPath,
  }) async {
    try {
      if (SupabaseConfig.isDemoMode) {
        // Return mock data for demo mode
        return {
          'storage_path': 'demo/$bucketName/${file.path.split('/').last}',
          'signed_url': 'https://example.com/demo-file',
          'file_name': file.path.split('/').last,
          'file_size': await file.length(),
        };
      }

      final fileName = customPath ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storagePath = '$bucketName/$fileName';

      // Upload file
      await _client.storage.from(bucketName).upload(
        fileName,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Get public URL (or generate signed URL)
      final publicUrl = _client.storage.from(bucketName).getPublicUrl(fileName);
      
      // Generate signed URL (valid for 1 hour)
      final signedUrlResponse = await _client.storage
          .from(bucketName)
          .createSignedUrl(fileName, 3600);

      // Save to media_assets table
      final userId = _client.auth.currentUser?.id;
      final fileStat = await file.stat();
      
      final mediaAsset = await _client
          .from('media_assets')
          .insert({
            'storage_path': storagePath,
            'bucket_name': bucketName,
            'file_name': file.path.split('/').last,
            'file_type': _getFileType(file.path),
            'file_size': fileStat.size,
            'mime_type': _getMimeType(file.path),
            'signed_url': signedUrlResponse,
            'url_expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
            'uploaded_by': userId,
          })
          .select()
          .single();

      return {
        'id': mediaAsset['id'],
        'storage_path': storagePath,
        'signed_url': signedUrlResponse,
        'public_url': publicUrl,
        'file_name': file.path.split('/').last,
        'file_size': fileStat.size,
        'mime_type': mediaAsset['mime_type'],
      };
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Pick and upload a file
  static Future<Map<String, dynamic>?> pickAndUpload({
    required String bucketName,
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await uploadFile(
          file: file,
          bucketName: bucketName,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick/upload file: $e');
    }
  }

  /// Delete a file from storage
  static Future<void> deleteFile({
    required String bucketName,
    required String fileName,
  }) async {
    try {
      if (SupabaseConfig.isDemoMode) return;

      await _client.storage.from(bucketName).remove([fileName]);
      
      // Also delete from media_assets table
      await _client
          .from('media_assets')
          .delete()
          .eq('storage_path', '$bucketName/$fileName');
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get signed URL for a file (refresh if expired)
  static Future<String> getSignedUrl({
    required String bucketName,
    required String fileName,
    int expiresIn = 3600,
  }) async {
    try {
      if (SupabaseConfig.isDemoMode) {
        return 'https://example.com/demo-file';
      }

      final signedUrl = await _client.storage
          .from(bucketName)
          .createSignedUrl(fileName, expiresIn);
      
      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  static String _getFileType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) return 'audio';
    if (['mp4', 'mov', 'avi', 'webm'].contains(ext)) return 'video';
    return 'other';
  }

  static String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'm4a': 'audio/mp4',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'webm': 'video/webm',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}

