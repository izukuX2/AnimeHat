enum ExtensionStatus { installed, updateAvailable, missing }

enum ExtensionType { source, uiMod }

class Extension {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final String iconUrl;
  final String pkgName;
  final ExtensionSource source;
  final ExtensionStatus status;
  final ExtensionType type;
  final ModData? modData;

  Extension({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    required this.iconUrl,
    required this.pkgName,
    required this.source,
    this.status = ExtensionStatus.installed,
    this.type = ExtensionType.source,
    this.modData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'author': author,
      'iconUrl': iconUrl,
      'pkgName': pkgName,
      'source': source.toJson(),
      'type': type.name,
      'modData': modData?.toJson(),
    };
  }

  factory Extension.fromJson(Map<String, dynamic> json) {
    return Extension(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      version: json['version'] ?? '1.0.0',
      author: json['author'] ?? 'Unknown',
      iconUrl: json['iconUrl'] ?? '',
      pkgName: json['pkgName'] ?? '',
      source: ExtensionSource.fromJson(json['source'] ??
          {
            'baseUrl': '',
            'headers': {},
            'endpoints': {},
          }),
      type: ExtensionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExtensionType.source,
      ),
      modData:
          json['modData'] != null ? ModData.fromJson(json['modData']) : null,
    );
  }
}

class ModData {
  final Map<String, dynamic> themeOverrides;
  final Map<String, dynamic> uiTweaks;

  ModData({
    required this.themeOverrides,
    required this.uiTweaks,
  });

  Map<String, dynamic> toJson() {
    return {
      'themeOverrides': themeOverrides,
      'uiTweaks': uiTweaks,
    };
  }

  factory ModData.fromJson(Map<String, dynamic> json) {
    return ModData(
      themeOverrides: Map<String, dynamic>.from(json['themeOverrides'] ?? {}),
      uiTweaks: Map<String, dynamic>.from(json['uiTweaks'] ?? {}),
    );
  }
}

class ExtensionSource {
  final String baseUrl;
  final Map<String, String> headers;
  final Map<String, dynamic> endpoints;

  ExtensionSource({
    required this.baseUrl,
    required this.headers,
    required this.endpoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'headers': headers,
      'endpoints': endpoints,
    };
  }

  factory ExtensionSource.fromJson(Map<String, dynamic> json) {
    return ExtensionSource(
      baseUrl: json['baseUrl'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      // endpoints can contain nested maps for selectors
      endpoints: Map<String, dynamic>.from(json['endpoints'] ?? {}),
    );
  }
}
