import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/data/services/location_service.dart';
import 'package:weather_app/data/services/preferences_service.dart';
import 'package:weather_app/data/services/widget_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../screens/settings_page.dart';


String generateSimplifier(var split) {
  return "${split["name"]}, ${split["lat"].toStringAsFixed(2)}, ${split["lon"].toStringAsFixed(2)}";
}

bool isUppercase(String str) {
  return str == str.toUpperCase();
}

String generateAbbreviation(String countryName) {
  List<String> words = countryName.split(' ');

  if (words.length == 1) {
    return countryName;
  } else {
    String abbreviation = '';
    for (String word in words) {
      if (word.isNotEmpty && isUppercase(word[0])) {
        abbreviation += word[0];
      }
    }
    return abbreviation;
  }
}

class MySearchWidget extends StatefulWidget {
  final place;
  final updateLocation;
  final isTabletMode;

  const MySearchWidget(
      {super.key,
      required this.place,
      required this.updateLocation,
      required this.isTabletMode});

  @override
  _MySearchWidgetState createState() => _MySearchWidgetState();
}

class _MySearchWidgetState extends State<MySearchWidget> {

  final ValueNotifier<List<String>> recommend = ValueNotifier<List<String>>([]);
  late ValueNotifier<List<String>> favorites;

  @override
  void initState() {
    super.initState();
    favorites = ValueNotifier<List<String>>(getFavorites());
  }

  List<String> getFavorites() {
    final ifnot = ["{\n        \"id\": 2651922,\n        \"name\": \"Nashville\",\n        \"region\": \"Tennessee\",\n        \"country\": \"United States of America\",\n        \"lat\": 36.17,\n        \"lon\": -86.78,\n        \"url\": \"nashville-tennessee-united-states-of-america\"\n    }"];
    final used = PreferenceUtils.getStringList('favorites', ifnot);
    return used;
  }

  void updateFav(List<String> fav) {
    PreferenceUtils.setStringList('favorites', fav);

    //Save the favorites so the widgets can access them when selecting location
    String jsonString = jsonEncode(fav);
    WidgetService.saveData('widget.favorites', jsonString);

    setState(() {
      favorites.value = fav;
    });
  }

  void updateRec(List<String> rec) {
    setState(() {
      recommend.value = rec;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTabletMode) {
      return HeroSearchPage(
          place: widget.place,
          recommend: recommend,
          updateRec: updateRec,
          updateLocation: widget.updateLocation,
          favorites: favorites,
          updateFav: updateFav,
          isTabletMode: true);
    }

    return SearchBar(
        recommend: recommend,
        updateLocation: widget.updateLocation,
        updateFav: updateFav,
        favorites: favorites,
        updateRec: updateRec,
        place: widget.place);
  }
}

class SearchBar extends StatelessWidget {
  final ValueNotifier<List<String>> recommend;
  final Function updateLocation;
  final Function updateFav;
  final ValueNotifier<List<String>> favorites;
  final Function updateRec;
  final String place;

  SearchBar(
      {super.key,
      required this.recommend,
      required this.updateLocation,
      required this.updateFav,
      required this.favorites,
      required this.updateRec,
      required this.place});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        child: Hero(
          tag: 'searchBarHero',
          child: Container(
            height: 67,
            margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 15, left: 28, right: 28),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(33)),
            padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            child: Material(
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 13),
                    child: Icon(Icons.place_outlined,
                        color: Theme.of(context).colorScheme.primary, size: 25),
                  ),
                  Expanded(
                      child: Text(
                    place,
                    style: const TextStyle(fontSize: 23),
                    maxLines: 1,
                  )),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.primary, size: 25),
                    onPressed: () {
                      HapticFeedback.mediumImpact();

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        onTap: () {
          HapticFeedback.lightImpact();

          // i had to use my own transition because the default sliding doesn't look good here
          Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HeroSearchPage(
                    place: place,
                    recommend: recommend,
                    updateRec: updateRec,
                    updateLocation: updateLocation,
                    favorites: favorites,
                    updateFav: updateFav,
                    isTabletMode: false,
                  ),
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 250),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 0.1);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;

                final tween = Tween(begin: begin, end: end);
                final curvedAnimation =
                    CurvedAnimation(parent: animation, curve: curve);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: tween.animate(curvedAnimation),
                    child: child,
                  ),
                );
              }));
        },
      ),
    );
  }
}

