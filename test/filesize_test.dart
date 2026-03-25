import 'package:flutter_test/flutter_test.dart';
import 'package:s3gui/utils/filesize.dart';

void main() {
  group('filesize', () {
    test('returns bytes for small sizes', () {
      expect(filesize(0), '0 B');
      expect(filesize(512), '512 B');
      expect(filesize(1023), '1023 B');
    });

    test('returns KiB for kilobyte range', () {
      expect(filesize(1024), '1 KiB');
      expect(filesize(2048), '2 KiB');
      expect(filesize(1536), '1.50 KiB');
    });

    test('returns MiB for megabyte range', () {
      expect(filesize(1048576), '1 MiB');
      expect(filesize(2097152), '2 MiB');
      expect(filesize(1500000), '1.43 MiB');
    });

    test('returns GiB for gigabyte range', () {
      expect(filesize(1073741824), '1 GiB');
      expect(filesize(2147483648), '2 GiB');
    });

    test('respects custom round parameter', () {
      expect(filesize(1536, 1), '1.5 KiB');
      expect(filesize(1536, 0), '2 KiB');
      expect(filesize(1536, 3), '1.500 KiB');
    });
  });
}
