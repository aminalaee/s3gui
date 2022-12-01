import 'package:minio/minio.dart';

class Client {
  static final Client _client = Client._internal();
  Client._internal();

  late Minio c;

  factory Client() {
    return _client;
  }

  void init() {
    c = Minio(
      endPoint: '###',
      accessKey: '###',
      secretKey: '###',
      useSSL: true,
    );
  }
}
