import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  Future<void> createNewDirectory(
      String bucket, String prefix, String directory) async {
    final path = '$prefix$directory/';
    await Client().c.putObject(bucket, path, const Stream.empty(), size: 0);
  }

  @action
  Future<void> uploadFile(String bucket, String path, PlatformFile file,
      AnimationController controller) async {
    controller.value = 1;
    await Client().c.putObject(
      bucket,
      path,
      Stream.value(file.bytes!),
      onProgress: (bytes) {
        controller.value = bytes / file.size;
      },
    );
  }

  @action
  Future<String> getObjectURL(String bucket, String path) async {
    return await Client().c.presignedGetObject(bucket, path);
  }

  @action
  Future<void> deleteObject(String bucket, String prefix, String key) async {
    final path = '$prefix$key';
    await Client().c.removeObject(bucket, path);
  }

  @action
  Future<void> deleteDirectory(String bucket, String prefix, String key) async {
    final path = '$prefix$key';
    await _removeDirectory(bucket, path);
  }

  Future<void> _removeDirectory(String bucket, String prefix) async {
    final objs = Client().c.listObjects(bucket, prefix: prefix);
    await for (final objResult in objs) {
      for (final obj in objResult.objects) {
        await Client().c.removeObject(bucket, obj.key!); // Remove files
      }
      for (final p in objResult.prefixes) {
        await _removeDirectory(bucket, p); // Remove directories
      }
    }
  }
}