class HeroSearchPage extends StatefulWidget {
  final String place;
  final recommend;
  final updateRec;
  final updateLocation;
  final favorites;
  final updateFav;
  final isTabletMode;

  const HeroSearchPage(
      {super.key,
      required this.place,
      required this.recommend,
      required this.updateRec,
      required this.updateLocation,
      required this.favorites,
      required this.updateFav,
      required this.isTabletMode});

  @override
  State<HeroSearchPage> createState() => _HeroSearchPageState(
      place: place,
      recommend: recommend,
      updateRec: updateRec,
      updateLocation: updateLocation,
      favorites: favorites,
      updateFav: updateFav,
      isTabletMode: isTabletMode);
}

class _HeroSearchPageState extends State<HeroSearchPage> {
  final String place;
  final recommend;
  final updateRec;
  final updateLocation;
  final favorites;
  final updateFav;
  final isTabletMode;

  _HeroSearchPageState(
      {required this.place,
      required this.recommend,
      required this.updateRec,
      required this.updateLocation,
      required this.favorites,
      required this.updateFav,
      required this.isTabletMode});

  String text = "";
  bool isEditing = false;

  String locationState = "unknown";
  String locationMessage = "unknown";
  String placeName = "-";
  String placeLatLon = "0.0, 0.0";
  String country = "-";
  String region = "-";

  Timer? _debounce;

