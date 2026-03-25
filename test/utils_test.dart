import 'package:flutter_test/flutter_test.dart';
import 'package:s3gui/utils/utils.dart';

void main() {
  group('normalizePath', () {
    test('removes prefix from path', () {
      expect(normalizePath('photos/vacation/img.jpg', 'photos/vacation/'),
          'img.jpg');
    });

    test('returns full path when prefix is empty', () {
      expect(normalizePath('photos/img.jpg', ''), 'photos/img.jpg');
    });

    test('removes prefix from directory path', () {
      expect(normalizePath('data/logs/', 'data/'), 'logs/');
    });

    test('handles root-level objects', () {
      expect(normalizePath('file.txt', ''), 'file.txt');
    });

    test('handles matching prefix exactly', () {
      expect(normalizePath('prefix/', 'prefix/'), '');
    });
  });
}
