import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:s3gui/client.dart';
import 'package:s3gui/pages/home.dart';
import 'package:s3gui/pages/objects.dart';
import 'package:s3gui/const.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final _endpointController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _bucketController = TextEditingController();
  final _regionController = TextEditingController();
  final _portController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _obscureSecret = true;
  bool _useSSL = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final endpoint = await _storage.read(key: s3EndpointURLTag);
    final accessKey = await _storage.read(key: s3AccessKeyTag);
    final secretKey = await _storage.read(key: s3SecretKeyTag);
    final bucket = await _storage.read(key: s3BucketTag);
    final region = await _storage.read(key: s3RegionTag);
    final useSSL = await _storage.read(key: s3UseSSLTag);
    final port = await _storage.read(key: s3PortTag);
    _endpointController.text = endpoint ?? '';
    _accessKeyController.text = accessKey ?? '';
    _secretKeyController.text = secretKey ?? '';
    _bucketController.text = bucket ?? '';
    _regionController.text = region ?? '';
    _portController.text = port ?? '';
    _useSSL = useSSL != 'false';
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    _bucketController.dispose();
    _regionController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _storage.write(
        key: s3EndpointURLTag, value: _endpointController.text.trim());
    await _storage.write(
        key: s3AccessKeyTag, value: _accessKeyController.text.trim());
    await _storage.write(
        key: s3SecretKeyTag, value: _secretKeyController.text.trim());
    await _storage.write(
        key: s3BucketTag, value: _bucketController.text.trim());
    await _storage.write(
        key: s3RegionTag, value: _regionController.text.trim());
    await _storage.write(key: s3UseSSLTag, value: _useSSL.toString());
    await _storage.write(
        key: s3PortTag, value: _portController.text.trim());
    if (!mounted) return;
    await Client().init();
    if (!mounted) return;
    final bucket = _bucketController.text.trim();
    final Widget destination = bucket.isNotEmpty
        ? ObjectsPage(
            bucket: bucket,
            prefix: '',
            onToggleTheme: widget.onToggleTheme,
          )
        : HomePage(onToggleTheme: widget.onToggleTheme);
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.cloud_outlined,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to S3',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your S3-compatible service credentials',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _endpointController,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint',
                      hintText: 's3.amazonaws.com',
                      prefixIcon: Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Endpoint is required';
                      }
                      final trimmed = v.trim();
                      if (trimmed.startsWith('http://') ||
                          trimmed.startsWith('https://')) {
                        return 'Enter hostname only, without http:// or https://';
                      }
                      if (trimmed.contains('/')) {
                        return 'Enter hostname only, without path';
                      }
                      if (trimmed.contains(':')) {
                        return 'Enter hostname only — use the Port field for the port number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accessKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Access Key',
                      prefixIcon: Icon(Icons.key_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Access Key is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _secretKeyController,
                    obscureText: _obscureSecret,
                    decoration: InputDecoration(
                      labelText: 'Secret Key',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureSecret
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureSecret = !_obscureSecret),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Secret Key is required'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text('Optional',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _regionController,
                          decoration: const InputDecoration(
                            labelText: 'Region',
                            hintText: 'us-east-1',
                            prefixIcon: Icon(Icons.public_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '443',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bucketController,
                    decoration: const InputDecoration(
                      labelText: 'Default Bucket',
                      hintText: 'my-bucket',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Use SSL (HTTPS)'),
                    subtitle: Text(_useSSL
                        ? 'Secure connection enabled'
                        : 'Insecure connection (HTTP)'),
                    secondary: Icon(_useSSL
                        ? Icons.lock_outlined
                        : Icons.lock_open_outlined),
                    value: _useSSL,
                    onChanged: (v) => setState(() => _useSSL = v),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save & Connect'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
