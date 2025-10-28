import '../decoders/decode_OM.dart';

class WeatherCurrent {
  final String condition;
  final double tempC;
  final int humidity;
  final double feelsLikeC;
  final int uv;
  final double precipMm;

  final double windKph;
  final int windDirA;

  WeatherCurrent({
    required this.condition,
    required this.tempC,
    required this.humidity,
    required this.feelsLikeC,
    required this.uv,
    required this.precipMm,
    required this.windKph,
    required this.windDirA,
  });
}

class WeatherDay {
  final String condition;

  final DateTime date;

  final double minTempC;
  final double maxTempC;

  final List<WeatherHour> hourly;

  final int precipProb;
  final double totalPrecipMm;

  final double windKph;
  final int windDirA;

  final int uv;

  WeatherDay ({
    required this.condition,
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.hourly,
    required this.precipProb,
    required this.totalPrecipMm,
    required this.windKph,
    required this.windDirA,
    required this.uv,
  });
}

class WeatherHour {
  final double tempC;

  final DateTime time;

  final String condition;
  final double precipMm;
  final int precipProb;
  final double windKph;
  final int windDirA;
  final double windGustKph;
  final int uv;

  WeatherHour({
    required this.tempC,
    required this.time,
    required this.condition,
    required this.precipMm,
    required this.precipProb,
    required this.windKph,
    required this.windDirA,
    required this.windGustKph,
    required this.uv,
  });
}

class WeatherSunStatus {
  final DateTime sunrise;
  final DateTime sunset;
  final double sunstatus;

  WeatherSunStatus({
    required this.sunrise,
    required this.sunset,
    required this.sunstatus,
  });
}

class WeatherAlert {
  final String headline;
  final DateTime? start;
  final DateTime? end;
  final String desc;
  final String event;
  final String urgency;
  final String severity;
  final String certainty;
  final String areas;

  const WeatherAlert({
    required this.headline,
    required this.start,
    required this.end,
    required this.desc,
    required this.event,
    required this.urgency,
    required this.severity,
    required this.certainty,
    required this.areas,
  });
}

class WeatherRain15Minutes {
  final String text;
  final int timeTo;
  final double precipSumMm;
  final List<double> precipListMm;

  WeatherRain15Minutes({
    required this.text,
    required this.timeTo,
    required this.precipSumMm,
    required this.precipListMm,
  });
}

class WeatherAqi {
  final int aqiIndex;

  WeatherAqi({
    required this.aqiIndex,
  });
}

class WeatherMinMaxTemp {
  final double minTempC;
  final double maxTempC;

  WeatherMinMaxTemp({
    required this.minTempC,
    required this.maxTempC,
  });
}

class WeatherData {
  final WeatherCurrent current;
  final List<WeatherDay> days;
  final WeatherSunStatus sunStatus;
  final List<WeatherAlert> alerts;
  final WeatherRain15Minutes? minutely15Precip;
  final List<WeatherMinMaxTemp> dailyMinMaxTemp;
  final List<dynamic> hourly72;
  final WeatherAqi aqi;
  final double lat;
  final double lng;
  final String place;
  final String provider;
  final DateTime fetchDatetime;
  final DateTime updatedTime;
  final DateTime localTime;
  final bool isOnline;

  WeatherData({
    required this.current,
    required this.days,
    required this.sunStatus,
    required this.alerts,
    required this.minutely15Precip,
    required this.dailyMinMaxTemp,
    required this.hourly72,
    required this.aqi,
    required this.lat,
    required this.lng,
    required this.place,
    required this.provider,
    required this.fetchDatetime,
    required this.updatedTime,
    required this.localTime,
    required this.isOnline,
  });

  static Future<WeatherData> getFullData(String placeName, String latLon, String provider) async {
    List<String> split = latLon.split(",");
    double lat = double.parse(split[0]);
    double lng = double.parse(split[1]);

    return oMGetWeatherData(lat, lng, placeName);
  }
}

enum WeatherError {
  locationNotFound,
  networkError,
  apiError,
  parsingError,
  unknownError,
}