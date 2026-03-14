import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_state_provider.dart';

/// Register new courier account
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String _selectedVehicleType = 'motorcycle';
  int _selectedCapacity = 1;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final List<String> _vehicleTypes = ['motorcycle', 'car', 'van', 'truck'];
  final List<int> _capacities = [1, 2, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).registerCourier(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        vehicleType: _selectedVehicleType,
        vehicleNumber: 'VEHICLE-${_selectedCapacity}', // Placeholder vehicle number
        licenseNumber: 'LICENSE-${_selectedCapacity}', // Placeholder license number
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return false;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('Please enter a valid email');
      return false;
    }
    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }
    if (!_agreedToTerms) {
      _showError('Please agree to Terms & Conditions');
      return false;
    }
    return true;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              _buildFormField(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline,
                hint: 'John Doe',
              ),

              const SizedBox(height: 20),

              // Email Field
              _buildFormField(
                label: 'Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Phone Field
              _buildFormField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                hint: '+1234567890',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // Vehicle Type Dropdown
              Text(
                'Vehicle Type',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                items: _vehicleTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type[0].toUpperCase() + type.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedVehicleType = value);
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 20),

              // Capacity Dropdown
              Text(
                'Delivery Capacity',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedCapacity,
                items: _capacities.map((capacity) {
                  return DropdownMenuItem(
                    value: capacity,
                    child: Text('$capacity parcel${capacity > 1 ? 's' : ''}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCapacity = value);
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),

              const SizedBox(height: 20),

              // Password Field
              _buildFormField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                hint: 'Create a strong password',
                obscureText: _obscurePassword,
                onSuffixPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                suffixIcon: _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),

              const SizedBox(height: 20),

              // Confirm Password Field
              _buildFormField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                hint: 'Confirm your password',
                obscureText: _obscureConfirmPassword,
                onSuffixPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                suffixIcon: _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),

              const SizedBox(height: 24),

              // Terms & Conditions
              CheckboxListTile(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() => _agreedToTerms = value ?? false);
                },
                title: Text(
                  'I agree to Terms & Conditions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? onSuffixPressed,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon),
                    onPressed: onSuffixPressed,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ],
    );
  }
}
