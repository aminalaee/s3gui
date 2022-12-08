import 'package:flutter/material.dart';
import 'package:s3gui/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:s3gui/const.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final endpointUrlController = TextEditingController();
  final accessKeyController = TextEditingController();
  final secretKeyController = TextEditingController();

  @override
  void dispose() {
    endpointUrlController.dispose();
    accessKeyController.dispose();
    secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s3EndpointURL = widget.sharedPreferences.getString(s3EndpointURLTag);
    endpointUrlController.text = s3EndpointURL ?? '';
    final s3AccessKey = widget.sharedPreferences.getString(s3AccessKeyTag);
    accessKeyController.text = s3AccessKey ?? '';
    final s3SecretKey = widget.sharedPreferences.getString(s3SecretKeyTag);
    secretKeyController.text = s3SecretKey ?? '';
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
                    await widget.sharedPreferences.setString(
                        s3EndpointURLTag, endpointUrlController.text);
                    await widget.sharedPreferences
                        .setString(s3AccessKeyTag, accessKeyController.text);
                    await widget.sharedPreferences
                        .setString(s3SecretKeyTag, secretKeyController.text);
                    navigator.pushAndRemoveUntil<void>(
                      MaterialPageRoute<void>(
                          builder: (BuildContext context) => HomePage(
                                sharedPreferences: widget.sharedPreferences,
                              )),
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
