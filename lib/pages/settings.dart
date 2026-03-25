import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:s3gui/pages/home.dart';
import 'package:s3gui/const.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final endpointUrlController = TextEditingController();
  final accessKeyController = TextEditingController();
  final secretKeyController = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final endpoint = await _storage.read(key: s3EndpointURLTag);
    final accessKey = await _storage.read(key: s3AccessKeyTag);
    final secretKey = await _storage.read(key: s3SecretKeyTag);
    endpointUrlController.text = endpoint ?? '';
    accessKeyController.text = accessKey ?? '';
    secretKeyController.text = secretKey ?? '';
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    endpointUrlController.dispose();
    accessKeyController.dispose();
    secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(left: 25, right: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: endpointUrlController,
                decoration: const InputDecoration(
                  labelText: 'Endpoint URL',
                  hintText: 'eg. s3.amazon.com',
                  enabledBorder: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Endpoint URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: accessKeyController,
                decoration: const InputDecoration(
                  labelText: 'Acess Key',
                  enabledBorder: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Access Key';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: secretKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  enabledBorder: UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Secret Key';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Saving...'),
                        duration: Duration(seconds: 1)));
                    await _storage.write(
                        key: s3EndpointURLTag,
                        value: endpointUrlController.text);
                    await _storage.write(
                        key: s3AccessKeyTag,
                        value: accessKeyController.text);
                    await _storage.write(
                        key: s3SecretKeyTag,
                        value: secretKeyController.text);
                    navigator.pushAndRemoveUntil<void>(
                      MaterialPageRoute<void>(
                          builder: (BuildContext context) => const HomePage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
