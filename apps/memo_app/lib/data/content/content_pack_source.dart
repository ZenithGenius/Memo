import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:memo/data/content/content_pack.dart';

abstract interface class ContentPackSource {
  Future<ContentPack> load();
}

class AssetContentPackSource implements ContentPackSource {
  const AssetContentPackSource({this.assetPath = 'assets/content/pack.json'});
  final String assetPath;

  @override
  Future<ContentPack> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return ContentPack.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }
}

class InMemoryContentPackSource implements ContentPackSource {
  const InMemoryContentPackSource(this.pack);
  final ContentPack pack;

  @override
  Future<ContentPack> load() async => pack;
}
