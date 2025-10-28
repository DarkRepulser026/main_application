import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../api_key.dart';
import '../../weather_refact.dart';
import 'caching_service.dart';
import 'color_service.dart';

String backdropCorrection(String text) {
  return textBackground[text] ?? 'clear_sky3.jpg';
}

List<String> assetImageCredit(String name){
  return assetPhotoCredits[name] ?? ["", "", ""];
}

class ImageService {
  final Image image;
  final String username;
  final String userLink;
  final String photoLink;
  final Color textRegionColor;

  const ImageService({
    required this.image,
    required this.username,
    required this.userLink,
    required this.photoLink,
    required this.textRegionColor,
  });

  static Future<ImageService> getUnsplashCollectionImage(String condition, String loc) async {

    String collectionId = conditionToCollection[condition] ?? 'XMGA2-GGjyw';

    final params = {
      'client_id': unsplashAccessKey,
      'collections': collectionId,
      'content_filter' : 'high',
      'count': '1',
    };

    final url = Uri.https('api.unsplash.com', 'photos/random', params);

    var file = await XCustomCacheManager.fetchData(url.toString(), "$condition $loc unsplash");
    var response2 = await file[0].readAsString();
    var unsplashBody = jsonDecode(response2);

    final String image_path = unsplashBody[0]["urls"]["raw"] + "&w=2500";
    Image image = Image(image: CachedNetworkImageProvider(image_path, cacheManager: customImageCacheManager),
        fit: BoxFit.cover, width: double.infinity, height: double.infinity);

    final String _userLink = (unsplashBody[0]["user"]["links"]["html"]) ?? "";
    final String _userName = unsplashBody[0]["user"]["name"] ?? "";

    final String _photoLink = unsplashBody[0]["links"]["html"] ?? "";

    Color textRegionColor = Colors.black; // Placeholder

    return ImageService(
      image: image,
      username: _userName,
      userLink: _userLink,
      photoLink: _photoLink,
      textRegionColor: textRegionColor,
    );
  }

  static Future<ImageService> getAssetImage(String condition) async {

    final String imagePath = backdropCorrection(condition);
    final Image image = Image.asset("assets/backdrops/$imagePath", fit: BoxFit.cover,
      width: double.infinity, height: double.infinity,);
    final List<String> credits = assetImageCredit(condition);

    final String _photoLink = credits[0];
    final String _userName = credits[1];
    final String _userLink = credits[2];

    Color textRegionColor = await getBottomLeftColor(image.image);

    return ImageService(
      image: image,
      username: _userName,
      userLink: _userLink,
      photoLink: _photoLink,
      textRegionColor: textRegionColor
    );

  }

  static Future<ImageService> getImageService(String condition, String loc, String imageSource) async {

    if (imageSource == "network") {
      try {
        ImageService i = await getUnsplashCollectionImage(condition, loc);
        return i;
      }
      catch (e) {
        if (kDebugMode) {
          String error = e.toString().replaceAll(unsplashAccessKey, "<key>");
          print(error);
        }
        return await getAssetImage(condition);
      }
    }
    else {
      return await getAssetImage(condition);
    }
  }
}

class FadingImageWidget extends StatelessWidget {
  final Image? image;

  const FadingImageWidget({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey(image.hashCode),
              child: (image == null)
                  ? Container(color: Theme.of(context).colorScheme.inverseSurface,)
                  : image,
            ),
          ),
          //Add a slight tint to make the text more legible
          Container(color: const Color.fromARGB(30, 0, 0, 0),)
        ]
    );
  }
}