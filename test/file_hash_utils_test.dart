import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_dev/utils/file_hash_utils.dart';

void main() {
  test('mathches all five one-shot digests across chunk boundaries', () async {
    final bytes = List<int>.generate(1029, (i) => i % 256);
    final chunks = Stream.fromIterable([
      bytes.sublist(0, 3),
      <int>[],
      bytes.sublist(3, 129),
      bytes.sublist(129),
    ]);
    expect(await computeFileHashes(chunks), {
      'MD5': md5.convert(bytes).toString(),
      'SHA-1': sha1.convert(bytes).toString(),
      'SHA-256': sha256.convert(bytes).toString(),
      'SHA-384': sha384.convert(bytes).toString(),
      'SHA-512': sha512.convert(bytes).toString(),
    });
  });

  test('checks known SHA-256 vectors for empty input and abc', () async {
    final empty = await computeFileHashes(Stream<List<int>>.empty());
    final abc = await computeFileHashes(Stream.value(utf8.encode('abc')));

    expect(empty['SHA-256'],
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    expect(abc['SHA-256'],
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });

  test('propagates read errors and allows the next file to be hashed', () async {
    final error = Exception('read error');
    final chunks = Stream<List<int>>.fromFutures([
      Future.error(error),
      Future.value(utf8.encode('abc')),
    ]);
    expect(computeFileHashes(chunks), throwsA(error));
    expect(await computeFileHashes(Stream.value(utf8.encode('abc'))), {
      'MD5': md5.convert(utf8.encode('abc')).toString(),
      'SHA-1': sha1.convert(utf8.encode('abc')).toString(),
      'SHA-256': sha256.convert(utf8.encode('abc')).toString(),
      'SHA-384': sha384.convert(utf8.encode('abc')).toString(),
      'SHA-512': sha512.convert(utf8.encode('abc')).toString(),
    });
  });
}
