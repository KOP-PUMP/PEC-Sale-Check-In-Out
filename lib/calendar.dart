import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kop_checkin/api/api.dart';
import 'package:kop_checkin/model/user.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'package:month_year_picker/month_year_picker.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  bool _isLoadingAttendancePage = false;
  List<dynamic> resData = [];
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  String _day = DateFormat('dd MMMM yyyy').format(DateTime.now());

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getRowCheckin(); // Load data on init
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getRowCheckin(); // Refetch data whenever dependencies change (including when navigating to this screen)
  }

  Future<void> getRowCheckin() async {
    try {
      setState(() {
        _isLoadingAttendancePage = true;
      });

      print({'user_code': Users.id, 'doc_date': _day});
      var res = await http.post(Uri.parse(API.getRowCheck), body: {
        'user_code': Users.id,
        'doc_date': _day
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        if (res.body.contains('<br />') || res.body.contains('<b>Notice</b>') || res.body.isEmpty) {
          return;
        } else {
          var resBody = jsonDecode(res.body);
          setState(() {
            resData = resBody;
          });
        }
      } else {
        debugPrint("Error get attendance : Error code ${res.statusCode}");
        showSnackBar("Error get attendance : Error code ${res.statusCode}");
        setState(() {
          resData = [];
        });
      }
    } catch (e) {
      debugPrint("Network Error : $e ");
      showSnackBar("Network Error : Cannot connect to database");
      setState(() {
        resData = [];
      });
    } finally {
      setState(() {
        _isLoadingAttendancePage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: screenHeight / 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      "My Attendance",
                      style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'NexaBold',
                          fontSize: screenWidth / 18),
                    ),
                  ),
                ),
              ],
            ),
            Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 20),
                  child: Text(
                    _day,
                    style: TextStyle(
                        color: Colors.black54,
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth / 18),
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(top: 20),
                  child: GestureDetector(
                    onTap: () async {
                      int nowyear = DateTime.now().year.toInt();
                      final month = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(nowyear),
                        lastDate: DateTime(2099),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                  primary: primary,
                                  secondary: primary,
                                  onSecondary: Colors.white),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: primary,
                                ),
                              ),
                              textTheme: const TextTheme(
                                headlineMedium:
                                    TextStyle(fontFamily: 'NexaBold'),
                                labelSmall: TextStyle(fontFamily: 'NexaBold'),
                                labelLarge: TextStyle(fontFamily: 'NexaBold'),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (month != null) {
                        setState(() {
                          _day = DateFormat('dd MMMM yyyy').format(month);
                        });
                        getRowCheckin(); // Refresh data on date change
                      }
                    },
                    child: Text(
                      'Pick Date',
                      style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'NexaBold',
                          fontSize: screenWidth / 18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: screenHeight / 1.45,
              child: _isLoadingAttendancePage
                  ? const Center(child: CircularProgressIndicator())
                  : resData.isNotEmpty
                      ? ListView.builder(
                          itemCount: resData.length,
                          itemBuilder: (context, index) {
                            List list = resData;
                            return list[index]['doc_date'] == _day
                                ? Container(
                                    margin: const EdgeInsets.only(
                                        top: 12, right: 6, left: 6, bottom: 12),
                                    height: screenHeight / 2.5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.only(),
                                                  decoration: BoxDecoration(
                                                      color: primary,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  20))),
                                                  child: Center(
                                                    child: Text(
                                                        'Loc: ${list[index]['location_index']}',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'NexaBold',
                                                          fontSize:
                                                              screenWidth / 20,
                                                          color: Colors.white,
                                                        )),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Check In",
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'NexaBold',
                                                          fontSize:
                                                              screenWidth / 20,
                                                          color: Colors.white),
                                                    ),
                                                    Text(list[index]['checkin'],
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'NexaBold',
                                                            fontSize:
                                                                screenWidth /
                                                                    24,
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Check Out",
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'NexaBold',
                                                          fontSize:
                                                              screenWidth / 20,
                                                          color: Colors.white),
                                                    ),
                                                    Text(
                                                        list[index]['checkout'],
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'NexaBold',
                                                            fontSize:
                                                                screenWidth /
                                                                    24,
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          child: Column(
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    "Customer : ${list[index]['customer']}",
                                                    style: TextStyle(
                                                        fontFamily: 'NexaBold',
                                                        fontSize:
                                                            screenWidth / 24,
                                                        color: Colors.black54)),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    "Remark : ${list[index]['remark']}",
                                                    style: TextStyle(
                                                        fontFamily: 'NexaBold',
                                                        fontSize:
                                                            screenWidth / 24,
                                                        color: Colors.black54)),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    "Companion : ${list[index]['companion_name'] ?? ""}",
                                                    style: TextStyle(
                                                        fontFamily: 'NexaBold',
                                                        fontSize:
                                                            screenWidth / 24,
                                                        color: Colors.black54)),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    "Vehicle : ${list[index]['vehicle_name'] ?? ""}",
                                                    style: TextStyle(
                                                        fontFamily: 'NexaBold',
                                                        fontSize:
                                                            screenWidth / 24,
                                                        color: Colors.black54)),
                                              ),
                                              Text(
                                                  "Location : ${list[index]['location']}",
                                                  style: TextStyle(
                                                      fontFamily: 'NexaBold',
                                                      fontSize:
                                                          screenWidth / 24,
                                                      color: Colors.black54)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                : const SizedBox();
                          },
                        )
                      : const Center(
                          child: Text(
                            "There are no records for today.",
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
