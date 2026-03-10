import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

/// Firebase Storage Service for Photo Management
/// Handles upload and download of delivery photos
class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Callbacks for upload progress
  Function(double)? onUploadProgress;
  Function(String)? onUploadError;
  Function(String)? onUploadSuccess;

  factory FirebaseStorageService() {
    return _instance;
  }

  FirebaseStorageService._internal();

  /// Upload pickup photo to Firebase Storage
  Future<String?> uploadPickupPhoto({
    required String orderId,
    required String courierId,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'pickup_${timestamp}.jpg';
      final path = 'orders/$orderId/pickup/$filename';

      _logger.i('Uploading pickup photo to: $path');

      final ref = _storage.ref(path);
      final task = ref.putFile(imageFile);

      // Monitor upload progress
      task.snapshotEvents.listen((event) {
        final progress = (event.bytesTransferred / event.totalBytes) * 100;
        _logger.d('Upload progress: ${progress.toStringAsFixed(2)}%');
        onUploadProgress?.call(progress / 100);
      });

      // Wait for upload to complete
      await task;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      _logger.i('Pickup photo uploaded successfully: $downloadUrl');
      onUploadSuccess?.call(downloadUrl);
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error uploading pickup photo: ${e.message}');
      onUploadError?.call(e.message ?? 'Unknown error');
      return null;
    } catch (e) {
      _logger.e('Error uploading pickup photo: $e');
      onUploadError?.call(e.toString());
      return null;
    }
  }

  /// Upload delivery photo to Firebase Storage
  Future<String?> uploadDeliveryPhoto({
    required String orderId,
    required String courierId,
    required File imageFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'delivery_${timestamp}.jpg';
      final path = 'orders/$orderId/delivery/$filename';

      _logger.i('Uploading delivery photo to: $path');

      final ref = _storage.ref(path);
      final task = ref.putFile(imageFile);

      // Monitor upload progress
      task.snapshotEvents.listen((event) {
        final progress = (event.bytesTransferred / event.totalBytes) * 100;
        _logger.d('Upload progress: ${progress.toStringAsFixed(2)}%');
        onUploadProgress?.call(progress / 100);
      });

      // Wait for upload to complete
      await task;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      _logger.i('Delivery photo uploaded successfully: $downloadUrl');
      onUploadSuccess?.call(downloadUrl);
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error uploading delivery photo: ${e.message}');
      onUploadError?.call(e.message ?? 'Unknown error');
      return null;
    } catch (e) {
      _logger.e('Error uploading delivery photo: $e');
      onUploadError?.call(e.toString());
      return null;
    }
  }

  /// Get download URL for a photo
  Future<String?> getDownloadUrl(String path) async {
    try {
      final url = await _storage.ref(path).getDownloadURL();
      _logger.i('Retrieved download URL: $url');
      return url;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error getting URL: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Error getting download URL: $e');
      return null;
    }
  }

  /// Delete a photo from Firebase Storage
  Future<bool> deletePhoto(String path) async {
    try {
      await _storage.ref(path).delete();
      _logger.i('Photo deleted: $path');
      return true;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error deleting photo: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error deleting photo: $e');
      return false;
    }
  }

  /// List all photos for an order
  Future<List<String>> listOrderPhotos(String orderId) async {
    try {
      final result = await _storage.ref('orders/$orderId').listAll();
      final urls = <String>[];

      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      _logger.i('Retrieved ${urls.length} photos for order: $orderId');
      return urls;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error listing photos: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('Error listing photos: $e');
      return [];
    }
  }

  /// Cancel ongoing upload
  void cancelUpload() {
    // Firebase Storage doesn't expose direct cancel, but we can clear callbacks
    onUploadProgress = null;
    onUploadError = null;
    _logger.i('Upload cancelled');
  }
}
