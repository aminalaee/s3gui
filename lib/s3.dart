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

  @observable
  String? error;

  @action
  void clearError() {
    error = null;
  }

  @action
  Future<void> listBuckets() async {
    try {
      error = null;
      buckets = await Client().c.listBuckets();
    } catch (e) {
      error = 'Failed to list buckets: $e';
    }
  }

  @action
  Future<void> listObjects(String bucket, String prefix) async {
    try {
      error = null;
      objects = Client().c.listObjects(bucket, prefix: prefix);
    } catch (e) {
      error = 'Failed to list objects: $e';
    }
  }

  @action
  Future<void> createNewDirectory(
      String bucket, String prefix, String directory) async {
    try {
      error = null;
      final path = '$prefix$directory/';
      await Client().c.putObject(bucket, path, const Stream.empty(), size: 0);
    } catch (e) {
      error = 'Failed to create directory: $e';
    }
  }

  @action
  Future<void> uploadFile(String bucket, String path, PlatformFile file,
      AnimationController controller) async {
    try {
      error = null;
      controller.value = 1;
      await Client().c.putObject(
        bucket,
        path,
        Stream.value(file.bytes!),
        onProgress: (bytes) {
          controller.value = bytes / file.size;
        },
      );
    } catch (e) {
      controller.value = -1;
      error = 'Failed to upload file: $e';
    }
  }

  @action
  Future<String?> getObjectURL(String bucket, String path) async {
    try {
      error = null;
      return await Client().c.presignedGetObject(bucket, path);
    } catch (e) {
      error = 'Failed to get object URL: $e';
      return null;
    }
  }

  @action
  Future<void> deleteObject(String bucket, String prefix, String key) async {
    try {
      error = null;
      final path = '$prefix$key';
      await Client().c.removeObject(bucket, path);
    } catch (e) {
      error = 'Failed to delete object: $e';
    }
  }

  @action
  Future<void> deleteDirectory(
      String bucket, String prefix, String key) async {
    try {
      error = null;
      final path = '$prefix$key';
      await _removeDirectory(bucket, path);
    } catch (e) {
      error = 'Failed to delete directory: $e';
    }
  }

  Future<void> _removeDirectory(String bucket, String prefix) async {
    final objs = Client().c.listObjects(bucket, prefix: prefix);
    await for (final objResult in objs) {
      for (final obj in objResult.objects) {
        await Client().c.removeObject(bucket, obj.key!);
      }
      for (final p in objResult.prefixes) {
        await _removeDirectory(bucket, p);
      }
    }
  }
}
