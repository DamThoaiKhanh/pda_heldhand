import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/auth_viewmodel.dart';
import 'package:pda_handheld/views/server_setting_screen.dart';
import 'package:pda_handheld/views/request_order_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final authViewModel = context.read<AuthViewModel>();
    _rememberMe = authViewModel.rememberMe;

    if (_rememberMe) {
      final credentials = await authViewModel.getSavedCredentials();
      if (credentials != null) {
        _accountController.text = credentials['account'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
      }
    }
    setState(() {});
  }

  Future<void> _login() async {
    // MaterialPageRoute(builder: (_) => const RequestOrderScreen());
    // return;

    if (_accountController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter account and password')),
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    if (authViewModel.serverConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure server settings first')),
      );
      return;
    }

    final success = await authViewModel.login(
      _accountController.text,
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful')));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RequestOrderScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOGIN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerSettingScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'WELCOME',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _accountController,
                  decoration: const InputDecoration(
                    labelText: 'Tài khoản / Account',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu / Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                        authViewModel.setRememberMe(_rememberMe);
                      },
                    ),
                    const Text('Remember me'),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authViewModel.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authViewModel.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('LOGIN', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServerSettingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_ethernet),
                  label: const Text('Server settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
