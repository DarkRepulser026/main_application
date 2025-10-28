import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/preferences_service.dart';
import 'settings_screens.dart';

Widget dropdown(Color bgcolor, String name, Function updatePage, String unit, settings, textcolor,
    Color primary, rawName) {
  List<String> Items = settingSwitches[rawName] ?? ['˚C', '˚F'];

  return DropdownButton(
    elevation: 0,
    underline: Container(),
    dropdownColor: bgcolor,
    borderRadius: BorderRadius.circular(18),
    icon: Padding(
      padding: const EdgeInsets.only(left:10),
      child: Icon(Icons.arrow_drop_down_circle_rounded, color: primary,),
    ),
    style: GoogleFonts.comfortaa(
      color: textcolor,
      fontSize: 19,
      fontWeight: FontWeight.w300,
    ),
    alignment: Alignment.centerRight,
    value: unit,
    items: Items.map((item) {
      return DropdownMenuItem(
        value: item,
        child: Text(item),
      );
    }).toList(),
    onChanged: (Object? value) {
      HapticFeedback.mediumImpact();
      settings[rawName] = value;
      updatePage(rawName, value);
    }
  );
}

Widget circleBorderIcon(IconData icon, context) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(30),
    ),
    width: 50,
    height: 50,
    child: Center(child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24,)),
  );
}

class SettingsEntry extends StatelessWidget {
  final IconData icon;
  final String text;
  final String rawText;
  final String selected;
  final Function update;

  const SettingsEntry({super.key, required this.icon, required this.text, required this.rawText,
  required this.selected, required this.update});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              List<String> options = settingSwitches[rawText] ?? [""];
              return AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 10, left: 0),
                          child: Text(text, style: const TextStyle(fontSize: 22),),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List<Widget>.generate(options.length, (int index) {
                            return RadioListTile<String>(
                              title: Text(options[index], style: const TextStyle(fontSize: 18)),
                              value: options[index],
                              groupValue: selected,
                              onChanged: (String? value) {
                                HapticFeedback.mediumImpact();
                                update(options[index]);
                                Navigator.pop(context, value);
                              },
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              );
            }
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 14),
        child: Row(
          children: [
            circleBorderIcon(icon, context),
            const SizedBox(width: 20,),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(fontSize: 20, height: 1.2),),
                  Text(selected, style: TextStyle(color: Theme.of(context).colorScheme.outline,
                      fontSize: 15, height: 1.2),)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SwitchSettingEntry extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final Function update;

  const SwitchSettingEntry({super.key, required this.icon, required this.text,
    required this.selected, required this.update});

  static const WidgetStateProperty<Icon> thumbIcon = WidgetStateProperty<Icon>.fromMap(
    <WidgetStatesConstraint, Icon>{
      WidgetState.selected: Icon(Icons.check),
      WidgetState.any: Icon(Icons.close),
    },
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 14),
      child: Row(
        children: [
          circleBorderIcon(icon, context),
          const SizedBox(width: 20,),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 20, height: 1.2),),),
          Switch(
            value: selected,
            onChanged: (bool value) {
              HapticFeedback.mediumImpact();
              update(value);
            },
            thumbIcon: thumbIcon,
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  void goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return  Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading:
            IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary,),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  goBack();
                }),
            title: Text('Settings', style: const TextStyle(fontSize: 30),),
            pinned: false,
          ),

          const SliverToBoxAdapter(
            child: NewSettings(),
          ),

        ],
      ),
    );
  }
}

class NewSettings extends StatelessWidget {
  const NewSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            MainSettingEntry(
              title: 'Appearance',
              desc: 'Theme, colors, and image settings',
              icon: Icons.palette_outlined,
              pushTo: const AppearancePage(),
            ),
            MainSettingEntry(
              title: 'General',
              desc: 'Time format, date format, and other general settings',
              icon: Icons.tune,
              pushTo: const GeneralSettingsPage(),
            ),
            MainSettingEntry(
              title: 'Units',
              desc: 'Temperature, precipitation, and wind units',
              icon: Icons.straighten,
              pushTo: const UnitsPage(),
            ),
            MainSettingEntry(
              title: 'Layout',
              desc: 'Customize the order of weather widgets',
              icon: Icons.widgets_outlined,
              pushTo: const LayoutPage(),
            ),
            MainSettingEntry(
              title: 'About',
              desc: 'App information and credits',
              icon: Icons.info_outline,
              pushTo: const AboutPage(),
            ),
          ],
        ),
      ),
    );
  }
}