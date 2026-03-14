import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_state_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleNumberController;
  String _vehicleType = 'bike';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _vehicleNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _vehicleNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      // Cast authProvider.notifier to CourierAuthNotifier
      final authNotifier = ref.read(authProvider.notifier);
      
      // Register courier using registerCourier method
      await authNotifier.registerCourier(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleType: _vehicleType,
        vehicleNumber: _vehicleNumberController.text.trim(),
      );

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo/Title
              const Text(
                'Join CityDrop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Start Earning Today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              // Error message
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ),
              // Name field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(height: 16),
              // Email field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabled: !isLoading,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Phone field
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabled: !isLoading,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Vehicle Type dropdown
              const Text(
                'Vehicle Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _vehicleType,
                isExpanded: true,
                items: ['bike', 'car', 'truck']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _vehicleType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Vehicle number field
              TextField(
                controller: _vehicleNumberController,
                decoration: InputDecoration(
                  hintText: 'Vehicle License Plate',
                  prefixIcon: const Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(height: 16),
              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password (min 6 characters)',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabled: !isLoading,
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              // Register button
              ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