  late final TextEditingController _controller;

  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (mounted) {
        var result = await LocationService.getRecommendation(
            query, context.read<SettingsProvider>().getSearchProvider);
        updateRec(result);
      }
    });
  }

  onSubmitted(String submitted) async {
    if (!isTabletMode) {
      Navigator.pop(context);
    }
    var rec = await LocationService.getRecommendation(
        submitted, context.read<SettingsProvider>().getSearchProvider);
    if (rec.isNotEmpty) {
      var split = json.decode(rec[0]);
      updateLocation('${split["lat"]}, ${split["lon"]}', removeDiacritics(split["name"]));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Unable to find place: $submitted"),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0)),
          ),
        );
      }
    }
  }

  onFavChanged(List<String> fav) {
    setState(() {
      updateFav(fav);
    });
  }

  onIsEditingChanged() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  findCurrentPosition() async {
    Position position;

    setState(() {
      locationState = "pending";
    });

    //start by getting the last position, so there is always some place showing, and then update it later
    try {
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        position = lastPosition;

        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        Placemark place = placemarks[0];

        setState(() {
          placeName = removeDiacritics(place.locality ?? place.subLocality ?? place.thoroughfare ?? place.subThoroughfare ?? "");
          country = place.isoCountryCode ?? place.country ?? "";
          region = place.administrativeArea ?? place.subAdministrativeArea ?? "";
          locationState = "enabled";
        });
      } else {
        // No last known position available, continue to get current position
        if (kDebugMode) print('No last known position available');
      }
    } catch (e) {
      // Handle system-level exceptions like DeadSystemException, or if no last known position
      if (kDebugMode) print('Last known position failed: $e');
      // Continue to try current position
    }

    try {
      position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 10)
          )
      );
    } on TimeoutException {
      setState(() {
        locationState = "disabled";
        locationMessage = "Location request timed out";
      });
      return "disabled";
    } on PermissionDeniedException {
      setState(() {
        locationState = "disabled";
        locationMessage = "Location permission denied";
      });
      return "disabled";
    } on LocationServiceDisabledException {
      setState(() {
        locationState = "disabled";
        locationMessage = "Location services are disabled";
      });
      return "disabled";
    } catch (e) {
      // Handle system-level exceptions like DeadSystemException
      if (e.toString().contains('DeadSystemException') ||
          e.toString().contains('DeadSystemRuntimeException')) {
        setState(() {
          locationState = "disabled";
          locationMessage = "Location service temporarily unavailable";
        });
        return "disabled";
      }
      setState(() {
        locationState = "disabled";
        locationMessage = "Unable to locate device";
      });
      return "disabled";
    }

    try {

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        placeName = place.locality ?? place.subLocality ?? place.thoroughfare ?? place.subThoroughfare ?? "";
        country = place.isoCountryCode ?? place.country ?? "";
        region = place.administrativeArea ?? place.subAdministrativeArea ?? "";
        locationState = "enabled";
      });

      await PreferenceUtils.setString('LastKnownPositionName', placeName);
      await PreferenceUtils.setString('LastKnownPositionCord', "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}");
      WidgetService.saveData("widget.lastKnownPlace", placeName); //save the name of the place to the widgets

    } on Error {

      if (!mounted) return;
      setState(() {
        placeName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });
    }
  }

  askGrantLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationState = "disabled";
        locationMessage = "Location services are disabled";
      });
      return "disabled";
    }
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationState = "disabled";
        locationMessage = "Location permission denied forever";
      });
      return "disabled";
    }
    String x = await checkIflocationState(true);
    if (x == "enabled") {
      await findCurrentPosition();
    }
  }

  Future<String> checkIflocationState([bool afterAsk = false]) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationState = "disabled";
        locationMessage = "Location services are disabled";
      });
      return "disabled";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationState = "deniedForever";
        locationMessage = "Location permission denied forever";
      });
      return "disabled";
    }
    if (permission == LocationPermission.denied) {
      setState(() {
        locationState = "denied";
        locationMessage = "Location permission is denied";
      });
      return "disabled";
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        locationState = "enabled";
      });
      return "enabled";
    }
    setState(() {
      locationState = "disabled";
      locationMessage = "Unable to locate device";
    });
    return "disabled";
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_){
      checkIflocationState().then((x) {
        if (x == "enabled") {
          WidgetsBinding.instance.addPostFrameCallback((_){
            findCurrentPosition();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isTabletMode ? Theme.of(context).colorScheme.surfaceContainer
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: isTabletMode ? Theme.of(context).colorScheme.surfaceContainer : Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        surfaceTintColor: Theme.of(context).colorScheme.outlineVariant,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: isTabletMode ? Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.primary, size: 23,),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ) : IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.primary, size: 25,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: (text == "") ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(right: 13),
                child: IconButton(
                  icon: Icon(
                    isEditing ? Icons.check : Icons.edit_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 25,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onIsEditingChanged();
                  },
                ),
              ),
            )
            : Container(),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(103),
          child: Hero(
            tag: 'searchBarHero',
            child: Container(
              height: 67,
              margin: const EdgeInsets.only(left: 27, right: 27, bottom: 20),
              decoration: BoxDecoration(
                  color: isTabletMode ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(33)
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: Material(
                    color: isTabletMode ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
                    child: TextField(
                      autofocus: false,
                      controller: _controller,
                      onChanged: (String to) async{
                        setState(() {
                          text = to;
                        });
                        _onSearchChanged(to);
                      },
                      onSubmitted: (String submission) {
                        HapticFeedback.lightImpact();
                        onSubmitted(submission);
                        /*
                        _controller.clear();
                        setState(() {
                          text = "";
                        });

                         */
                      },
                      cursorWidth: 2,
                      decoration: const InputDecoration(
                        hintText: 'search...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 19.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Align(
                key: ValueKey<bool>(text == ""),
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: buildRecommend(text, favorites, recommend,
                  updateLocation, onFavChanged, isEditing, locationState, locationMessage, askGrantLocationPermission,
                  placeName, country, region, placeLatLon, isTabletMode),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget buildRecommend(String text, ValueListenable<List<String>> favoritesListen,
    ValueListenable<List<String>> recommend, updateLocation, onFavChanged, isEditing, locationState, locationMessage,
    askGrantLocationPermission, placeName, country, region, placeLatLon, isTabletMode) {

  return ValueListenableBuilder(
    valueListenable: favoritesListen,
    builder: (context, value, child) {
      List<String> favorites = value;
      if (text == "") {
        return Padding(
          padding: const EdgeInsets.only(left: 30, top: 10, right: 30, bottom: 40),
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 475),
                childAnimationBuilder: (widget) =>
                  SlideAnimation(
                    horizontalOffset: 0.0,
                    verticalOffset: 50,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10, top: 2),
                        child: Icon(
                          Icons.gps_fixed, color: Theme.of(context).colorScheme.outline, size: 17,),
                      ),
                      Text("Current Location",
                        style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 18, height: 1.2),)
                    ],
                  ),
                  CurrentLocationWidget(locationState, locationMessage, askGrantLocationPermission,
                      placeName, country, region, updateLocation, context, placeLatLon, isTabletMode),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 0),
                          child: Icon(
                            Icons.star_outline, color: Theme.of(context).colorScheme.outline, size: 18,),
                        ),
                        Text("Favorites",
                          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 18, height: 1.2),)
                      ],
                    ),
                  ),
                  if (favorites.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child,
                          Animation<double> animation) {
                        return SizeTransition(
                            sizeFactor: animation, child: child);
                      },
                      child: favoritesOrReorder(isEditing, favorites, onFavChanged, updateLocation, context, isTabletMode),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
      else {
        return buildSearchResults(favorites, recommend, updateLocation, onFavChanged, isTabletMode);
      }
    }
  );
}

