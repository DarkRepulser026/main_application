import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../api_key.dart';
import '../decoders/decode_OM.dart';
import '../models/weather_data.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';

class WeatherProvider with ChangeNotifier {
  WeatherData? _weatherData;
  ImageService? _imageService;
  bool _isLoading = false;
  String? _error;

  WeatherData? get weatherData => _weatherData;
  ImageService? get imageService => _imageService;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Fetching weather...');
      Position position;
      try {
        position = await LocationService.getCurrentPosition().timeout(const Duration(seconds: 10));
        print('Position: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Location failed: $e, using default');
        position = Position(longitude: 105.8342, latitude: 21.0278, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0); // Hanoi
      }
      String placeName = await LocationService.getPlaceName(position.latitude, position.longitude).timeout(const Duration(seconds: 10));
      print('Place: $placeName');
      WeatherData data = await oMGetWeatherData(position.latitude, position.longitude, placeName).timeout(const Duration(seconds: 30));
      print('Weather data fetched');
      _weatherData = data;

      // Load image
      try {
        _imageService = await ImageService.getImageService(data.current.condition, placeName, 'network').timeout(const Duration(seconds: 10));
        print('Image loaded');
      } catch (e) {
        print('Image load failed: $e');
        _imageService = null; // Continue without image
      }
    } catch (e) {
      print('Error fetching weather: $e');
      if (e.toString().contains('no wifi')) {
        _error = 'No internet connection. Please check your connection and try again.';
      } else {
        _error = 'Failed to load weather data: ${e.toString().replaceAll(weatherApiKey, '[API_KEY]').replaceAll(unsplashAccessKey, '[API_KEY]').replaceAll(timezonedbKey, '[API_KEY]')}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      // Debug: confirm final state so UI doesn't stay stuck on loading
      try {
        print('fetchWeather complete: isLoading=$_isLoading, error=$_error, hasData=${_weatherData != null}');
      } catch (_) {}
    }
  }

  Future<void> updateLocation(String latLon, String location) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update settings with new location
      // Note: This assumes we have access to SettingsProvider, but we'll need to pass it or get it from context
      // For now, we'll just fetch the weather data

      const minDuration = Duration(milliseconds: 600);
      final minimumDelayFuture = Future.delayed(minDuration);

      // Get provider from settings - we'll need to access this somehow
      // For now, default to open-meteo
      final String provider = "open-meteo";

      final dataFetchFuture = WeatherData.getFullData(location, latLon, provider);

      final results = await Future.wait([
        dataFetchFuture,
        minimumDelayFuture,
      ]);

      WeatherData data = results[0];
      _weatherData = data;

      // Update image
      _imageService = await ImageService.getImageService(data.current.condition, data.place, 'network');

      // Keep it there while the image is animating
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      _error = 'Failed to update location: ${e.toString().replaceAll(weatherApiKey, '[API_KEY]').replaceAll(unsplashAccessKey, '[API_KEY]').replaceAll(timezonedbKey, '[API_KEY]')}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}