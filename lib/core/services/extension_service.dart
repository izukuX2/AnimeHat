import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/animeify_api_client.dart';
import '../models/extension_model.dart';
import '../providers/anime_provider.dart';
import '../providers/animeify_provider.dart';
import '../providers/dynamic_json_provider.dart';
import 'package:http/http.dart' as http;

class ExtensionService extends ChangeNotifier {
  static final ExtensionService _instance = ExtensionService._internal();
  factory ExtensionService() => _instance;

  final Map<String, BaseAnimeProvider> _providers = {};
  final Map<String, Extension> _installedMods = {};
  String _activeProviderId = 'animeify_legacy';
  String? _activeModId;
  static const String _extensionsKey = 'custom_extensions';
  static const String _activeProviderKey = 'active_provider_id';
  static const String _activeModKey = 'active_mod_id';

  ExtensionService._internal() {
    _init();
  }

  Future<void> _init() async {
    // Register built-in providers
    final animeify = AnimeifyProvider(AnimeifyApiClient());
    registerProvider(animeify);

    // Set fallback to legacy
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_activeProviderKey)?.contains('witanime') ?? false) {
      await setActiveProvider('animeify_legacy');
    }

    // Order matters: assets should come LAST to overwrite potentially stale cached versions
    await loadExtensions();
  }

  BaseAnimeProvider get activeProvider =>
      _providers[_activeProviderId] ?? _providers.values.first;

  Extension? get activeMod =>
      _activeModId != null ? _installedMods[_activeModId] : null;

  List<BaseAnimeProvider> get availableProviders => _providers.values.toList();
  List<Extension> get installedMods => _installedMods.values.toList();

  void registerProvider(BaseAnimeProvider provider) {
    _providers[provider.id] = provider;
    notifyListeners();
  }

  void registerMod(Extension mod) {
    _installedMods[mod.id] = mod;
    notifyListeners();
  }

  Future<void> setActiveProvider(String id) async {
    if (_providers.containsKey(id)) {
      _activeProviderId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeProviderKey, id);
      notifyListeners();
    }
  }

  Future<void> setActiveMod(String? id) async {
    _activeModId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_activeModKey, id);
    } else {
      await prefs.remove(_activeModKey);
    }
    notifyListeners();
  }

  Future<void> loadExtensions() async {
    final prefs = await SharedPreferences.getInstance();
    _activeProviderId =
        prefs.getString(_activeProviderKey) ?? 'animeify_legacy';
    _activeModId = prefs.getString(_activeModKey);

    final jsonList = prefs.getStringList(_extensionsKey) ?? [];
    for (final jsonStr in jsonList) {
      try {
        final ext = Extension.fromJson(json.decode(jsonStr));
        if (ext.type == ExtensionType.source) {
          final provider = DynamicJsonProvider(ext);
          registerProvider(provider);
        } else if (ext.type == ExtensionType.uiMod) {
          registerMod(ext);
        }
      } catch (e) {
        debugPrint('Failed to load extension: $e');
      }
    }
  }

  Future<void> installExtensionFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final ext = Extension.fromJson(json.decode(response.body));
        if (ext.type == ExtensionType.source) {
          registerProvider(DynamicJsonProvider(ext));
        } else if (ext.type == ExtensionType.uiMod) {
          registerMod(ext);
        }
        await _saveExtension(ext);
      }
    } catch (e) {
      debugPrint('Failed to install extension: $e');
      rethrow;
    }
  }

  Future<void> _saveExtension(Extension ext) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_extensionsKey) ?? [];
    // Avoid duplicates
    final newList = jsonList.where((jsonStr) {
      final existing = Extension.fromJson(json.decode(jsonStr));
      return existing.id != ext.id;
    }).toList();
    newList.add(json.encode(ext.toJson()));
    await prefs.setStringList(_extensionsKey, newList);
  }

  Future<void> uninstallExtension(String id) async {
    if (id == 'animeify_legacy') return;

    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_extensionsKey) ?? [];
    final newList = jsonList.where((jsonStr) {
      final ext = Extension.fromJson(json.decode(jsonStr));
      return ext.id != id;
    }).toList();

    await prefs.setStringList(_extensionsKey, newList);
    _providers.remove(id);
    _installedMods.remove(id);

    if (_activeProviderId == id) {
      _activeProviderId = 'animeify_legacy';
      await prefs.setString(_activeProviderKey, _activeProviderId);
    }

    if (_activeModId == id) {
      _activeModId = null;
      await prefs.remove(_activeModKey);
    }

    notifyListeners();
  }
}
