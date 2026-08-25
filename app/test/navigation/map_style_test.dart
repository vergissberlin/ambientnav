import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('transparent map style keeps only the background transparent', () async {
    final raw = await rootBundle.loadString(
      'assets/map_style/ambientnav-transparent.json',
    );
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final layers = (data['layers'] as List).cast<Map<String, dynamic>>();

    expect(layers.first['id'], 'background');
    expect(layers.first['type'], 'background');
    expect(
      layers.first['paint'],
      containsPair('background-color', 'rgba(0,0,0,0)'),
    );

    final roadLayerIds = layers
        .where((layer) => (layer['id'] as String).startsWith('highway_'))
        .map((layer) => layer['id'] as String)
        .toList();

    expect(roadLayerIds, isNotEmpty);
    expect(
      roadLayerIds,
      containsAll(<String>[
        'highway_path',
        'highway_minor',
        'highway_major_inner',
        'highway_motorway_inner',
      ]),
    );
  });
}
