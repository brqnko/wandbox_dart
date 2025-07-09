/// Represents information about a compiler available on Wandbox.
class CompilerInfo {
  /// The name of the compiler (e.g., "gcc-head").
  final String name;

  /// The version of the compiler.
  final String version;

  /// The language supported by the compiler (e.g., "C++", "Python").
  final String language;

  /// Whether this compiler is considered a "warning" or experimental version.
  final bool? warning;

  /// Display name for the compiler.
  final String? displayName;

  /// List of templates available for this compiler.
  final List<String> templates;

  /// The provider of the compiler (e.g., 1 for GCC, 2 for Clang).
  final int? provider;

  // TODO: Add switches if needed, they have a complex structure.

  /// Creates a [CompilerInfo] from a JSON map.
  CompilerInfo.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      version = json['version'],
      language = json['language'],
      warning = json['warning'],
      displayName = json['display-name'],
      templates = List<String>.from(json['templates'] ?? []),
      provider = json['provider'];

  /// Converts this [CompilerInfo] to a JSON map.
  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'language': language,
    'warning': warning,
    'display-name': displayName,
    'templates': templates,
    'provider': provider,
  };

  @override
  String toString() {
    return 'CompilerInfo(name: $name, version: $version, language: $language)';
  }
}
