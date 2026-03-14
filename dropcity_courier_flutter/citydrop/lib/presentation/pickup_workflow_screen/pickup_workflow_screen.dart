import 'dart:io';
import '../../services/firebase_storage_service.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/photo_preview_modal_widget.dart';
import './widgets/pickup_action_widget.dart';
import './widgets/pickup_checklist_widget.dart';
import './widgets/pickup_header_widget.dart';
import './widgets/upload_progress_widget.dart';

class PickupWorkflowScreen extends ConsumerStatefulWidget {
  const PickupWorkflowScreen({super.key});

  @override
  ConsumerState<PickupWorkflowScreen> createState() => _PickupWorkflowScreenState();
}

class _PickupWorkflowScreenState extends ConsumerState<PickupWorkflowScreen>
    with WidgetsBindingObserver {
  // Mock order data
  final Map<String, dynamic> _orderData = {
    "orderId": "ORD-2026-00847",
    "customerName": "Sarah Mitchell",
    "pickupAddress": "1247 Maple Street, Brooklyn, NY 11201",
    "packageSize": "Medium",
    "packageWeight": "3.2 lbs",
    "notes": "Handle with care - fragile items inside",
    "estimatedDistance": "0.08 km",
    "courierDistance": 45.0,
  };

  // State
  bool _isWithinGeofence = false;
  bool _isPickupConfirmed = false;
  bool _isUploading = false;
  bool _isUploadComplete = false;
  bool _isStatusUpdated = false;
  double _uploadProgress = 0.0;
  XFile? _capturedPhoto;
  String? _pickupPhotoUrl;
  String? _captureTimestamp;
  String? _captureGpsCoords;
  bool _showPreviewModal = false;
  bool _isOfflineMode = false;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraOpen = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _simulateGeofenceCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  void _simulateGeofenceCheck() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isWithinGeofence = true;
          _orderData["courierDistance"] = 42.0;
        });
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (_) {}
      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraOpen = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          'Camera initialization failed. Using gallery instead.',
        );
        await _pickFromGallery();
      }
    }
  }

  Future<void> _openCamera() async {
    if (!_isWithinGeofence) return;
    HapticFeedback.lightImpact();
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      _showErrorSnackbar(
        'Camera permission is required to capture pickup photo.',
      );
      return;
    }
    await _initializeCamera();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final XFile photo = await _cameraController!.takePicture();
      final now = DateTime.now();
      setState(() {
        _capturedPhoto = photo;
        _captureTimestamp =
            '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _captureGpsCoords = '40.6892° N, 74.0445° W';
        _isCameraOpen = false;
        _showPreviewModal = true;
      });
      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraInitialized = false;
    } catch (e) {
      _showErrorSnackbar('Failed to capture photo. Please try again.');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (photo != null) {
        final now = DateTime.now();
        setState(() {
          _capturedPhoto = photo;
          _captureTimestamp =
              '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          _captureGpsCoords = '40.6892° N, 74.0445° W';
          _showPreviewModal = true;
        });
      }
    } catch (e) {
      // no-op
      _showErrorSnackbar('Failed to select photo.');
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
      _showPreviewModal = false;
    });
  }

  Future<void> _confirmPhoto() async {
    setState(() {
      _showPreviewModal = false;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final authState = ref.read(authProvider);
    final apiClient = ref.read(apiClientProvider);
    final storageService = FirebaseStorageService();
    final orderId = _orderData['orderId'] as String;
    final courierId = authState.userId ?? 'unknown';

    try {
      if (_capturedPhoto == null) throw Exception('No photo to upload');
      final file = File(_capturedPhoto!.path);
      String? downloadUrl;
      downloadUrl = await storageService.uploadPickupPhoto(
        orderId: orderId,
        courierId: courierId,
        imageFile: file,
      );
      if (downloadUrl == null) throw Exception('Photo upload failed');

      setState(() {
        _pickupPhotoUrl = downloadUrl;
        _uploadProgress = 1.0;
      });

      // Update order with pickupPhotoUrl and set status to PICKED_UP
      await apiClient.updateOrderStatus(
        orderId: orderId,
        status: 'picked_up',
      );
      setState(() {
        _isUploading = false;
        _isUploadComplete = true;
        _isPickupConfirmed = true;
        _isStatusUpdated = true;
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup photo uploaded and order updated!')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isUploadComplete = false;
        _isPickupConfirmed = false;
        _isStatusUpdated = false;
      });
      _showErrorSnackbar('Failed to upload photo or update order: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _allChecklistComplete =>
      _capturedPhoto != null && _isWithinGeofence && _isStatusUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (_isPickupConfirmed && !_allChecklistComplete) {
          final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                'Incomplete Pickup',
                style: theme.textTheme.titleMedium,
              ),
              content: Text(
                'Pickup is not fully complete. Are you sure you want to leave?',
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
          return shouldLeave ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: _isCameraOpen
              ? _buildCameraView(theme)
              : Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  child: Column(
                    children: [
                      PickupHeaderWidget(
                        orderData: _orderData,
                        isOfflineMode: _isOfflineMode,
                        onBack: () => Navigator.of(context).pop(),
                        onToggleOffline: () =>
                            setState(() => _isOfflineMode = !_isOfflineMode),
                      ),
                      SizedBox(height: 2.h),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PickupActionWidget(
                                orderData: _orderData,
                                isWithinGeofence: _isWithinGeofence,
                                isPickupConfirmed: _isPickupConfirmed,
                                isUploading: _isUploading,
                                isUploadComplete: _isUploadComplete,
                                capturedPhoto: _capturedPhoto,
                                pickupPhotoUrl: _pickupPhotoUrl,
                                captureTimestamp: _captureTimestamp,
                                captureGpsCoords: _captureGpsCoords,
                                onConfirmPickup: _openCamera,
                                onPickFromGallery: _pickFromGallery,
                              ),
                              if (_isUploading) ...[
                                SizedBox(height: 2.h),
                                UploadProgressWidget(progress: _uploadProgress),
                              ],
                              SizedBox(height: 2.h),
                              PickupChecklistWidget(
                                isPhotoCapture: _capturedPhoto != null,
                                isLocationVerified: _isWithinGeofence,
                                isStatusUpdated: _isStatusUpdated,
                              ),
                              SizedBox(height: 2.h),
                              if (_isOfflineMode) _buildOfflineBanner(theme),
                              SizedBox(height: 2.h),
                            ],
                          ),
                        ),
                      ),
                      if (_allChecklistComplete) _buildNavigateButton(theme),
                    ],
                  ),
                ),
        ),
        // Photo preview modal overlay
        bottomSheet: _showPreviewModal
            ? PhotoPreviewModalWidget(
                capturedPhoto: _capturedPhoto,
                onRetake: _retakePhoto,
                onConfirm: _confirmPhoto,
              )
            : null,
      ),
    );
  }

  Widget _buildCameraView(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _isCameraInitialized && _cameraController != null
            ? CameraPreview(_cameraController!)
            : Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
        // Alignment guides overlay
        Positioned.fill(child: CustomPaint(painter: _AlignmentGuidePainter())),
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    _cameraController?.dispose();
                    _cameraController = null;
                    setState(() {
                      _isCameraOpen = false;
                      _isCameraInitialized = false;
                    });
                  },
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Capture Package Photo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
            ),
          ),
        ),
        // Tips
        Positioned(
          top: 10.h,
          left: 4.w,
          right: 4.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'lightbulb_outline',
                  color: Colors.amber,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Ensure good lighting and center the package in frame',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Capture button
        Positioned(
          bottom: 5.h,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Container(
                    width: 13.w,
                    height: 13.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Gallery fallback
        Positioned(
          bottom: 5.h,
          right: 8.w,
          child: IconButton(
            onPressed: () {
              _cameraController?.dispose();
              _cameraController = null;
              setState(() {
                _isCameraOpen = false;
                _isCameraInitialized = false;
              });
              _pickFromGallery();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'photo_library',
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'cloud_off',
            color: AppTheme.warningColor,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode Active',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.warningColor,
                  ),
                ),
                Text(
                  'Photos stored locally. Will sync when connected.',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigateButton(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed('/active-delivery-dashboard');
          },
          icon: CustomIconWidget(
            iconName: 'navigation',
            color: Colors.white,
            size: 20,
          ),
          label: const Text('Proceed to Delivery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            padding: EdgeInsets.symmetric(vertical: 1.8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlignmentGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double boxW = size.width * 0.7;
    final double boxH = size.height * 0.4;
    final double left = cx - boxW / 2;
    final double top = cy - boxH / 2;
    final double cornerLen = 20;

    // Corner guides
    // TL
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), paint);
    // TR
    canvas.drawLine(
      Offset(left + boxW - cornerLen, top),
      Offset(left + boxW, top),
      paint,
    );
    canvas.drawLine(
      Offset(left + boxW, top),
      Offset(left + boxW, top + cornerLen),
      paint,
    );
    // BL
    canvas.drawLine(
      Offset(left, top + boxH - cornerLen),
      Offset(left, top + boxH),
      paint,
    );
    canvas.drawLine(
      Offset(left, top + boxH),
      Offset(left + cornerLen, top + boxH),
      paint,
    );
    // BR
    canvas.drawLine(
      Offset(left + boxW - cornerLen, top + boxH),
      Offset(left + boxW, top + boxH),
      paint,
    );
    canvas.drawLine(
      Offset(left + boxW, top + boxH - cornerLen),
      Offset(left + boxW, top + boxH),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
