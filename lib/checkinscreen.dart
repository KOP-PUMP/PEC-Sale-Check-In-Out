// ignore_for_file: non_constant_identifier_names
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kop_checkin/api/api.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:kop_checkin/model/user_model.dart';
import 'package:kop_checkin/services/location_service.dart';
import 'package:timezone/standalone.dart' as tz;


class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  /* Assuming in an async function */
  String? lat;
  String? long;
  String office = 'Bangkok';

  double screenHeight = 0;
  double screenWidth = 0;

  String checkIn2 = '';
  String checkIn = '--/--';
  String checkOut = '--/--';
  String locationCheckin = " ";
  String locationCheckout = " ";
  // var location_index = 1;
  bool _isLoading = false;
  List<UserModel> userList = []; // Initialize your user list
  UserModel? _selectedUser;

  String docdate = DateFormat('dd MMMM yyyy').format(DateTime.now());
  String nightdate = DateFormat('H').format(DateTime.now());

  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  bool check = false;
  late Position currentLocation;

  final _locationController = TextEditingController();
  final _customerController = TextEditingController();
  String customer = '';
  Timer? timer;

  final List<Marker> _list = [
    Marker(
        markerId: const MarkerId('1'),
        position: LatLng(Users.lat, Users.long),
        infoWindow: const InfoWindow(title: 'You are Here !'))
  ];

  final Completer<GoogleMapController> _controller = Completer();
  final List<Marker> _maker = [];

  List<String> officeProvince = [
    "Bangkok",
    "Rayong",
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _maker.addAll(_list);
    _getRecord();
    _startLocationService();
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

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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

  // Future<void> _showMyDialog() async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false, // user must tap button!
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Alert Mock App'),
  //         content: const SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Text('Please turn off the mock app'),
  //               // Text('Would you like to approve of this message?'),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Ok'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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

  Future addRecordDetails(
      String locationCheckin, location_index, time_in, timestamp_in) async {
    var res = await http.post(Uri.parse(API.getDocCheck), body: {
      'doc_date': DateFormat('dd MMMM yyyy').format(DateTime.now()),
      'user_code': Users.id,
    });
    if (res.statusCode == 200) {
      try {
        var resBody = jsonDecode(res.body);
        check = resBody['success'];
        if (check == true) {
          await http.post(Uri.parse(API.addCheckin), body: {
            'doc_date': docdate,
            'user_code': Users.id,
            'time': time_in,
            'checkin_out': 'IN',
            'location': locationCheckin.toString(),
            'location_index': location_index.toString(),
            'time_in': timestamp_in,
            'remark': _locationController.text.trim(),
            'longitude': Users.long.toString(),
            'latitude': Users.lat.toString(),
            'office': "",
            'customer': Users.customer
          });
        } else {
          setState(() {
            Users.location_index = 1;
          });
          await http.post(Uri.parse(API.addCheckin), body: {
            'doc_date': docdate,
            'user_code': Users.id,
            'time': time_in,
            'checkin_out': 'IN',
            'location': locationCheckin.toString(),
            'location_index': '1',
            'time_in': timestamp_in,
            'remark': _locationController.text.trim(),
            'longitude': Users.long.toString(),
            'latitude': Users.lat.toString(),
            'office': "",
            'customer': Users.customer
          });
        }
      } catch (e) {
        setState(() {
          Users.location_index = 1;
        });
        await http.post(Uri.parse(API.addCheckin), body: {
          'doc_date': docdate,
          'user_code': Users.id,
          'time': time_in,
          'checkin_out': 'IN',
          'location': locationCheckin.toString(),
          'location_index': '1',
          'time_in': timestamp_in,
          'remark': _locationController.text.trim(),
          'longitude': Users.long.toString(),
          'latitude': Users.lat.toString(),
          'office': "",
          'customer': Users.customer
        });
      }
    }
  }

  Future updateRecordDetails(
      String locationCheckout, location_index, time_out, timestamp_out) async {
    await http.post(Uri.parse(API.updateCheck), body: {
      'user_code': Users.id,
      'doc_date': docdate,
      'time': time_out,
      'time_out': timestamp_out,
      'location': locationCheckout.toString(),
      'location_index': location_index.toString(),
      'longitude': Users.long.toString(),
      'latitude': Users.lat.toString(),
    });
  }

  void _getRecord() async {
    var res = await http.post(Uri.parse(API.getDocCheck), body: {
      'doc_date': DateFormat('dd MMMM yyyy').format(DateTime.now()),
      'user_code': Users.id,
    });
    if (res.statusCode == 200) {
      try {
        var resBody = jsonDecode(res.body);
        setState(() {
          checkIn = resBody['checkin'];
          checkOut = resBody['checkout'];
          Users.location_index = int.parse(resBody['location_index']);
          _isLoading = true;
        });
        if (resBody['checkout'] != '--/--') {
          setState(() {
            Users.location_index = int.parse(resBody['location_index']) + 1;
            checkIn = '--/--';
            checkOut = '--/--';
            _isLoading = true;
          });
        }
        // ignore: empty_catches
      } catch (e) {}
    } else {
      setState(() {
        Users.location_index = 1;
      });
    }
    setState(() {
      _isLoading = true;
    });
  }

  void changeLocationIndex() async {
    var res = await http.post(Uri.parse(API.getDocCheck), body: {
      'doc_date': DateFormat('dd MMMM yyyy').format(DateTime.now()),
      'user_code': Users.id,
    });
    if (res.statusCode == 200) {
      try {
        var resBody = jsonDecode(res.body);
        setState(() {
          checkIn = resBody['checkin'];
          checkOut = resBody['checkout'];
          Users.location_index = int.parse(resBody['location_index']);
          _isLoading = true;
        });
        if (resBody['checkout'] != '--/--') {
          setState(() {
            Users.location_index = int.parse(resBody['location_index']) + 1;
            checkIn = '--/--';
            checkOut = '--/--';
            _isLoading = true;
          });
        }
        // ignore: empty_catches
      } catch (e) {}
    } else {
      setState(() {
        Users.location_index = 1;
      });
    }
  }

  // void _getOffice() async {
  //   var res = await http.post(Uri.parse(API.getDocCheck), body: {
  //     'doc_date': DateFormat('dd MMMM yyyy').format(DateTime.now()),
  //     'user_code': Users.id,
  //   });
  //   if (res.statusCode == 200) {
  //     try {
  //       var resBody = jsonDecode(res.body);
  //       setState(() {
  //         office = resBody['office_province'];
  //       });
  //       // ignore: empty_catches
  //     } catch (e) {}
  //   }
  // }

  Future _goToMe(double lat, double long) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(lat, long),
      zoom: 16,
    )));
    _maker.add(
      Marker(
        markerId: const MarkerId('2'),
        position: LatLng(lat, long),
        infoWindow: const InfoWindow(
            title: 'My Current Position', snippet: 'ที่อยุ๋ปัจจุบัน'),
      ),
    );
  }

  void clearItemBuilder() {
    PopupPropsMultiSelection.modalBottomSheet(
      showSearchBox: true,
      itemBuilder: null,
      // Other properties
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return _isLoading
        ? Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 30),
                    child: Text(
                      'Welcome ${Users.username}',
                      style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'NexaBold',
                          fontSize: screenWidth / 20),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Location ${Users.location_index}',
                            style: TextStyle(
                                color: Colors.black54,
                                fontFamily: 'NexaBold',
                                fontSize: screenWidth / 20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          child: RichText(
                            text: TextSpan(
                              text: DateTime.now().day.toString(),
                              style: TextStyle(
                                color: primary,
                                fontSize: screenWidth / 20,
                                fontFamily: 'NexaBold',
                              ),
                              children: [
                                TextSpan(
                                  text: DateFormat(' MMMM yyyy')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                      fontFamily: 'NexaBold',
                                      fontSize: screenWidth / 22,
                                      color: Colors.black54),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.only(top: 10),
                          child: Text(
                            "Today's Status",
                            style: TextStyle(
                                color: Colors.black54,
                                fontFamily: 'NexaBold',
                                fontSize: screenWidth / 20),
                          ),
                        ),
                      ),
                      Expanded(
                          child: StreamBuilder(
                              stream:
                                  Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                return Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    DateFormat('hh:mm:ss a')
                                        .format(DateTime.now()),
                                    style: TextStyle(
                                        fontFamily: 'NexaBold',
                                        fontSize: screenWidth / 18,
                                        color: Colors.black54),
                                  ),
                                );
                              }))
                    ],
                  ),
                  SizedBox(
                    width: 400,
                    height: 150,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(Users.lat, Users.long),
                        zoom: 17,
                      ),
                      markers: Set<Marker>.of(_maker),
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 30, bottom: 30),
                    height: 75,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(2, 2))
                      ],
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Check In",
                                style: TextStyle(
                                    fontFamily: 'NexaRegular',
                                    fontSize: screenWidth / 20,
                                    color: Colors.black54),
                              ),
                              Text(checkIn,
                                  style: TextStyle(
                                      fontFamily: 'NexaBold',
                                      fontSize: screenWidth / 18,
                                      color: Colors.black54)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Check Out",
                                style: TextStyle(
                                    fontFamily: 'NexaRegular',
                                    fontSize: screenWidth / 20,
                                    color: Colors.black54),
                              ),
                              Text(checkOut,
                                  style: TextStyle(
                                      fontFamily: 'NexaBold',
                                      fontSize: screenWidth / 18,
                                      color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: DropdownSearch<UserModel>(
                            items: userList,
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: "Customer",
                                filled: true,
                              ),
                            ),
                            onChanged: (UserModel? data) => setState(() {
                              Users.customer = data!.name.toString();
                              _selectedUser = data;
                            }),
                            selectedItem: _selectedUser,
                            asyncItems: (filter) => getData(filter),
                            compareFn: (i, s) => i.isEqual(s),
                            popupProps:
                                PopupPropsMultiSelection.modalBottomSheet(
                              showSearchBox: true,
                              itemBuilder: _customPopupItemBuilderExample2,
                              favoriteItemProps: FavoriteItemProps(
                                showFavoriteItems: true,
                                favoriteItems: (us) {
                                  var favorites = us
                                      .where((e) =>
                                          e.name.contains("O-0040") ||
                                          e.name.contains("O-0019") ||
                                          e.name.contains("O-0039"))
                                      .toList();
                                  // Sort favorites to ensure '0019' is first
                                  favorites.sort((a, b) {
                                    if (a.name.contains("O-0019")) {
                                      return -1;
                                    } else if (b.name.contains("O-0019")) {
                                      return 1;
                                    } else {
                                      return 0;
                                    }
                                  });
                                  return favorites;
                                },
                                favoriteItemBuilder:
                                    (context, item, isSelected) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[100]),
                                    child: Row(
                                      children: [
                                        Text(
                                          item.code + " " + item.nameEN,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.indigo),
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.only(left: 8)),
                                        isSelected
                                            ? const Icon(
                                                Icons.check_box_outlined)
                                            : const SizedBox.shrink(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textField("Remark", "Remark", _locationController),

                  // Row(
                  //   children: [
                  //     Container(
                  //       margin: const EdgeInsets.only(top: 10),
                  //       padding: const EdgeInsets.symmetric(horizontal: 20),
                  //       alignment: Alignment.centerLeft,
                  //       child: DropdownMenu<String>(
                  //         label: const Text('Office'),
                  //         textStyle: const TextStyle(
                  //           fontSize: 18,
                  //           color: Colors.black54,
                  //           fontFamily: 'NexaBold',
                  //         ),
                  //         initialSelection: dropdownValue,
                  //         dropdownMenuEntries: officeProvince
                  //             .map<DropdownMenuEntry<String>>((String value) {
                  //           return DropdownMenuEntry<String>(
                  //               value: value, label: value);
                  //         }).toList(),
                  //         onSelected: (String? value) {
                  //           setState(() {
                  //             dropdownValue = value!;
                  //             office = value!;
                  //           });
                  //           // This is called when the user selects an item.
                  //         },
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  if (checkOut == '--/--') Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 75,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.grey.shade600,
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                      offset: const Offset(4, 4)),
                                  const BoxShadow(
                                      color: Colors.white,
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                      offset: Offset(-4, -4))
                                ],
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(100)),
                              ),
                              margin: const EdgeInsets.only(top: 40),
                              child: MaterialButton(
                                onPressed: () async {
                                  
                               
                                  _getCurrentLocation().then((value) {
                                    setState(() {
                                      Users.lat = value.latitude;
                                      Users.long = value.longitude;
                                    });
                                  });
                                  _goToMe(Users.lat, Users.long);
                                },
                                color: Colors.blue,
                                textColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: const CircleBorder(),
                                child: const Icon(
                                  FontAwesomeIcons.mapLocationDot,
                                  size: 40,
                                ),
                              ),
                            ),
                            checkIn == '--/--'
                                ? Container(
                                    width: 75,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade600,
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                            offset: const Offset(4, 4)),
                                        const BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                            offset: Offset(-4, -4))
                                      ],
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(100)),
                                    ),
                                    margin: const EdgeInsets.only(top: 24),
                                    child: MaterialButton(
                                      onPressed: () async {
                                       
                                        
                                          tz.initializeTimeZone();
                                          var bangkok =
                                              tz.getLocation('Asia/Bangkok');
                                          var now = tz.TZDateTime.now(bangkok);
                                          String remark =
                                              _locationController.text.trim();
                                          if (Users.customer.isEmpty &&
                                              remark.isEmpty) {
                                            _showMyDialog('Missing Value',
                                                'Customer Or Remark are not must be empty!');
                                          } else {
                                            _goToMe(Users.lat, Users.long);
                                            List<Placemark> placemark =
                                                await placemarkFromCoordinates(
                                                    Users.lat, Users.long);
                                            now = tz.TZDateTime.now(bangkok);
                                            setState(() {
                                              locationCheckin =
                                                  "${placemark[0].name} ${placemark[0].subLocality} ${placemark[0].thoroughfare} ${placemark[0].subAdministrativeArea}  ${placemark[0].locality} ${placemark[0].administrativeArea} ${placemark[0].postalCode}  ${placemark[0].country}";
                                              docdate =
                                                  DateFormat('dd MMMM yyyy')
                                                      .format(now);
                                            });

                                            setState(() {
                                              checkIn = DateFormat('hh:mm')
                                                  .format(now);
                                              addRecordDetails(
                                                "${placemark[0].name} ${placemark[0].subLocality} ${placemark[0].thoroughfare} ${placemark[0].subAdministrativeArea}  ${placemark[0].locality} ${placemark[0].administrativeArea} ${placemark[0].postalCode}  ${placemark[0].country}",
                                                Users.location_index,
                                                DateFormat('hh:mm a')
                                                    .format(now),
                                                DateFormat('yyyy-MM-dd H:m:s')
                                                    .format(now),
                                              );
                                            });
                                          }
                                        
                                      },
                                      color: Colors.green,
                                      textColor: Colors.white,
                                      padding: const EdgeInsets.all(16),
                                      shape: const CircleBorder(),
                                      child: const Icon(
                                        FontAwesomeIcons.arrowRightToBracket,
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 75,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade600,
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                            offset: const Offset(4, 4)),
                                        const BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                            offset: Offset(-4, -4))
                                      ],
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(150)),
                                    ),
                                    margin: const EdgeInsets.only(top: 24),
                                    child: MaterialButton(
                                      onPressed: () async {
                                       
                                       
                                          tz.initializeTimeZone();
                                          var bangkok =
                                              tz.getLocation('Asia/Bangkok');
                                          var now = tz.TZDateTime.now(bangkok);
                                          _getCurrentLocation().then((value) {
                                            setState(() {
                                              Users.lat = value.latitude;
                                              Users.long = value.longitude;
                                            });
                                          });
                                          now = tz.TZDateTime.now(bangkok);
                                          _goToMe(Users.lat, Users.long);
                                          List<Placemark> placemark =
                                              await placemarkFromCoordinates(
                                                  Users.lat, Users.long);
                                          setState(() {
                                            locationCheckout =
                                                "${placemark[0].name} ${placemark[0].subLocality} ${placemark[0].thoroughfare} ${placemark[0].subAdministrativeArea}  ${placemark[0].locality} ${placemark[0].administrativeArea} ${placemark[0].postalCode}  ${placemark[0].country}";
                                            docdate = DateFormat('dd MMMM yyyy')
                                                .format(now);
                                            updateRecordDetails(
                                                "${placemark[0].name} ${placemark[0].subLocality} ${placemark[0].thoroughfare} ${placemark[0].subAdministrativeArea}  ${placemark[0].locality} ${placemark[0].administrativeArea} ${placemark[0].postalCode}  ${placemark[0].country}",
                                                Users.location_index,
                                                DateFormat('hh:mm a')
                                                    .format(now),
                                                DateFormat('yyyy-MM-dd H:m:s')
                                                    .format(now));
                                            checkOut =
                                                DateFormat('hh:mm').format(now);
                                          });
                                          Timer(
                                              const Duration(
                                                  milliseconds: 5000), () {
                                            setState(() {
                                              Users.location_index++;
                                              checkOut = '--/--';
                                              checkIn = '--/--';
                                              Users.customer = '';
                                              _locationController.clear();
                                              _selectedUser = null;
                                            });
                                          });
                                      
                                      },
                                      color: Colors.red,
                                      textColor: Colors.white,
                                      padding: const EdgeInsets.all(16),
                                      shape: const CircleBorder(),
                                      child: const Icon(
                                        FontAwesomeIcons.arrowRightFromBracket,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                          ],
                        ) else Container(
                          margin: const EdgeInsets.only(top: 24),
                          child: Text(
                            'Today You have Check In',
                            style: TextStyle(
                              color: Colors.black54,
                              fontFamily: "NexaBold",
                              fontSize: screenWidth / 18,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget textField(
      String hint, String title, TextEditingController controller) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontFamily: "NexaBold",
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            cursorColor: Colors.black54,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.black54,
                fontFamily: "NexaBold",
                fontSize: 14,
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black54,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customPopupItemBuilderExample2(
      BuildContext context, UserModel item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: !isSelected
          ? null
          : BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
            ),
      child: ListTile(
        selected: isSelected,
        title: Text('${item.name} ${item.nameEN} '),
      ),
    );
  }

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
  }

  Future<List<UserModel>> getData(filter) async {
    //  var res = await http.post(Uri.parse(API.getRowCheck), body: {
    //   'user_code': Users.id,
    // });
    var response = await Dio().get(
      "https://www.project1.ts2337.com/checkin_App/api_sql/user/getCustomer.php",
      queryParameters: {"filter": filter},
    );

    final data = jsonDecode(response.data);
    //  print('date' + response.data);
    if (data != null) {
      return UserModel.fromJsonList(data);
    }

    return [];
  }
}
