import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

String prettyJson(String jsonString) {
  return const JsonEncoder.withIndent('  ').convert(jsonDecode(jsonString));
}

String minifyJson(String jsonString) {
  return jsonEncode(jsonDecode(jsonString));
}

String describeJsonError(FormatException error, String source) {
  final offest = error.offset;
  if (offest == null || offest < 0 || offest > source.length) {
    return error.message;
  }

  var line = 1;
  var lineStart = 0;
  for (var i = 0; i < offest; i++) {
    if (source.codeUnitAt(i) == 10) {
      line++;
      lineStart = i + 1;
    }
  }
  final column = offest - lineStart + 1;
  return 'Line $line, column $column: ${error.message}';
}

String convertJsonToYaml(String jsonString) {
  final jsonValue = json.decode(jsonString);

  YamlEditor yamlEditor = YamlEditor('');
  yamlEditor.update([], jsonValue);
  return yamlEditor.toString();
}

/// Converts a YAML document to a pretty-printed JSON string.
String convertYamlToJson(String yamlString) {
  final parsed = loadYaml(yamlString);
  final native = _yamlToNative(parsed);
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(native);
}

/// Recursively converts `YamlMap`/`YamlList`/scalar values into the standard
/// `Map<String, dynamic>` / `List<dynamic>` types that `jsonEncode` accepts.
dynamic _yamlToNative(dynamic node) {
  if (node is YamlMap) {
    return {
      for (final entry in node.entries)
        entry.key.toString(): _yamlToNative(entry.value),
    };
  }
  if (node is YamlList) {
    return [for (final v in node) _yamlToNative(v)];
  }
  return node;
}