Widget buildSearchResults(List<String> favorites, ValueListenable<List<String>> recommend, updateLocation,
    onFavChanged, isTabletMode) {
  List<String> favoriteNarrow = [];
  for (int i = 0; i < favorites.length; i++) {
    var d = jsonDecode(favorites[i]);
    favoriteNarrow.add(generateSimplifier(d));
  }
  return ValueListenableBuilder(
      valueListenable: recommend,
      builder: (context, value, child) {
        List<String> rec = value;
        return Padding(
          padding: const EdgeInsets.only(
              top: 0, bottom: 30, left: 30, right: 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child,
                    Animation<double> animation) {
                  return SizeTransition(
                      sizeFactor: animation, child: child);
                },
                child: Container(
                    key: ValueKey<String>(rec.toString()),
                    decoration: BoxDecoration(
                      color: isTabletMode ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: rec.isEmpty
                        ? const EdgeInsets.all(0)
                        : const EdgeInsets.all(14),
                    child: Column(
                        children: List.generate(rec.length, (index) {
                          var split = json.decode(rec[index]);
                          String name = removeDiacritics(split["name"]);
                          String country = generateAbbreviation(split["country"]);
                          String region = split["region"];
                          String simplifier = generateSimplifier(split);

                          bool contained = favoriteNarrow.contains(simplifier);
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              updateLocation(
                                  '${split["lat"]}, ${split["lon"]}',
                                  split["name"]);
                              if (!isTabletMode) {
                                Navigator.pop(context);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 7, top: 5, bottom: 5),
                              child:
                              Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                        crossAxisAlignment : CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(
                                              fontSize: 19.5, height: 1.2),),
                                          Text("$region, $country", style: TextStyle(
                                              color: Theme.of(context).colorScheme.outline, fontSize: 14, height: 1.25))
                                        ],
                                      )
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (contained) {
                                        HapticFeedback.mediumImpact();
                                        int z = favoriteNarrow.indexOf(simplifier);
                                        favorites.removeAt(z);
                                        onFavChanged(favorites);
                                      }
                                      else{
                                        HapticFeedback.lightImpact();
                                        favorites.add(rec[index]);
                                        onFavChanged(favorites);
                                      }
                                    },
                                    icon: Icon(
                                      contained? Icons.star : Icons.star_outline,
                                      color: Theme.of(context).colorScheme.primary, size: 24,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        })
                    )
                )
            ),
          )
        );
      }
  );
}

Widget CurrentLocationWidget(locationState, locationMessage, askGrantLocationPermission,
    String placeName, String country, String region, updateLocation, context, placeLatLon, isTabletMode) {
  if (locationState == "denied") {
    return GestureDetector(
      onTap: () {
        askGrantLocationPermission();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 30),
        padding: const EdgeInsets.only(
            left: 25, right: 25, top: 23, bottom: 23),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixedDim,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Icon(Icons.gps_fixed,
              color: Theme.of(context).colorScheme.onPrimaryFixed, size: 19),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 2),
                child: Text("Grant Location Permission",
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryFixed, fontSize: 19),)
              ),
            ),
          ],
        ),
      ),
    );
  }
  if (locationState == "enabled" || locationState == "pending") {
    return GestureDetector(
      onTap: () {
        if (locationState == "enabled") {
          HapticFeedback.lightImpact();
          updateLocation(placeLatLon, placeName);
          if (!isTabletMode) {
            Navigator.pop(context);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 14, bottom: 30),
        padding: const EdgeInsets.only(
            left: 25, right: 25, top: 20, bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixedDim,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Expanded(
                child: Column(
                  crossAxisAlignment : CrossAxisAlignment.start,
                  children: [
                    Text(placeName, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryFixed, fontSize: 19.5, height: 1.2),),
                    Text("$region, $country", style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryFixed, fontSize: 14, height: 1.25),)
                  ],
                )
            ),
            locationState == "enabled"
                ? Icon(Icons.keyboard_arrow_right_rounded,
              color: Theme.of(context).colorScheme.onPrimaryFixed,)
                : CircularProgressIndicator(year2023: false, strokeWidth: 2.7,  color: Theme.of(context).colorScheme.onPrimaryFixed,
                  constraints: const BoxConstraints(maxWidth: 18, maxHeight: 18, minWidth: 18, minHeight: 18))
          ],
        ),
      ),
    );
  }
  return Container(
    margin: const EdgeInsets.only(top: 20, bottom: 30),
    padding: const EdgeInsets.only(
        left: 25, right: 25, top: 20, bottom: 20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryFixedDim,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      children: [
        Icon(Icons.gps_off,
          color: Theme.of(context).colorScheme.onPrimaryFixed, size: 19,),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2),
            child: Text(locationMessage, style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryFixed, fontSize: 19),)
          ),
        ),

      ],
    ),
  );
}

