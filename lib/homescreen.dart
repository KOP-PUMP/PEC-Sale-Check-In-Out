// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kop_checkin/agendaJson.dart';
import 'package:kop_checkin/calendar.dart';
import 'package:kop_checkin/checkinscreen.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreeen extends StatefulWidget {
  const HomeScreeen({super.key});

  @override
  State<HomeScreeen> createState() => _HomeScreeenState();
}

class _HomeScreeenState extends State<HomeScreeen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  int currerntIndex = 1;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarDay,
    FontAwesomeIcons.check,
    FontAwesomeIcons.calendarXmark,
    // FontAwesomeIcons.print
  ];

  void changePage(int newIndex) {
    setState(() {
      currerntIndex = newIndex;
    });
  }



  Future<Position> _getCurrentLocation() async {
    bool serviceEnable = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnable) {
      return Future.error('Location service are Disable');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissino are denied, we cannot request');
    }
    return Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: IndexedStack(
        index: currerntIndex,
        children: [
          CalendarScreen(),
          CheckinScreen(() {
            _getCurrentLocation().then((value) {
              setState(() {
                Users.lat = value.latitude;
                Users.long = value.longitude;
              });
            });
            print('${Users.lat} ${Users.long}');
          }),
          CalendarExample(),
          // ColorPickerDemo(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(40)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(2, 2))
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>{
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      changePage(i);
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              navigationIcons[i],
                              color:
                                  i == currerntIndex ? primary : Colors.black54,
                              size: i == currerntIndex ? 30 : 26,
                            ),
                            i == currerntIndex
                                ? Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    height: 3,
                                    width: 22,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(40)),
                                      color: primary,
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              }
            ],
          ),
        ),
      ),
    );
  }
}
