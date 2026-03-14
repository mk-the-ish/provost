import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_state_provider.dart';
import '../../services/api_client.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _phone;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final apiClient = ref.read(apiClientProvider);
    final theme = Theme.of(context);

    if (authState.isLoading || _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState;
    _name ??= user.email ?? '';
    _phone ??= user.userId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.email != null && user.email!.isNotEmpty
                          ? user.email![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email ?? '', style: theme.textTheme.titleMedium),
                        Text(user.userType ?? '', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _name,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (val) => _name = val,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _phone,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                onSaved: (val) => _phone = val,
              ),
              const SizedBox(height: 16),
              Text('Vehicle Type: ${user.userType ?? 'N/A'}'),
              const SizedBox(height: 24),
              if (_isEditing)
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          setState(() => _isLoading = true);
                          try {
                            await apiClient.updateCourierProfile(
                              name: _name!,
                              phone: _phone!,
                              vehicleType: user.userType ?? '',
                              vehicleNumber: '',
                            );
                            setState(() => _isEditing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  child: const Text('Edit Profile'),
                ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                onTap: () async {
                  // TODO: Implement password reset flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset link sent')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  setState(() => _isLoading = true);
                  await ref.read(authProvider.notifier).logout();
                  setState(() => _isLoading = false);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppTheme.errorLight),
                title: Text('Delete Account', style: TextStyle(color: AppTheme.errorLight)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text('Delete', style: TextStyle(color: AppTheme.errorLight)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    setState(() => _isLoading = true);
                    try {
                      await apiClient.deleteCourierProfile();
                      await ref.read(authProvider.notifier).logout();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
