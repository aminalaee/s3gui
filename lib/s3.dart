import 'dart:async';

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
  ListObjectsResult? objectsResult;

  @observable
  bool loadingObjects = false;

  @observable
  bool loadingMore = false;

  @observable
  bool hasMore = false;

  @observable
  String? error;

  StreamIterator<ListObjectsResult>? _streamIterator;

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
  Future<void> createBucket(String bucket) async {
    try {
      error = null;
      await Client().c.makeBucket(bucket);
    } catch (e) {
      error = 'Failed to create bucket: $e';
    }
  }

  @action
  Future<void> deleteBucket(String bucket) async {
    try {
      error = null;
      await Client().c.removeBucket(bucket);
    } catch (e) {
      error = 'Failed to delete bucket: $e';
    }
  }

  Future<bool> _fetchNextPage() async {
    if (_streamIterator == null) return false;
    final hasNext = await _streamIterator!.moveNext();
    if (!hasNext) {
      hasMore = false;
      await _streamIterator!.cancel();
      _streamIterator = null;
      return false;
    }
    final result = _streamIterator!.current;
    final prevPrefixes = objectsResult?.prefixes ?? [];
    final prevObjects = objectsResult?.objects ?? [];
    objectsResult = ListObjectsResult(
      objects: [...prevObjects, ...result.objects],
      prefixes: [...prevPrefixes, ...result.prefixes],
    );
    return true;
  }

  @action
  Future<void> listObjects(String bucket, String prefix) async {
    try {
      error = null;
      loadingObjects = true;
      objectsResult = null;
      hasMore = false;
      await _streamIterator?.cancel();
      Stream<ListObjectsResult> stream;
      try {
        stream = Client().c.listObjectsV2(bucket, prefix: prefix);
      } catch (_) {
        stream = Client().c.listObjects(bucket, prefix: prefix);
      }
      _streamIterator = StreamIterator(stream);
      final gotFirst = await _fetchNextPage();
      if (gotFirst) {
        // Try fetching a second page to determine if there's more
        hasMore = await _fetchNextPage();
      }
      loadingObjects = false;
    } catch (e) {
      loadingObjects = false;
      error = 'Failed to list objects: $e';
    }
  }

  @action
  Future<void> loadMore() async {
    if (!hasMore || loadingMore) return;
    try {
      loadingMore = true;
      final hasNext = await _fetchNextPage();
      hasMore = hasNext;
      loadingMore = false;
    } catch (e) {
      loadingMore = false;
      error = 'Failed to load more objects: $e';
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
    final objs = Client().c.listObjectsV2(bucket, prefix: prefix);
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