Widget favoritesOrReorder(isEditing, favorites, onFavChanged, updateLocation, context, isTabletMode) {
  if (isEditing) {
    return reorderFavorites(favorites, onFavChanged, isTabletMode, context);
  }
  else {
    return buildFavorites(favorites, updateLocation, context, isTabletMode);
  }
}

Widget buildFavorites(List<String> favorites, updateLocation, context, isTabletMode) {
  return SingleChildScrollView(
    child: Container(
        key: const ValueKey<String>("normal"),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isTabletMode ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
            children: List.generate(favorites.length, (index) {
              var split = json.decode(favorites[index]);
              String name = removeDiacritics(split["name"]);
              String country = generateAbbreviation(split["country"]);
              String region = split["region"];
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  HapticFeedback.lightImpact();
                  updateLocation(
                      '${split["lat"]}, ${split["lon"]}', split["name"]);
                  if (!isTabletMode) {
                    Navigator.pop(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 10, right: 7, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                            crossAxisAlignment : CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(
                                  fontSize: 19.5, height: 1.2),),
                              Text("$region, $country", style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline, fontSize: 14, height: 1.25))
                            ],
                          )
                      ),
                      Icon(Icons.keyboard_arrow_right_rounded, color: Theme.of(context).colorScheme.primary,)
                    ],
                  ),
                ),
              );
            })
        )
    ),
  );
}

Widget reorderFavorites(List<String> _items, onFavChanged, bool isTabletMode, context) {
  return Container(
    key: const ValueKey<String>("editing"),
    decoration: BoxDecoration(
      color: isTabletMode ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(30),
    ),
    child: ReorderableListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      proxyDecorator: (child, index, animation) => Material(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        for (int index = 0; index < _items.length; index += 1)
          reorderableItem(_items, index, onFavChanged, isTabletMode, context)
      ],
      onReorder: (int oldIndex, int newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final String item = _items.removeAt(oldIndex);
        _items.insert(newIndex, item);
        onFavChanged(_items);
      },
    )
  );
}

Widget reorderableItem(List<dynamic> items, index, onFavChanged, isTabletMode, context) {
  var split = json.decode(items[index]);
  String name = removeDiacritics(split["name"]);
  String country = generateAbbreviation(split["country"]);
  String region = split["region"];
  return Container(
    key: Key("$name, $country, $region"),
    color: isTabletMode ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surfaceContainer,
    child: Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 7, bottom: 7),
      child:
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.drag_indicator, color: Theme.of(context).colorScheme.outline,),
          ),
          Expanded(
              child: Column(
                crossAxisAlignment : CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                      fontSize: 19.5, height: 1.2),),
                  Text("$region, $country", style: TextStyle(
                      color: Theme.of(context).colorScheme.outline, fontSize: 14, height: 1.25))
                ],
              )
          ),
          IconButton(
            onPressed: () {
              items.removeAt(index);
              onFavChanged(items);
            },
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.primary, size: 23,
            ),
          )
        ],
      ),
    ),
  );
}

String removeDiacritics(String text) {
  // Vietnamese diacritic mappings
  const diacritics = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'È': 'E', 'É': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'Ì': 'I', 'Í': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'Ò': 'O', 'Ó': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'Ù': 'U', 'Ú': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'Ỳ': 'Y', 'Ý': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
    'đ': 'd', 'Đ': 'D',
  };
  
  String result = text;
  diacritics.forEach((key, value) {
    result = result.replaceAll(key, value);
  });
  
  return result;
}