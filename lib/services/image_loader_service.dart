import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImageLoaderService {
  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List?> loadImageBytes(String imageUrl) async {
    // Si ya está en cache, devolverla
    if (_cache.containsKey(imageUrl)) {
      return _cache[imageUrl];
    }

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Flutter Web App',
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Guardar en cache para futuras cargas
        _cache[imageUrl] = bytes;

        return bytes;
      } else {
        if (kDebugMode) {
          print('Error cargando imagen: ${response.statusCode} - $imageUrl');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Excepción cargando imagen: $e - $imageUrl');
      }
      return null;
    }
  }

  static void clearCache() {
    _cache.clear();
  }

  static void removeFromCache(String imageUrl) {
    _cache.remove(imageUrl);
  }
}