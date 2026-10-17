import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/draft_store.dart';

class SharedPrefsDraftStore implements DraftStore {
  static const _key = 'upload.draft.v1';

  @override
  Future<StoredDraft?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return null;
    try {
      return StoredDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A corrupt snapshot must never block the upload tab.
      return null;
    }
  }

  @override
  Future<void> save(StoredDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
