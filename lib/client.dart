import 'package:minio/minio.dart';
import 'package:s3gui/const.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Client {
  static final Client _client = Client._internal();
  Client._internal();

  late Minio c;

  factory Client() {
    return _client;
  }

  void init(SharedPreferences sharedPreferences) {
    final endpoint = sharedPreferences.getString(s3EndpointURLTag)!;
    final accessKey = sharedPreferences.getString(s3AccessKeyTag)!;
    final secretKey = sharedPreferences.getString(s3SecretKeyTag)!;
    c = Minio(
      endPoint: endpoint,
      accessKey: accessKey,
      secretKey: secretKey,
      useSSL: true,
    );
  }
}
