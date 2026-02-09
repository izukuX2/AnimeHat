import 'dart:convert';

/// Base class for value transformers
abstract class ValueTransformer {
  String transform(String input);
}

/// Base64 decoder transformer
class Base64Transformer extends ValueTransformer {
  @override
  String transform(String input) {
    try {
      // Clean the input - extract from quotes if needed
      var cleanValue = input.trim();
      if (cleanValue.contains("'")) {
        final match = RegExp(r"'([^']*)'").firstMatch(cleanValue);
        if (match != null) cleanValue = match.group(1)!;
      } else if (cleanValue.contains('"')) {
        final match = RegExp(r'"([^"]*)"').firstMatch(cleanValue);
        if (match != null) cleanValue = match.group(1)!;
      }
      return utf8.decode(base64.decode(cleanValue));
    } catch (e) {
      return input;
    }
  }
}

/// URL decoder transformer
class UrlDecodeTransformer extends ValueTransformer {
  @override
  String transform(String input) {
    try {
      return Uri.decodeComponent(input);
    } catch (e) {
      return input;
    }
  }
}

/// Regex extraction transformer
class RegexTransformer extends ValueTransformer {
  final String pattern;
  final int group;

  RegexTransformer(this.pattern, {this.group = 1});

  @override
  String transform(String input) {
    try {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(input);
      if (match != null && match.groupCount >= group) {
        return match.group(group) ?? input;
      }
      return input;
    } catch (e) {
      return input;
    }
  }
}

/// Replace transformer
class ReplaceTransformer extends ValueTransformer {
  final String from;
  final String to;
  final bool isRegex;

  ReplaceTransformer(this.from, this.to, {this.isRegex = false});

  @override
  String transform(String input) {
    if (isRegex) {
      return input.replaceAll(RegExp(from), to);
    }
    return input.replaceAll(from, to);
  }
}

/// Trim transformer
class TrimTransformer extends ValueTransformer {
  @override
  String transform(String input) => input.trim();
}

/// Strip label transformer (removes Arabic labels like "حالة الأنمي:")
class StripLabelTransformer extends ValueTransformer {
  @override
  String transform(String input) {
    // Remove common Arabic label patterns
    final patterns = [
      RegExp(r'^[^\:]+:\s*'), // "Label: value" pattern
      RegExp(r'^[أ-ي\s]+:\s*'), // Arabic "Label:" pattern
    ];

    var result = input;
    for (final pattern in patterns) {
      result = result.replaceFirst(pattern, '');
    }
    return result.trim();
  }
}

/// Chain multiple transformers
class TransformerChain extends ValueTransformer {
  final List<ValueTransformer> transformers;

  TransformerChain(this.transformers);

  @override
  String transform(String input) {
    var result = input;
    for (final transformer in transformers) {
      result = transformer.transform(result);
    }
    return result;
  }
}

/// Factory for common transformer combinations
class Transformers {
  static ValueTransformer base64() => Base64Transformer();
  static ValueTransformer urlDecode() => UrlDecodeTransformer();
  static ValueTransformer regex(String pattern, {int group = 1}) =>
      RegexTransformer(pattern, group: group);
  static ValueTransformer replace(String from, String to,
          {bool isRegex = false}) =>
      ReplaceTransformer(from, to, isRegex: isRegex);
  static ValueTransformer trim() => TrimTransformer();
  static ValueTransformer stripLabel() => StripLabelTransformer();
  static ValueTransformer chain(List<ValueTransformer> transformers) =>
      TransformerChain(transformers);

  /// Common: Extract Base64 from onclick attribute
  static ValueTransformer onclickBase64() => chain([
        regex(r"'([^']+)'"),
        base64(),
      ]);
}
