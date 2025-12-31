import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/auth_viewmodel.dart';

class ServerSettingScreen extends StatefulWidget {
  const ServerSettingScreen({super.key});

  @override
  State<ServerSettingScreen> createState() => _ServerSettingScreenState();
}

class _ServerSettingScreenState extends State<ServerSettingScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    final config = authViewModel.serverConfig;
    if (config != null) {
      _ipController.text = config.ipAddress;
      _portController.text = config.port;
    }
  }

  bool _isValidIPv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final num = int.tryParse(part);
      return num != null && num >= 0 && num <= 255;
    });
  }

  void _save() {
    if (!_isValidIPv4(_ipController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid IPv4 address')));
      return;
    }

    if (_portController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Port is required')));
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    authViewModel.saveServerConfig(_ipController.text, _portController.text);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Server settings saved')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
                helperText: 'Server IPv4 address',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '8080',
                border: OutlineInputBorder(),
                helperText: 'Server port',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('SAVE'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
