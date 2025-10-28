import 'dart:io';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

import '../../api_key.dart';
import 'caching_service.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getPlaceName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon).timeout(const Duration(seconds: 5));
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final locality = place.locality ?? '';
        final country = place.country ?? '';
        final result = (locality.isNotEmpty ? locality : '') + (locality.isNotEmpty && country.isNotEmpty ? ', ' : '') + (country.isNotEmpty ? country : '');
        if (result.trim().isNotEmpty) return result;
      }
    } catch (e) {
      if (kDebugMode) print('Reverse geocode failed: $e');
    }
    return 'Unknown Location';
  }

  static Future<List<String>> getRecommendation(String query, String searchProvider) async {
    query = _sanitizeQuery(query);
    if (query == '') {
      return [];
    }

    if (searchProvider == "weatherapi") {
      return _getWapiRecommendation(query);
    } else {
      return _getOMRecommendation(query);
    }
  }

  static Future<List<String>> _getWapiRecommendation(String query) async {
    var params = {
      'key': wapi_key,
      'q': query,
    };
    var url = Uri.https('api.weatherapi.com', 'v1/search.json', params);

    var jsonbody = [];
    try {
      var file = await cacheManager.getSingleFile(url.toString(), 
        headers: {'cache-control': 'private, max-age=120'});
      var response = await file.readAsString();
      jsonbody = jsonDecode(response);
    } on SocketException {
      return [];
    }

    List<String> recommendations = [];
    for (var item in jsonbody) {
      recommendations.add(json.encode(item));
    }

    return recommendations;
  }

  static Future<List<String>> _getOMRecommendation(String query) async {
    var params = {
      'name': query,
      'count': '10',
    };

    var url = Uri.https('geocoding-api.open-meteo.com', 'v1/search', params);

    var jsonbody = [];
    try {
      var file = await cacheManager.getSingleFile(url.toString(), 
        key: "$query, open-meteo search",
        headers: {'cache-control': 'private, max-age=120'})
        .timeout(const Duration(seconds: 4));
      var response = await file.readAsString();
      jsonbody = jsonDecode(response)["results"];
    } catch(e) {
      return [];
    }

    List<String> recommendations = [];
    for (var item in jsonbody) {
      String pre = json.encode(item);

      if (!pre.contains('"admin1"')) {
        item["region"] = "";
      } else {
        item["region"] = item['admin1'];
      }

      if (!pre.contains('"country"')) {
        item["country"] = "";
      }

      String x = json.encode(item);
      x = x.replaceAll('latitude', "lat");
      x = x.replaceAll('longitude', "lon");

      recommendations.add(x);
    }
    return recommendations;
  }

  /// Sanitizes the input query string by removing unsafe characters and limiting length
  static String _sanitizeQuery(String input) {
    final safeInput = input.replaceAll(RegExp(r'[^\w\s,\-]'), '');
    final trimmedInput = safeInput.trim();
    return trimmedInput.length > 100 ? trimmedInput.substring(0, 100) : trimmedInput;
  }
}