import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/socket_service.dart';
import '../../providers/courier_providers.dart';

/// Pickup Photo Capture Screen
/// Allows courier to capture photo at pickup location and upload to Firebase
class PickupPhotoScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String courierId;

  const PickupPhotoScreen({
    Key? key,
    required this.orderId,
    required this.courierId,
  }) : super(key: key);

  @override
  ConsumerState<PickupPhotoScreen> createState() => _PickupPhotoScreenState();
}

class _PickupPhotoScreenState extends ConsumerState<PickupPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final SocketService _socketService = SocketService();
  final Logger _logger = Logger();

  File? _selectedPhoto;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedPhotoUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupStorageCallbacks();
  }

  /// Setup Firebase Storage callbacks
  void _setupStorageCallbacks() {
    _storageService.onUploadProgress = (progress) {
      setState(() {
        _uploadProgress = progress;
      });
    };

    _storageService.onUploadError = (error) {
      setState(() {
        _errorMessage = 'Upload failed: $error';
        _isUploading = false;
      });
      _logger.e('Upload error: $error');
    };

    _storageService.onUploadSuccess = (url) {
      setState(() {
        _uploadedPhotoUrl = url;
        _isUploading = false;
      });
      _logger.i('Upload successful: $url');
    };
  }

  /// Capture photo using camera
  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedPhoto = File(photo.path);
          _errorMessage = null;
        });
        _logger.i('Photo captured: ${photo.name}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture photo: $e';
      });
      _logger.e('Capture error: $e');
    }
  }

  /// Upload photo to Firebase Storage
  Future<void> _uploadPhoto() async {
    if (_selectedPhoto == null) {
      setState(() {
        _errorMessage = 'Please select a photo first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    _logger.i('Starting photo upload for order: ${widget.orderId}');

    final photoUrl = await _storageService.uploadPickupPhoto(
      orderId: widget.orderId,
      courierId: widget.courierId,
      imageFile: _selectedPhoto!,
    );

    if (photoUrl != null && mounted) {
      // Broadcast photo via Socket.io
      _socketService.broadcastPickupPhoto(
        courierId: widget.courierId,
        orderId: widget.orderId,
        photoUrl: photoUrl,
      );

      _logger.i('Photo uploaded and broadcasted');

      // Show success and navigate to next screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup photo uploaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to delivery tracking or next step
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop({'photoUrl': photoUrl});
        }
      }
    }
  }

  /// Retake photo
  void _retakePhoto() {
    setState(() {
      _selectedPhoto = null;
      _uploadedPhotoUrl = null;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Photo'),
        elevation: 0,
        backgroundColor: Colors.blue[700],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Text(
                'Capture Pickup Photo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo of the item at pickup location',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Photo preview or placeholder
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedPhoto!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _uploadedPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _uploadedPhotoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No photo selected',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Upload progress
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}% Uploading...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Buttons
              if (_selectedPhoto == null && !_isUploading)
                ElevatedButton.icon(
                  onPressed: _capturePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.blue[700],
                  ),
                ),

              if (_selectedPhoto != null && !_isUploading)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploadPhoto,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Photo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _retakePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Retake Photo'),
                    ),
                  ],
                ),

              if (_uploadedPhotoUrl != null && !_isUploading)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Photo uploaded successfully',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop({'photoUrl': _uploadedPhotoUrl}),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.blue[700],
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
