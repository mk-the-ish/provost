import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_state_provider.dart';

/// Phone verification screen with OTP
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String phone;

  const PhoneVerificationScreen({
    Key? key,
    required this.phone,
  }) : super(key: key);

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  late TextEditingController _phoneController;
  late TextEditingController _otpController;
  bool _showOtpField = false;
  bool _isLoading = false;
  String? _verificationId;
  int _resendTimer = 0;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone);
    _otpController = TextEditingController();
    if (widget.phone.isNotEmpty) {
      _requestOtp();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_phoneController.text.isEmpty) {
      _showError('Please enter phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Phone OTP verification not implemented for this version
      // Using email/password authentication instead
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use email/password login instead')),
      );
    } catch (e) {
      _showError('Phone verification is not available');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showError('Please enter OTP');
      return;
    }

    if (_verificationId == null) {
      _showError('Verification ID not found. Please request OTP again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Phone OTP verification not implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone verification is not available')),
      );
    } catch (e) {
      _showError('Verification failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.06),

              // Illustration
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.phone_android,
                    size: 60,
                    color: Colors.blue[600],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.06),

              // Title
              Text(
                _showOtpField ? 'Enter Verification Code' : 'Phone Number',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _showOtpField
                    ? 'We\'ve sent a verification code to ${_phoneController.text}'
                    : 'Enter your phone number to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: size.height * 0.06),

              // Phone Number Field
              if (!_showOtpField) ...[
                Text(
                  'Phone Number',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: '+1 (555) 123-4567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Request OTP',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              // OTP Field
              if (_showOtpField) ...[
                Text(
                  'Verification Code',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !_isLoading,
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[300],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Verify',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Didn\'t receive code? '),
                    if (_resendTimer > 0)
                      Text(
                        'Resend in ${_resendTimer}s',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      GestureDetector(
                        onTap: _requestOtp,
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              SizedBox(height: size.height * 0.06),

              // Change Number Link
              if (_showOtpField)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showOtpField = false;
                        _otpController.clear();
                      });
                    },
                    child: const Text('Change phone number'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
