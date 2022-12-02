import 'package:minio/models.dart';
import 'package:mobx/mobx.dart';
import 'package:s3gui/client.dart';

part 's3.g.dart';

class S3 = S3Base with _$S3;

abstract class S3Base with Store {
  @observable
  List<Bucket> buckets = [];

  @observable
  Stream<ListObjectsResult> objects = const Stream.empty();

  @action
  Future<void> listBuckets() async {
    buckets = await Client().c.listBuckets();
  }

  @action
  Future<void> listObjects(String bucket, String prefix) async {
    objects = Client().c.listObjects(bucket, prefix: prefix);
  }

  @action
  Future<void> createNewDirectory(String bucket, String prefix) async {
    final path = '${prefix}new_folder/';
    await Client().c.putObject(bucket, path, const Stream.empty(), size: 0);
    await listObjects(bucket, prefix);
  }
}
