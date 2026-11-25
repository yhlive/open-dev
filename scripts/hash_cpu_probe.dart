import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:open_dev/utils/file_hash_utils.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2 || !{'whole', 'stream'}.contains(args.first)) {
    stderr.writeln('Usage: hash_cpu_probe.dart whole|stream <file>');
    exitCode = 64;
    return;
  }

  final mode = args.first;
  final file = File(args.last);
  stdout.writeln('Mode: $mode. Press Enter to hash the file; type q to quit.');
  var line = stdin.readLineSync();
  while (line != null && line != 'q') {
    final stopwatch = Stopwatch()..start();
    final Map<String, String> hashes;
    if (mode == 'whole') {
      final bytes = await file.readAsBytes();
      hashes = {
        'MD5': md5.convert(bytes).toString(),
        'SHA-1': sha1.convert(bytes).toString(),
        'SHA-256': sha256.convert(bytes).toString(),
        'SHA-384': sha384.convert(bytes).toString(),
        'SHA-512': sha512.convert(bytes).toString(),
      };
    } else {
      hashes = await computeFileHashes(file.openRead());
    }
    stopwatch.stop();
    stdout.writeln('SHA-256: ${hashes['SHA-256']}');
    stdout.writeln('Elapsed: ${stopwatch.elapsedMilliseconds} ms');
    stdout.writeln('Press Enter to hash again; type q to quit.');
    line = stdin.readLineSync();
  }
}
