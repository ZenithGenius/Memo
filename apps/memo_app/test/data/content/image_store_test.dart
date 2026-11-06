import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/image_store.dart';

void main() {
  late Directory dir;
  late ImageStore store;
  // SHA-256 de « abc ».
  const abc =
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  final bytes = Uint8List.fromList(utf8.encode('abc'));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('memo-images');
    store = ImageStore(Directory('${dir.path}/images'));
  });
  tearDown(() => dir.delete(recursive: true));

  test('enregistre une image sous son empreinte', () async {
    expect(await store.has(abc), isFalse);
    expect(await store.save(abc, bytes), isTrue);
    expect(await store.has(abc), isTrue);
    expect(await store.fileFor(abc).readAsBytes(), bytes);
  });

  test('refuse un contenu qui ne correspond pas à son empreinte', () async {
    expect(
      await store.save(abc, Uint8List.fromList(utf8.encode('abd'))),
      isFalse,
    );
    expect(await store.has(abc), isFalse);
  });
}
