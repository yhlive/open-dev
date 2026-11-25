import 'dart:convert';

import 'package:crypto/crypto.dart';

///Reads a file once and feed each chun to all supported hash algorithms.
Future<Map<String, String>> computeFileHashes(
  Stream<List<int>> contents,
) async {
  const algorithme = {
    'MD5': md5,
    'SHA-1': sha1,
    'SHA-256': sha256,
    'SHA-384': sha384,
    'SHA-512': sha512,
  };
  final results = {for (final label in algorithme.keys) label: _DigestSink()};
  final inputs = <ByteConversionSink>[
    for (final entry in algorithme.entries)
      entry.value.startChunkedConversion(results[entry.key]!)
  ];

  try {
    await for (final chunk in contents) {
      for (final input in inputs) {
        input.add(chunk);
      }
    }
  } finally {
    for (final input in inputs) {
      input.close();
    }
  }

  return {
    for (final entry in results.entries)
      entry.key: entry.value.digest.toString(),
  };
}

class _DigestSink implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
