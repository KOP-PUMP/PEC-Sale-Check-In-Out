import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:kop_checkin/homescreen.dart';
import 'package:kop_checkin/login.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:kop_checkin/services/location_service.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:kop_checkin/services/location_service.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter_android_developer_mode/flutter_android_developer_mode.dart';
import 'package:timezone/standalone.dart' as tz;

void main() async {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: KeyboardVisibilityProvider(
        child: AuthCheck(),
      ),
      localizationsDelegates: [MonthYearPickerLocalizations.delegate],
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool userAvailable = false;
  late SharedPreferences sharedPreferences;
  bool developerOptionsEnabled = false;
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _startLocationService();
    checkForUpdate();
    updateDevMode();
  }

  void updateDevMode() async {
    bool isDevMode =
        await FlutterAndroidDeveloperMode.isAndroidDeveloperModeEnabled;
    if (isDevMode) {
      _showMyDialog(
          'Developer Mode Warning', 'Close the Developer Mode in your phone');
      Timer(const Duration(milliseconds: 5000), () {
        exit(0);
      });
    }
  }

  Future<void> _showMyDialog(String title, String text) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _startLocationService() async {
    LocationService().initialize();
    LocationService().getLatetude().then((value) {
      setState(() {
        Users.lat = value!;
      });
      LocationService().getLongtetude().then((value) {
        setState(() {
          Users.long = value!;
        });
      });
    });
  }

  Future<void> checkForUpdate() async {
    // print('checking for Update');
    InAppUpdate.checkForUpdate().then((info) {
      setState(() {
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          // print('update available');
          update();
        }
      });
    }).catchError((e) {
      // print(e.toString());
    });
  }

  void update() async {
    // print('Updating');
    await InAppUpdate.startFlexibleUpdate();
    InAppUpdate.completeFlexibleUpdate().then((_) {}).catchError((e) {
      // print(e.toString());
    });
  }

  void _getCurrentUser() async {
    sharedPreferences = await SharedPreferences.getInstance();
    try {
      if (sharedPreferences.getString('employeeUser') != '') {
        setState(() {
          Users.username = sharedPreferences.getString('username')!;
          // Users.name_surname_en =
          //     sharedPreferences.getString('name_surname_en')!;
          // Users.name_surname_th =
          //     sharedPreferences.getString('name_surname_th')!;
          Users.pec_group = sharedPreferences.getString('pec_group')!;
          Users.department = sharedPreferences.getString('department')!;
          Users.position = sharedPreferences.getString('position')!;
          Users.id = sharedPreferences.getString('employeeID')!;
          userAvailable = true;
        });
      }
    } catch (e) {
      setState(() {
        userAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return userAvailable
        ? const HomeScreeen()
        : const KeyboardVisibilityProvider(
            child: LoginScreen(),
          );
  }
}
