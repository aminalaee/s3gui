import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:minio/minio.dart';
import 'package:s3gui/const.dart';

class Client {
  static final Client _client = Client._internal();
  Client._internal();

  late Minio c;

  factory Client() {
    return _client;
  }

  Future<void> init() async {
    const storage = FlutterSecureStorage();
    final endpoint = await storage.read(key: s3EndpointURLTag);
    final accessKey = await storage.read(key: s3AccessKeyTag);
    final secretKey = await storage.read(key: s3SecretKeyTag);
    c = Minio(
      endPoint: endpoint!,
      accessKey: accessKey!,
      secretKey: secretKey!,
      useSSL: true,
    );
  }
}
