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
    final region = await storage.read(key: s3RegionTag);
    final useSSLStr = await storage.read(key: s3UseSSLTag);
    final portStr = await storage.read(key: s3PortTag);
    final useSSL = useSSLStr != 'false';
    var host = endpoint!;
    var port = portStr != null && portStr.isNotEmpty
        ? int.tryParse(portStr)
        : null;
    // Handle endpoint entered as "host:port"
    if (host.contains(':')) {
      final parts = host.split(':');
      host = parts[0];
      port ??= int.tryParse(parts[1]);
    }
    c = Minio(
      endPoint: host,
      accessKey: accessKey!,
      secretKey: secretKey!,
      useSSL: useSSL,
      region: region != null && region.isNotEmpty ? region : null,
      port: port,
      enableTrace: true,
    );
  }
}
