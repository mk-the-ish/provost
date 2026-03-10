import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

/// FirebaseStorageService handles photo uploads for proof of delivery
/// Uses Firebase Storage's free tier (1 GB/month)
class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();

  factory FirebaseStorageService() {
    return _instance;
  }

  FirebaseStorageService._internal();

  final _storage = FirebaseStorage.instance;
  final _logger = Logger();

  /// Upload pickup photo
  /// Returns the Firebase Storage URL
  Future<String?> uploadPickupPhoto(
    String orderId,
    String courierId,
    File imageFile,
  ) async {
    try {
      _logger.i('📷 Uploading pickup photo for order: $orderId');

      final fileName = 'pickup_${orderId}_${courierId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('orders/$orderId/pickup/$fileName');

      // Upload file
      final uploadTask = ref.putFile(imageFile);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        _logger.d('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      _logger.i('✅ Pickup photo uploaded: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error uploading photo: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Error uploading photo: $e');
      return null;
    }
  }

  /// Upload delivery photo
  /// Returns the Firebase Storage URL
  Future<String?> uploadDeliveryPhoto(
    String orderId,
    String courierId,
    File imageFile,
  ) async {
    try {
      _logger.i('📷 Uploading delivery photo for order: $orderId');

      final fileName = 'delivery_${orderId}_${courierId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('orders/$orderId/delivery/$fileName');

      // Upload file
      final uploadTask = ref.putFile(imageFile);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        _logger.d('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      _logger.i('✅ Delivery photo uploaded: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error uploading photo: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Error uploading photo: $e');
      return null;
    }
  }

  /// Delete a photo from Firebase Storage
  Future<bool> deletePhoto(String storagePath) async {
    try {
      _logger.i('🗑️ Deleting photo: $storagePath');

      final ref = _storage.refFromURL(storagePath);
      await ref.delete();

      _logger.i('✅ Photo deleted successfully');
      return true;
    } on FirebaseException catch (e) {
      _logger.e('Firebase error deleting photo: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error deleting photo: $e');
      return false;
    }
  }

  /// Get download URL for a photo
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.refFromURL(storagePath);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _logger.e('Error getting download URL: $e');
      return null;
    }
  }
}

