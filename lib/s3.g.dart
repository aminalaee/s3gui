// GENERATED CODE - DO NOT MODIFY BY HAND

part of 's3.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$S3 on S3Base, Store {
  late final _$bucketsAtom = Atom(name: 'S3Base.buckets', context: context);

  @override
  List<Bucket> get buckets {
    _$bucketsAtom.reportRead();
    return super.buckets;
  }

  @override
  set buckets(List<Bucket> value) {
    _$bucketsAtom.reportWrite(value, super.buckets, () {
      super.buckets = value;
    });
  }

  late final _$objectsResultAtom =
      Atom(name: 'S3Base.objectsResult', context: context);

  @override
  ListObjectsResult? get objectsResult {
    _$objectsResultAtom.reportRead();
    return super.objectsResult;
  }

  @override
  set objectsResult(ListObjectsResult? value) {
    _$objectsResultAtom.reportWrite(value, super.objectsResult, () {
      super.objectsResult = value;
    });
  }

  late final _$loadingObjectsAtom =
      Atom(name: 'S3Base.loadingObjects', context: context);

  @override
  bool get loadingObjects {
    _$loadingObjectsAtom.reportRead();
    return super.loadingObjects;
  }

  @override
  set loadingObjects(bool value) {
    _$loadingObjectsAtom.reportWrite(value, super.loadingObjects, () {
      super.loadingObjects = value;
    });
  }

  late final _$loadingMoreAtom =
      Atom(name: 'S3Base.loadingMore', context: context);

  @override
  bool get loadingMore {
    _$loadingMoreAtom.reportRead();
    return super.loadingMore;
  }

  @override
  set loadingMore(bool value) {
    _$loadingMoreAtom.reportWrite(value, super.loadingMore, () {
      super.loadingMore = value;
    });
  }

  late final _$hasMoreAtom = Atom(name: 'S3Base.hasMore', context: context);

  @override
  bool get hasMore {
    _$hasMoreAtom.reportRead();
    return super.hasMore;
  }

  @override
  set hasMore(bool value) {
    _$hasMoreAtom.reportWrite(value, super.hasMore, () {
      super.hasMore = value;
    });
  }

  late final _$errorAtom = Atom(name: 'S3Base.error', context: context);

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$listBucketsAsyncAction =
      AsyncAction('S3Base.listBuckets', context: context);

  @override
  Future<void> listBuckets() {
    return _$listBucketsAsyncAction.run(() => super.listBuckets());
  }

  late final _$createBucketAsyncAction =
      AsyncAction('S3Base.createBucket', context: context);

  @override
  Future<void> createBucket(String bucket) {
    return _$createBucketAsyncAction.run(() => super.createBucket(bucket));
  }

  late final _$deleteBucketAsyncAction =
      AsyncAction('S3Base.deleteBucket', context: context);

  @override
  Future<void> deleteBucket(String bucket) {
    return _$deleteBucketAsyncAction.run(() => super.deleteBucket(bucket));
  }

  late final _$listObjectsAsyncAction =
      AsyncAction('S3Base.listObjects', context: context);

  @override
  Future<void> listObjects(String bucket, String prefix) {
    return _$listObjectsAsyncAction
        .run(() => super.listObjects(bucket, prefix));
  }

  late final _$loadMoreAsyncAction =
      AsyncAction('S3Base.loadMore', context: context);

  @override
  Future<void> loadMore() {
    return _$loadMoreAsyncAction.run(() => super.loadMore());
  }

  late final _$createNewDirectoryAsyncAction =
      AsyncAction('S3Base.createNewDirectory', context: context);

  @override
  Future<void> createNewDirectory(
      String bucket, String prefix, String directory) {
    return _$createNewDirectoryAsyncAction
        .run(() => super.createNewDirectory(bucket, prefix, directory));
  }

  late final _$uploadFileAsyncAction =
      AsyncAction('S3Base.uploadFile', context: context);

  @override
  Future<void> uploadFile(String bucket, String path, PlatformFile file,
      AnimationController controller) {
    return _$uploadFileAsyncAction
        .run(() => super.uploadFile(bucket, path, file, controller));
  }

  late final _$getObjectURLAsyncAction =
      AsyncAction('S3Base.getObjectURL', context: context);

  @override
  Future<String?> getObjectURL(String bucket, String path) {
    return _$getObjectURLAsyncAction
        .run(() => super.getObjectURL(bucket, path));
  }

  late final _$deleteObjectAsyncAction =
      AsyncAction('S3Base.deleteObject', context: context);

  @override
  Future<void> deleteObject(String bucket, String prefix, String key) {
    return _$deleteObjectAsyncAction
        .run(() => super.deleteObject(bucket, prefix, key));
  }

  late final _$deleteDirectoryAsyncAction =
      AsyncAction('S3Base.deleteDirectory', context: context);

  @override
  Future<void> deleteDirectory(String bucket, String prefix, String key) {
    return _$deleteDirectoryAsyncAction
        .run(() => super.deleteDirectory(bucket, prefix, key));
  }

  late final _$S3BaseActionController =
      ActionController(name: 'S3Base', context: context);

  @override
  void clearError() {
    final _$actionInfo =
        _$S3BaseActionController.startAction(name: 'S3Base.clearError');
    try {
      return super.clearError();
    } finally {
      _$S3BaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
buckets: ${buckets},
objectsResult: ${objectsResult},
loadingObjects: ${loadingObjects},
loadingMore: ${loadingMore},
hasMore: ${hasMore},
error: ${error}
    ''';
  }
}
