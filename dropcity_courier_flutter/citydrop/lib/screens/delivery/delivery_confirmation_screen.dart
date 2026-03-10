import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/socket_service.dart';
import '../../providers/courier_providers.dart';

/// Delivery Confirmation Screen
/// Allows courier to enter delivery PIN and upload delivery proof photo
class DeliveryConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String courierId;
  final String deliveryPin;

  const DeliveryConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.courierId,
    required this.deliveryPin,
  }) : super(key: key);

  @override
  ConsumerState<DeliveryConfirmationScreen> createState() =>
      _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState
    extends ConsumerState<DeliveryConfirmationScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final SocketService _socketService = SocketService();
  final Logger _logger = Logger();

  File? _deliveryPhoto;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedPhotoUrl;
  String? _errorMessage;
  bool _photoRequired = true;

  int _currentStep = 0; // 0: Capture Photo, 1: Verify PIN

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

  /// Capture delivery photo
  Future<void> _captureDeliveryPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _deliveryPhoto = File(photo.path);
          _errorMessage = null;
        });
        _logger.i('Delivery photo captured: ${photo.name}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture photo: $e';
      });
      _logger.e('Capture error: $e');
    }
  }

  /// Upload delivery photo
  Future<void> _uploadDeliveryPhoto() async {
    if (_deliveryPhoto == null) {
      setState(() {
        _errorMessage = 'Please capture a photo first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    _logger.i('Uploading delivery photo for order: ${widget.orderId}');

    final photoUrl = await _storageService.uploadDeliveryPhoto(
      orderId: widget.orderId,
      courierId: widget.courierId,
      imageFile: _deliveryPhoto!,
    );

    if (photoUrl != null && mounted) {
      // Broadcast photo via Socket.io
      _socketService.broadcastDeliveryPhoto(
        courierId: widget.courierId,
        orderId: widget.orderId,
        photoUrl: photoUrl,
      );

      _logger.i('Delivery photo uploaded and broadcasted');

      // Move to PIN verification step
      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
      }
    }
  }

  /// Retake photo
  void _retakePhoto() {
    setState(() {
      _deliveryPhoto = null;
      _uploadedPhotoUrl = null;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
  }

  /// Complete delivery with PIN verification
  void _completeDelivery() {
    // Show PIN verification dialog
    _showPinVerificationDialog();
  }

  /// Show PIN verification dialog
  void _showPinVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinVerificationDialog(
        expectedPin: widget.deliveryPin,
        onPinVerified: _onPinVerified,
      ),
    );
  }

  /// Handle PIN verification
  void _onPinVerified() {
    _logger.i('PIN verified successfully for order: ${widget.orderId}');

    // Broadcast delivery completion
    _socketService.broadcastDeliveryComplete(
      orderId: widget.orderId,
      courierId: widget.courierId,
      notes: 'Delivery completed with photo proof and PIN verification',
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery completed successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Confirmation'),
        elevation: 0,
        backgroundColor: Colors.blue[700],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Step indicator
              Row(
                children: [
                  _buildStepIndicator(1, 'Photo', _currentStep >= 0),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 1 ? Colors.green : Colors.grey[300],
                    ),
                  ),
                  _buildStepIndicator(2, 'PIN', _currentStep >= 1),
                ],
              ),
              const SizedBox(height: 32),

              if (_currentStep == 0) ...[
                // Photo capture step
                Text(
                  'Capture Delivery Photo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo showing the delivered item at the delivery location',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Photo preview
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _deliveryPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _deliveryPhoto!,
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
                                  'No photo taken',
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
                if (_deliveryPhoto == null && !_isUploading)
                  ElevatedButton.icon(
                    onPressed: _captureDeliveryPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture Delivery Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.blue[700],
                    ),
                  ),

                if (_deliveryPhoto != null && !_isUploading)
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _uploadDeliveryPhoto,
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
              ] else if (_currentStep == 1) ...[
                // PIN verification step
                Text(
                  'Verify Delivery PIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 4-digit PIN provided by the customer',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Photo confirmation
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
                          'Delivery photo uploaded',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Complete delivery button
                ElevatedButton.icon(
                  onPressed: _completeDelivery,
                  icon: const Icon(Icons.check),
                  label: const Text('Enter PIN & Complete'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.green[700],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build step indicator widget
  Widget _buildStepIndicator(int step, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.green : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: completed ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: completed ? Colors.green : Colors.grey[600],
            fontWeight: completed ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// PIN Verification Dialog
class PinVerificationDialog extends StatefulWidget {
  final String expectedPin;
  final VoidCallback onPinVerified;

  const PinVerificationDialog({
    Key? key,
    required this.expectedPin,
    required this.onPinVerified,
  }) : super(key: key);

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorMessage;
  final Logger _logger = Logger();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Verify PIN
  void _verifyPin() {
    final enteredPin = _pinController.text.trim();

    if (enteredPin.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the PIN';
      });
      return;
    }

    if (enteredPin != widget.expectedPin) {
      setState(() {
        _errorMessage = 'Invalid PIN. Please try again.';
      });
      _logger.w('Invalid PIN entered: $enteredPin (expected: ${widget.expectedPin})');
      return;
    }

    _logger.i('PIN verified successfully');
    Navigator.of(context).pop();
    widget.onPinVerified();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Delivery PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Customer will provide a 4-digit PIN to confirm delivery',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: '0000',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: _errorMessage,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _verifyPin,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
