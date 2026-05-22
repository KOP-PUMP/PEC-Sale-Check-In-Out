// ignore_for_file: non_constant_identifier_names
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kop_checkin/api/api.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_size_text/auto_size_text.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:kop_checkin/model/user_model.dart';
import 'package:kop_checkin/services/location_service.dart';
import 'package:timezone/standalone.dart' as tz;
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class CheckinScreen extends StatefulWidget {
  final VoidCallback onLoad;

  const CheckinScreen(this.onLoad, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CheckinScreenState createState() => _CheckinScreenState();
}

class VehicleOwner {
  final String vehicle;
  final String owner;

  VehicleOwner({
    required this.vehicle,
    required this.owner,
  });

  factory VehicleOwner.fromJson(Map<String, dynamic> json) {
    return VehicleOwner(
      vehicle: json['vehicle'].toString(),
      owner: json['owner'].toString(),
    );
  }

  static List<VehicleOwner> fromJsonList2(List list) {
    return list.map((item) => VehicleOwner.fromJson(item)).toList();
  }

  String vehicleAsString() {
    return '#${this.owner} ${this.vehicle}';
  }

  bool vehicleFilterByName(String filter) {
    return this.vehicle.toString().contains(filter);
  }

  bool isEqual2(VehicleOwner model) {
    return this.vehicle == model.vehicle;
  }

  @override
  String toString() => '$vehicle';
}

class _CheckinScreenState extends State<CheckinScreen> {
  /* Assuming in an async function */
  String? lat;
  String? long;
  String office = 'Bangkok';
  double R = 6378137; // Earth's radius in meters
  double originLat = 13.6566; // Example origin latitude
  double originLng = 100.4682; // Example origin longitude
  double rayonglat = 12.691189895123365; // Example new longitude
  double rayonglng = 101.24271246533687; // Example new longitude
  List<String> companion_list = [];
  List<VehicleOwner> vehicle_data_list = [];
  VehicleOwner? vehicle_selected ;
  String vehicle_selected_name = Users.username;
  double radius = 100; // Radius in meters

  double screenHeight = 0;
  double screenWidth = 0;

  List<String> companion_selected = [];
  String companion_selected_name = "";
  String checkIn2 = '';
  String checkIn = '--/--';
  String checkOut = '--/--';
  String locationCheckin = " ";
  String locationCheckout = " ";
  int locationIndexCheckout = 0;
  String timeOutCheckout = " ";
  String timeStampOutCheckout = " ";
  String remark = "";

  var check_in_lat_long = {
    'latitude': null,
    'longitude': null,
  };

  // var location_index = 1;
  bool _isLoadingCheckinPage = false;
  bool _isErrorCheckinPage = false;
  bool _isLoadingButtonClick = false;
  List<UserModel> userList = []; // Initialize your user list
  UserModel? _selectedUser;

  String docdate = DateFormat('dd MMMM yyyy').format(DateTime.now());
  String nightdate = DateFormat('H').format(DateTime.now());

  Color primary = const Color.fromRGBO(12, 45, 92, 1);
  bool check = false;
  bool isForceCheckOut = false;
  bool isForceCheckOutDatePick = false;
  bool isForceCheckOutSuccess = false;
  late Position currentLocation;
  late SharedPreferences sharedPreferences;
  String customer = '';
  Timer? timer;

  final List<Marker> _list = [
    // Marker(
    //     markerId: const MarkerId('1'),
    //     position: LatLng(Users.lat, Users.long),
    //     infoWindow: const InfoWindow(title: 'You are Here !'))
  ];
  final GlobalKey<DropdownSearchState<UserModel>> _dropdownSearchKey =
      GlobalKey<DropdownSearchState<UserModel>>();
  final Completer<GoogleMapController> _controller = Completer();
  final List<Marker> _maker = [];

  List<String> officeProvince = [
    "Bangkok",
    "Rayong",
  ];

  @override
  void initState() {
    super.initState();
    _maker.addAll(_list);
    _getRecord();
    _startLocationService();
    _loadSavedData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoad();
    });
  }

  void _startLocationService() async {
    LocationService().initialize();
    LocationService().getLatitude().then((value) {
      setState(() {
        Users.lat = value!;
      });
      LocationService().getLongitude().then((value) {
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
    bool serviceEnable = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 10));
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
      return Future.error('Location permission are denied, we cannot request');
    }
    return Geolocator.getCurrentPosition();
  }

  /// Calculate the distance between two latitude and longitude points using the Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Check if the two points are the same (very small threshold for floating-point precision)
    if (lat1 == lat2 && lon1 == lon2) {
      return 0.0;
    }

    // Convert degrees to radians
    double lat1Rad = lat1 * pi / 180;
    double lon1Rad = lon1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double lon2Rad = lon2 * pi / 180;

    // Differences between the latitudes and longitudes
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;

    // Haversine formula
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Distance in meters
    double distance = R * c;
    return distance;
  }

  /// Check if the point is out of range (more than the specified radius)
  bool isOutOfRange(
      double lat1, double lon1, double lat2, double lon2, double radius) {
    double distance = calculateDistance(lat1, lon1, lat2, lon2);
    // print(lat1);
    // print(lon1);
    // print(lat2);
    // print(lon2);
    // print(distance);
    if (kDebugMode) {
      print(distance > radius);
    }
    return distance > radius;
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

  bool _isCheckOutBeforeCheckIn() {
    // If checkIn or checkOut are in '--/--' or the formats are incorrect, return false
    if (checkIn == '--/--' || checkOut == '--/--') {
      return false; // Can't compare if the values are not valid
    }

    try {
      DateTime checkInTime = DateFormat('hh:mm a').parse(checkIn);
      DateTime checkOutTime = DateFormat('hh:mm a').parse(checkOut);

      return checkOutTime.isBefore(
          checkInTime); // Returns true if check-out is before check-in
    } catch (e) {
      return false; // If parsing fails, return false
    }
  }

  bool _isCheckOutAfterCurrentTime() {
    try {
      DateTime currentTime = DateTime.now();

      // Parse checkOut time into DateTime object
      DateTime checkOutTime = DateFormat('hh:mm a').parse(checkOut);

      // Set the checkOutDate's year, month, and day to match currentDate
      checkOutTime = DateTime(currentTime.year, currentTime.month,
          currentTime.day, checkOutTime.hour, checkOutTime.minute);

      // Compare times
      return checkOutTime
          .isAfter(currentTime); // true if checkout time is after current time
    } catch (e) {
      debugPrint("$e");
      return false; // If parsing fails, assume check-out time is invalid
    }
  }

  Future<void> _saveData(String value, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved_customer_name = prefs.getString('customer_name');
    final saved_check_out_quota = prefs.getInt('check_out_quota');
    final saved_additional_quota = prefs.getInt('additional_quota');
    if (saved_customer_name != null && saved_customer_name.isNotEmpty) {
      setState(() {
        Users.customer = saved_customer_name;
      });
    }
    if (saved_check_out_quota != null && saved_additional_quota != null) {
      setState(() {
        Users.check_out_quota = saved_check_out_quota;
        Users.additional_quota = saved_additional_quota;
      });
    }
  }

  void _showCupertinoTimePicker(BuildContext outerContext) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    1969,
                    1,
                    1,
                    TimeOfDay.now().hour,
                    TimeOfDay.now().minute,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      // Update your checkout time variable
                      checkOut = DateFormat('hh:mm a').format(newDateTime);
                      isForceCheckOutDatePick = true;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, right: 24.0, bottom: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MaterialButton(
                      onPressed: () {
                        setState(() {
                          checkOut = '--/--';
                          isForceCheckOutDatePick = false;
                        });
                        Navigator.pop(context);
                        Navigator.pop(outerContext);
                      },
                      child: const Text('Cancel'),
                    ),
                    MaterialButton(
                      onPressed: () {
                        _startLocationService();
                        if (checkOut == '--/--' ||
                            isForceCheckOutDatePick == false) {
                          _showMyDialog("Check-out blocked",
                              "Please select actual check-out time.");
                        } else if (_isCheckOutBeforeCheckIn()) {
                          setState(() {
                            checkOut = '--/--';
                          });
                          _showMyDialog("Check-out blocked",
                              "Check-out time must be after ${checkIn}.");
                        } else if (_isCheckOutAfterCurrentTime()) {
                          setState(() {
                            checkOut = '--/--';
                          });
                          _showMyDialog("Check-out blocked",
                              "Check-out time must not be after current time.");
                        } else {
                          setState(() {
                            _isLoadingButtonClick = true;
                          });
                          updateRecordDetails(
                            locationCheckout,
                            locationIndexCheckout,
                            checkIn,
                            timeStampOutCheckout,
                          );
                          Navigator.pop(context); // Close the inner dialog
                          Navigator.pop(outerContext); // Close the outer dialog
                        }
                      }, // Text color when enabled
                      child: Text('Submit date'),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMyForceCheckOutDialog(String title, String text) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(title,
                      overflow:
                          TextOverflow.ellipsis)), // Added overflow handling
              IconButton(
                icon: Icon(Icons.close), // "X" button to close the dialog
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            Column(
              children: [
                MaterialButton(
                  child: Text(
                    'Force check-out (${(Users.additional_quota + Users.check_out_quota) - Users.force_checkout_count}/${Users.additional_quota + Users.check_out_quota})',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: (Users.additional_quota +
                              Users.check_out_quota -
                              Users.force_checkout_count <=
                          0)
                      ? () {
                          showSnackBar(
                              "Out of quota! Please contact person in charge to get more force check-out quota.");
                        }
                      : () {
                          setState(() {
                            isForceCheckOut = true;
                          });
                          _showCupertinoTimePicker(context);
                        },
                  color: (Users.additional_quota +
                              Users.check_out_quota -
                              Users.force_checkout_count <=
                          0)
                      ? Colors.white30
                      : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // You can add more buttons or other content below
              ],
            ),
          ],
        );
      },
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

  Future<void> addRecordDetails(String locationCheckin, int locationIndex,
      String timeIn, String timestampIn) async {
    try {
      setState(() {
        _isLoadingButtonClick = true;
      });

      final device_name = await checkDevice();

      if (device_name.isNotEmpty) {
        final response = await http.post(Uri.parse(API.addCheckin), body: {
          'doc_date': docdate,
          'user_code': Users.id,
          'time': timeIn,
          'checkin_out': 'IN',
          'location': locationCheckin,
          'location_index': locationIndex.toString(),
          'time_in': timeIn,
          'remark': remark,
          'longitude': Users.long.toString(),
          'latitude': Users.lat.toString(),
          'office': "",
          'customer': Users.customer,
          'device_name': device_name,
          'companion_name': companion_selected_name,
          'vehicle_name': vehicle_selected_name,
        }).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          showSnackBar("Check-in success");
        } else {
          _showMyDialog("Check-in error",
              "Error get Check-in record: ${response.statusCode}");
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('customer_name');
          await prefs.remove('remark');
          await prefs.remove('companion');
          await prefs.remove('vehicle');
          setState(() {
            _isErrorCheckinPage = true;
            Users.location_index++;
            checkOut = '--/--';
            checkIn = '--/--';
            isForceCheckOut = false;
            isForceCheckOutDatePick = false;
            isForceCheckOutSuccess = false;
            Users.customer = '';
            remark = "";
            vehicle_selected = null;
            vehicle_selected_name = "";
            companion_selected = [];
            companion_selected_name = "";
            _selectedUser = null;
          });
        }
        // Timeout duration for request
      }
      // Function to handle the check-in request
    } catch (e) {
      _showMyDialog("Check-in error", "Error add Check-in : ${e}");
      setState(() {
        _isErrorCheckinPage = true;
      });
      debugPrint("Network Error (addRecord): $e");
    } finally {
      setState(() {
        _isLoadingButtonClick = false;
      });
      await _getRecord();
    }
  }

  Future updateRecordDetails(String locationCheckout, int location_index,
      String time_out, String timestamp_out) async {
    try {
      final device_name = await checkDevice();

      if (device_name.isNotEmpty) {
        Map<String, dynamic> body = {
          'user_code': Users.id,
          'doc_date': docdate,
          'time': time_out,
          'time_out': timestamp_out,
          'location': locationCheckout.toString(),
          'location_index': location_index.toString(),
          'longitude': Users.long.toString(),
          'latitude': Users.lat.toString(),
          'force_checkout': "0",
          'device_name': device_name
        };
        if (isForceCheckOut) {
          body['force_checkout'] = "1";
        }
        var response = await http
            .post(
              Uri.parse(API.updateCheck),
              body: body,
            )
            .timeout(const Duration(seconds: 10));

        // Check for a successful response
        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('customer_name');
          // Successfully updated
          setState(() {
            isForceCheckOutSuccess = !isForceCheckOutSuccess;
          });
          showSnackBar("Check-out Success");
          Timer(const Duration(milliseconds: 5000), () {
            setState(() {
              Users.location_index++;
              checkOut = '--/--';
              checkIn = '--/--';
              isForceCheckOut = false;
              isForceCheckOutDatePick = false;
              isForceCheckOutSuccess = false;
              Users.customer = '';
              remark = "";
              companion_selected = [];
              companion_selected_name = "";
              vehicle_selected = null;
              vehicle_selected_name = "";
              _selectedUser = null;
            });
          });
        } else {
          // Handle non-200 response (e.g., error from server)
          _showMyDialog(
              'Failed to check-out', 'Status code: ${response.statusCode}');
          // You can also show an error dialog or message here
        }
      }
    } catch (e) {
      // Handle any errors (e.g., network failure, timeout)
      _showMyDialog('Failed to check-out', '$e');
      // Show a message to the user (or use a dialog)
    } finally {
      setState(() {
        _isLoadingButtonClick = false;
      });
    }
  }

  /// Returns true if within 2 km of the check-in location; false otherwise.
  /// Shows an error dialog via `_showMyDialog` when blocked or on errors.
  checkOutRadiusCheck(double checkOutLat, double checkOutLong) async {
    try {
      final res = await http.post(
        Uri.parse(API.getDocCheck),
        body: {
          'doc_date': DateFormat('dd MMMM yyyy').format(DateTime.now()),
          'user_code': Users.id,
        },
      );

      if (res.statusCode != 200) {
        _showMyDialog('Check-out error',
            'Unable to verify location (status ${res.statusCode}).');
        return false;
      }

      final data = jsonDecode(res.body);

      // Expecting these keys from your backend
      final latInRaw = data['latitude_in'];
      final longInRaw = data['longitude_in'];

      // Parse as doubles safely
      final double? checkInLat = (latInRaw is num)
          ? latInRaw.toDouble()
          : double.tryParse('$latInRaw');
      final double? checkInLong = (longInRaw is num)
          ? longInRaw.toDouble()
          : double.tryParse('$longInRaw');

      if (checkInLat == null || checkInLong == null) {
        _showMyDialog(
            'Check-out error', 'Missing check-in coordinates from server.');
        return false;
      }

      // Compute distance in meters using Haversine
      final distanceMeters =
          _haversineMeters(checkInLat, checkInLong, checkOutLat, checkOutLong);
      debugPrint('Check-in: ($checkInLat,$checkInLong) | '
          'Check-out: ($checkOutLat,$checkOutLong) | '
          'Distance: ${distanceMeters.toStringAsFixed(2)} m');

      final km = (distanceMeters / 1000).toStringAsFixed(2);

      if (distanceMeters > 2000.0) {
        return {"isWithin": false, "km": km};
      } else {
        return {"isWithin": true, "km": km};
      }

      // Within radius — allow check-out
      return true;
    } catch (e, st) {
      debugPrint('checkOutRadiusCheck error: $e');
      debugPrintStack(stackTrace: st);
      _showMyDialog(
          'Check-out error', 'Error getting data for location comparison.');
      return false;
    }
  }

  /// Great-circle distance between two lat/long points, in meters.
  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0; // mean Earth radius
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  Future<List<VehicleOwner>> getVehicle(filter) async {
    try {
      var res = await http
          .get(Uri.parse(API.getVehicle))
          .timeout(const Duration(seconds: 30));
      var resBody = jsonDecode(res.body);
      var data = VehicleOwner.fromJsonList2(resBody);
      return data;
    } catch (e) {
      debugPrint("Network Error (getVehicle): $e");
      _showMyDialog(
          "Network Error", "Cannot fetch vehicle data list from database.");
      setState(() {
        _isErrorCheckinPage = true;
      });
      return [];
    } finally {
      setState(() {
        _isLoadingButtonClick = false;
      });
    }
  }

  Future<List<String>> getCompanion() async {
    try {
      var res = await http
          .get(Uri.parse(API.getCompanion))
          .timeout(const Duration(seconds: 30));
      var resBody = jsonDecode(res.body);
      List<String> persons = List<String>.from(
          resBody.map((person) => person['support_by'].toString()));
      return persons;
      if (persons.isNotEmpty) {
        setState(() {
          companion_list = persons;
          _isLoadingButtonClick = true;
          _isErrorCheckinPage = false;
        });
      } else {
        setState(() {
          _isErrorCheckinPage = true;
        });
      }
    } catch (e) {
      debugPrint("Network Error (getCompanion): $e");
      _showMyDialog(
          "Network Error", "Cannot fetch companion list from database.");
      setState(() {
        _isErrorCheckinPage = true;
      });
      return [];
    } finally {
      setState(() {
        _isLoadingButtonClick = false;
      });
    }
  }

  Future<void> _getRecord() async {
    try {
      // Set loading state to true
      setState(() {
        _isLoadingCheckinPage = true;
        _isErrorCheckinPage = false;
      });

      var res = await http.post(Uri.parse(API.getDocCheck), body: {
        'doc_date': DateFormat('dd MMMM yyyy').format(DateTime.now()),
        'user_code': Users.id,
      }).timeout(const Duration(seconds: 30));
      var resBody = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (resBody['success']) {
          if (resBody['checkout'] != '--/--') {
            setState(() {
              Users.location_index = int.parse(resBody['location_index']) + 1;
              checkIn = '--/--';
              checkOut = '--/--';
            });
          } else {
            sharedPreferences = await SharedPreferences.getInstance();
            sharedPreferences.setString(
                'force_checkout_count', resBody['force_checkout_count']);
            sharedPreferences.setInt(
                'check_out_quota', int.parse(resBody['check_out_quota']));
            sharedPreferences.setInt(
                'additional_quota', int.parse(resBody['additional_quota']));
            setState(() {
              checkIn = resBody['checkin'];
              checkOut = resBody['checkout'];
              remark = resBody['remark'] ?? "";
              companion_selected_name = resBody['companion_name'] ?? "";
              vehicle_selected_name = resBody['vehicle_name'] ?? "";
              Users.check_out_quota = int.parse(resBody['check_out_quota']);
              Users.additional_quota = int.parse(resBody['additional_quota']);
              Users.force_checkout_count =
                  int.parse(resBody['force_checkout_count']);
              Users.location_index = int.parse(resBody['location_index']);
            });
          }
        } else {
          setState(() {
            Users.location_index = 1;
            checkIn = '--/--';
            checkOut = '--/--';
          });
        }
      } else {
        showSnackBar("Error Get Check-in/out record : code ${res.statusCode}");
        setState(() {
          _isLoadingCheckinPage = false;
          _isErrorCheckinPage = true;
        });
      }
    } catch (e) {
      // Handle any network or other errors
      debugPrint("Network Error (getRecord): $e");
      _showMyDialog(
          "Network Error", "Cannot fetch check-in/out record from database.");
      setState(() {
        _isLoadingCheckinPage = false;
        _isErrorCheckinPage = true;
      });
    } finally {
      setState(() {
        _isLoadingCheckinPage = false;
      });
    }
  }

  Future _goToMe(double lat, double long) async {
    final GoogleMapController controller =
        await _controller.future.timeout(const Duration(seconds: 10));
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(lat, long),
      zoom: 16,
    )));

    // _maker.add(
    //   Marker(
    //     markerId: const MarkerId('2'),
    //     position: LatLng(lat, long),
    //     infoWindow: const InfoWindow(
    //         title: 'My Current Position', snippet: 'ที่อยุ่ปัจจุบัน'),
    //   ),
    // );
  }

  void clearItemBuilder() {
    const PopupPropsMultiSelection.modalBottomSheet(
      showSearchBox: true,
      itemBuilder: null,
      // Other properties
    );
  }

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<String> checkDevice() async {
    final List<String> reasons = [];

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;

        // 1. Direct flag
        if (!info.isPhysicalDevice) {
          reasons.add('isPhysicalDevice is false');
        }

        final brand = info.brand.toLowerCase();
        final device = info.device.toLowerCase();
        final model = info.model.toLowerCase();
        final product = info.product.toLowerCase();
        final hardware = (info.hardware ?? '').toLowerCase();
        final fingerprint = info.fingerprint.toLowerCase();
        final manufacturer = info.manufacturer.toLowerCase();

        // 2. Common emulator brand/manufacturer
        if (brand.contains('generic') || brand.contains('unknown')) {
          reasons.add('brand is generic/unknown: $brand');
        }

        if (manufacturer.contains('genymotion') ||
            manufacturer.contains('unknown')) {
          reasons.add('manufacturer suspicious: $manufacturer');
        }

        // 3. Model / product / device hints
        final emulatorKeywords = [
          'google_sdk',
          'sdk_gphone',
          'sdk',
          'emulator',
          'android sdk built for x86',
          'x86',
          'vbox',
          'virtualbox',
        ];

        if (_containsAny(model, emulatorKeywords)) {
          reasons.add('model looks like emulator: ${info.model}');
        }
        if (_containsAny(device, emulatorKeywords)) {
          reasons.add('device looks like emulator: ${info.device}');
        }
        if (_containsAny(product, emulatorKeywords)) {
          reasons.add('product looks like emulator: ${info.product}');
        }

        // 4. Hardware / fingerprint hints
        final hardwareKeywords = [
          'goldfish', // classic Android emulator kernel
          'ranchu',
          'qcom', // not always emu, but sometimes interesting
          'vbox',
        ];
        if (_containsAny(hardware, hardwareKeywords)) {
          reasons.add('hardware indicates emulator: ${info.hardware}');
        }

        if (fingerprint.startsWith('generic') ||
            fingerprint.contains('test-keys')) {
          reasons.add('fingerprint suspicious: ${info.fingerprint}');
        }

        final isEmu = reasons.isNotEmpty;
        if (isEmu) {
          // print({"Device": "Android Simulator", "reason": "$reasons"});
          return "Android Emu";
        } else {
          // print({"Device": "Android", "reason": "$reasons"});
          return "Android";
        }
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;

        if (!info.isPhysicalDevice) {
          reasons.add('isPhysicalDevice is false (iOS simulator)');
        }

        // iOS simulators often have these machine names
        final machine = info.utsname.machine.toLowerCase();
        if (machine.contains('x86_64') || machine.contains('arm64')) {
          reasons.add(
              'utsname.machine looks like simulator: ${info.utsname.machine}');
        }

        final isEmu = reasons.isNotEmpty;
        if (isEmu) {
          // print({"Device": "IOS Simulator", "reason": "$reasons"});
          return "IOS Emu";
        } else {
          // print({"Device": "IOS", "reason": "$reasons"});
          return "IOS";
        }
      } else {
        // Other platforms (web, desktop)
        reasons.add('non-mobile platform: ${Platform.operatingSystem}');
        // print({"Device": "Other", "reason": "$reasons"});
        return "Other";
      }
    } catch (e) {
      // On error, you decide: treat as suspicious or ignore
      reasons.add('error while checking: $e');
      print({"Error": "Error while checking for device", "reason": "$reasons"});
      return "Error";
    }
  }

  static bool _containsAny(String value, List<String> patterns) {
    for (final p in patterns) {
      if (value.contains(p)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return !_isLoadingCheckinPage && !_isErrorCheckinPage
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
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: DropdownSearch<UserModel>(
                            key:
                                _dropdownSearchKey, // Attach the GlobalKey here
                            items: userList,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: "Customer",
                                labelStyle: const TextStyle(
                                  fontSize: 18, // Adjust the label font size
                                  color: Color.fromARGB(255, 50, 50,
                                      50), // Set the color of the label
                                  fontWeight: FontWeight
                                      .w400, // Optional: Change font weight
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior
                                    .always, // Always show the label above the dropdown
                                filled: true,
                                fillColor: Colors.grey[
                                    200], // Optional: Set background color for the dropdown
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          8)), // Customize the border radius
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(
                                        255, 100, 100, 100), // Border color
                                    width: 1, // Border width
                                  ),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          8)), // Border radius when enabled
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 100, 100,
                                        100), // Border color for enabled state
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          8)), // Border radius when focused
                                  borderSide: BorderSide(
                                    color: Colors
                                        .indigo, // Border color for focused state
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal:
                                        20), // Adjust padding inside the dropdown
                              ),
                              baseStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    13, // Customize the font size of the selected item
                                color: Color(0xff4962AD),
                              ),
                            ),
                            onChanged: (UserModel? data) async {
                              if (data != null) {
                                setState(() {
                                  _saveData(data.customer_name_show.toString(),
                                      'customer_name');
                                  Users.customer =
                                      data.customer_name_show.toString();
                                  _selectedUser = data;
                                });
                                await _saveData(
                                    Users.customer, 'customer_name');
                              }
                            },
                            selectedItem:
                                _selectedUser, // Ensure the correct selected item is displayed
                            asyncItems: (filter) =>
                                getData(filter), // Fetching data
                            compareFn: (i, s) => i.isEqual(
                                s), // Compare function for selection logic
                            onBeforePopupOpening: (popupProps) async {
                              // Get the current location before showing the dropdown
                              await _getCurrentLocation().then((value) {
                                setState(() {
                                  Users.lat =
                                      value.latitude; // Update lat and long
                                  Users.long = value.longitude;
                                });
                              });
                              _goToMe(
                                  Users.lat,
                                  Users
                                      .long); // Navigate to the user's location
                              return true;
                            },
                            enabled: checkIn != '--/--' ? false : true,
                            dropdownBuilder: (BuildContext context,
                                UserModel? selectedItem) {
                              // Use _selectedUser and display the correct field (customer_name_show)
                              return AutoSizeText(
                                // checkIn != '--/--'
                                //     ? Users
                                //         .customer
                                //     : 'Select customer',
                                _selectedUser != null
                                    ? _selectedUser!.customer_name_show
                                        .toString() // Display the modified "customer_name_show"
                                    : Users.customer != "" && checkIn != '--/--'
                                        ? Users.customer
                                        : 'Select customer', // Default text if no user is selected
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15, // Max font size
                                  color: checkIn != '--/--'
                                      ? Colors.grey
                                      : Color(0xff4962AD),
                                ),
                                maxLines:
                                    1, // Ensure the text stays on one line
                                minFontSize: 12, // Set the minimum font size
                                overflow: TextOverflow
                                    .ellipsis, // Truncate with '...'
                              );
                            },
                            popupProps:
                                PopupPropsMultiSelection.modalBottomSheet(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: const TextStyle(
                                      color: Colors
                                          .grey), // Customize hint text color
                                  filled: true,
                                  fillColor: Colors.grey
                                      .shade200, // Customize background color of the search box
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // Customize border radius of the search box
                                    borderSide: const BorderSide(
                                        color: Colors.blue,
                                        width:
                                            2), // Customize border color and width
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // Border radius when not focused
                                    borderSide: const BorderSide(
                                        color: Colors.grey,
                                        width:
                                            1), // Border color and width when enabled
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        10), // Border radius when focused
                                    borderSide: const BorderSide(
                                        color: Colors.indigo,
                                        width:
                                            1.5), // Border color and width when focused
                                  ),
                                ),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color:
                                        Colors.black), // Customize text style
                              ),
                              modalBottomSheetProps:
                                  const ModalBottomSheetProps(
                                backgroundColor: Color.fromARGB(
                                    255, 255, 255, 255), // Set background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(
                                        10), // Set the top border radius to 10
                                  ),
                                ),
                              ),
                              containerBuilder: (context, popupWidget) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10,
                                      bottom:
                                          10), // Set padding from above and below
                                  child: popupWidget,
                                );
                              },
                              itemBuilder: _customPopupItemBuilderExample2,
                              favoriteItemProps: FavoriteItemProps(
                                showFavoriteItems: true,
                                favoriteItems: (us) {
                                  if (!isOutOfRange(originLat, originLng,
                                      Users.lat, Users.long, radius)) {
                                    // If within the range of origin, show O-0019, O-0040, O-0041
                                    return us
                                        .where((e) =>
                                            e.name.contains("O-0019") ||
                                            e.name.contains("O-0040") ||
                                            e.name.contains("O-0041"))
                                        .toList();
                                  } else if (!isOutOfRange(rayonglat, rayonglng,
                                      Users.lat, Users.long, radius)) {
                                    // If within the range of Rayong, show O-0040, O-0041, O-0039
                                    return us
                                        .where((e) =>
                                            e.name.contains("O-0040") ||
                                            e.name.contains("O-0041") ||
                                            e.name.contains("O-0039"))
                                        .toList();
                                  } else {
                                    // Else show only O-0040 and O-0041
                                    return us
                                        .where((e) =>
                                            e.name.contains("O-0040") ||
                                            e.name.contains("O-0041"))
                                        .toList();
                                  }
                                },
                                favoriteItemBuilder:
                                    (context, item, isSelected) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[100],
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          item.customer_name_show,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff4962AD)),
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
                  Row(
                    children: [
                      Expanded(
                          child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Remark",
                            hintText: remark.isNotEmpty ? remark : "Remark",
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: checkIn != '--/--'
                                  ? Colors.grey
                                  : Color(0xff4962AD),
                            ),
                            labelStyle: const TextStyle(
                              fontSize: 18, // Adjust the label font size
                              color: Color.fromARGB(255, 50, 50,
                                  50), // Set the color of the label
                              fontWeight: FontWeight
                                  .w400, // Optional: Change font weight
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(
                                color: Color.fromARGB(
                                    255, 100, 100, 100), // Border color
                                width: 1, // Border width
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 100, 100,
                                    100), // Border color for enabled state
                                width: 1,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(
                                color: Colors
                                    .indigo, // Border color for focused state
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                          ),
                          onChanged: (value) {
                            setState(() {
                              remark = value;
                            });
                          },
                          enabled: checkIn != '--/--' ? false : true,
                        ),
                      ))
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Row(
                          children: [
                            // Divider before the "Optional" text
                            Expanded(
                              child: Divider(
                                color: Colors.grey, // Divider color
                                thickness: 1, // Divider thickness
                                endIndent: 2, // Space between text and divider
                              ),
                            ),
                            // "Optional" text
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "Optional",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            // Divider after the "Optional" text
                            Expanded(
                              child: Divider(
                                color: Colors.grey, // Divider color
                                thickness: 1, // Divider thickness
                                indent: 2, // Space between divider and text
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: Container(
                      //         margin: const EdgeInsets.only(bottom: 12),
                      //         padding: const EdgeInsets.symmetric(horizontal: 20),
                      //         alignment: Alignment.centerLeft,
                      //         child: DropdownSearch<String>(
                      //           items: companion_list,  // Fixed data
                      //           dropdownDecoratorProps: DropDownDecoratorProps(
                      //             dropdownSearchDecoration: InputDecoration(
                      //               labelText: "Companion",
                      //               labelStyle: const TextStyle(
                      //                 fontSize: 18,  // Adjust the label font size
                      //                 color: Color.fromARGB(255, 50, 50, 50),  // Set the color of the label
                      //                 fontWeight: FontWeight.w400,  // Optional: Change font weight
                      //               ),
                      //               floatingLabelBehavior: FloatingLabelBehavior.always,
                      //               filled: true,
                      //               fillColor: Colors.grey[200],
                      //               border: const OutlineInputBorder(
                      //                 borderRadius: BorderRadius.all(Radius.circular(8)),
                      //                 borderSide: BorderSide(
                      //                   color: Color.fromARGB(255, 100, 100, 100),  // Border color
                      //                   width: 1,  // Border width
                      //                 ),
                      //               ),
                      //               enabledBorder: const OutlineInputBorder(
                      //                 borderRadius: BorderRadius.all(Radius.circular(8)),
                      //                 borderSide: BorderSide(
                      //                   color: Color.fromARGB(255, 100, 100, 100),  // Border color for enabled state
                      //                   width: 1,
                      //                 ),
                      //               ),
                      //               focusedBorder: const OutlineInputBorder(
                      //                 borderRadius: BorderRadius.all(Radius.circular(8)),
                      //                 borderSide: BorderSide(
                      //                   color: Colors.indigo,  // Border color for focused state
                      //                   width: 1.5,
                      //                 ),
                      //               ),
                      //               contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      //             ),
                      //             baseStyle: const TextStyle(
                      //               fontWeight: FontWeight.w600,
                      //               fontSize: 13,  // Customize the font size of the selected item
                      //               color: Color(0xff4962AD),
                      //             ),
                      //           ),
                      //           enabled: checkIn != '--/--' ? false : true,
                      //           selectedItem: companion_selected,
                      //           dropdownBuilder: (context, companion_selected){
                      //             return AutoSizeText(
                      //               companion_selected != null
                      //                   ? companion_selected
                      //                   : 'Select companion', // Default text if no user is selected
                      //               style: TextStyle(
                      //                 fontWeight: FontWeight.w600,
                      //                 fontSize: 15, // Max font size
                      //                 color: checkIn != '--/--' ? Colors.grey : Color(0xff4962AD),
                      //               ),
                      //               maxLines:
                      //               1, // Ensure the text stays on one line
                      //               minFontSize: 12, // Set the minimum font size
                      //               overflow: TextOverflow
                      //                   .ellipsis, // Truncate with '...'
                      //             );
                      //           },
                      //             onChanged: (value) {
                      //             setState(() {
                      //               // Handle item selection here
                      //               if (value == companion_selected){
                      //                 companion_selected = null;
                      //               }else{
                      //                 companion_selected = value;
                      //               }// Update with selected value
                      //             });
                      //           },
                      //           asyncItems: (filter) =>
                      //               getCompanion(), // Display selected item
                      //           // Enable search functionality
                      //           popupProps: PopupPropsMultiSelection.modalBottomSheet(
                      //             showSearchBox: true,
                      //             searchFieldProps: TextFieldProps(
                      //               decoration: InputDecoration(
                      //                 hintText: 'Search',
                      //                 hintStyle: const TextStyle(
                      //                     color: Colors
                      //                         .grey), // Customize hint text color
                      //                 filled: true,
                      //                 fillColor: Colors.grey
                      //                     .shade200, // Customize background color of the search box
                      //                 border: OutlineInputBorder(
                      //                   borderRadius: BorderRadius.circular(
                      //                       10), // Customize border radius of the search box
                      //                   borderSide: const BorderSide(
                      //                       color: Colors.blue,
                      //                       width:
                      //                       2), // Customize border color and width
                      //                 ),
                      //                 enabledBorder: OutlineInputBorder(
                      //                   borderRadius: BorderRadius.circular(
                      //                       10), // Border radius when not focused
                      //                   borderSide: const BorderSide(
                      //                       color: Colors.grey,
                      //                       width:
                      //                       1), // Border color and width when enabled
                      //                 ),
                      //                 focusedBorder: OutlineInputBorder(
                      //                   borderRadius: BorderRadius.circular(
                      //                       10), // Border radius when focused
                      //                   borderSide: const BorderSide(
                      //                       color: Colors.indigo,
                      //                       width:
                      //                       1.5), // Border color and width when focused
                      //                 ),
                      //               ),
                      //               style: const TextStyle(
                      //                   fontSize: 16,
                      //                   color:
                      //                   Colors.black), // Customize text style
                      //             ),
                      //             modalBottomSheetProps:
                      //             const ModalBottomSheetProps(
                      //               backgroundColor: Color.fromARGB(
                      //                   255, 255, 255, 255), // Set background color
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.vertical(
                      //                   top: Radius.circular(
                      //                       10), // Set the top border radius to 10
                      //                 ),
                      //               ),
                      //             ),
                      //             containerBuilder: (context, popupWidget) {
                      //               return Padding(
                      //                 padding: const EdgeInsets.only(
                      //                     top: 10,
                      //                     bottom:
                      //                     10), // Set padding from above and below
                      //                 child: popupWidget,
                      //               );
                      //             },
                      //             itemBuilder: _customPopupItemBuilderExample3,
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      Row(children: [
                        Expanded(
                            child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerLeft,
                                child: DropdownSearch<String>.multiSelection(
                                    items: companion_list,
                                    enabled: checkIn != '--/--' ? false : true,
                                    selectedItems: companion_selected,
                                    dropdownDecoratorProps:
                                        DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: "Support By",
                                        labelStyle: const TextStyle(
                                          fontSize:
                                              18, // Adjust the label font size
                                          color: Color.fromARGB(255, 50, 50,
                                              50), // Set the color of the label
                                          fontWeight: FontWeight
                                              .w400, // Optional: Change font weight
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          borderSide: BorderSide(
                                            color: Color.fromARGB(255, 100, 100,
                                                100), // Border color
                                            width: 1, // Border width
                                          ),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          borderSide: BorderSide(
                                            color: Color.fromARGB(255, 100, 100,
                                                100), // Border color for enabled state
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                          borderSide: BorderSide(
                                            color: Colors
                                                .indigo, // Border color for focused state
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 20),
                                      ),
                                      baseStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            13, // Customize the font size of the selected item
                                        color: Color(0xff4962AD),
                                      ),
                                    ),
                                    dropdownBuilder:
                                        (context, companion_selected) {
                                      return AutoSizeText(
                                          companion_selected.isNotEmpty
                                              ? companion_selected.join(", ")
                                              : checkIn != '--/--'
                                              ? companion_selected_name
                                              : 'Select Companion',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15, // Max font size
                                            color: checkIn != '--/--'
                                                ? Colors.grey
                                                : Color(0xff4962AD),
                                          ));
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        companion_selected_name =
                                            value.join(", ");
                                      });
                                    },
                                    asyncItems: (filter) => getCompanion(),
                                    popupProps: PopupPropsMultiSelection
                                        .modalBottomSheet(
                                      showSearchBox:
                                          true, // Enable search functionality
                                      searchFieldProps: TextFieldProps(
                                        decoration: InputDecoration(
                                          hintText: 'Search Person',
                                          hintStyle: const TextStyle(
                                              color: Colors
                                                  .grey), // Customize hint text color
                                          filled: true,
                                          fillColor: Colors.grey
                                              .shade200, // Background color of the search box
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                10), // Border radius of the search box
                                            borderSide: const BorderSide(
                                                color: Colors.blue,
                                                width:
                                                    2), // Border color and width
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: Colors.grey, width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: Colors.indigo,
                                                width: 1.5),
                                          ),
                                        ),
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.black),
                                      ),
                                      modalBottomSheetProps:
                                          const ModalBottomSheetProps(
                                        backgroundColor: Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255), // Background color of bottom sheet
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(
                                                  10)), // Top radius
                                        ),
                                      ),
                                      containerBuilder: (context, popupWidget) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              top: 10,
                                              bottom:
                                                  10), // Padding above and below
                                          child: popupWidget,
                                        );
                                      },
                                      itemBuilder: (context, item, isSelected) {
                                        return Column(
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0),
                                              decoration: !isSelected
                                                  ? null
                                                  : BoxDecoration(
                                                      border: Border.all(
                                                          color: Theme.of(
                                                                  context)
                                                              .primaryColor),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      color: Colors.red,
                                                    ),
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 8),
                                                  Text(item,
                                                      style: const TextStyle(
                                                          fontSize: 16)),
                                                ],
                                              ),
                                            ),

                                          ],
                                        );
                                        ;
                                      },
                                    ))))
                      ]),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerLeft,
                              child: DropdownSearch<VehicleOwner>(
                                items: vehicle_data_list,
                                selectedItem: vehicle_selected,
                                onChanged: (VehicleOwner? data) async {
                                  if (data.toString() ==
                                      vehicle_selected.toString()) {
                                    setState(() {
                                      vehicle_selected = null;
                                      vehicle_selected_name = "";
                                    });
                                  } else if (data != null) {
                                    setState(() {
                                      _saveData(
                                          data.vehicle.toString(), 'vehicle');
                                      vehicle_selected = data;
                                      vehicle_selected_name = data.toString();
                                    });
                                  }
                                }, // Ensure the correct selected item is displayed
                                asyncItems: (filter) =>
                                    getVehicle(filter), // Fetching data
                                compareFn: (i, s) => i.isEqual2(
                                    s), // Compare function for selection logic
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: "Vehicle",
                                    labelStyle: const TextStyle(
                                      fontSize:
                                          18, // Adjust the label font size
                                      color: Color.fromARGB(255, 50, 50,
                                          50), // Set the color of the label
                                      fontWeight: FontWeight
                                          .w400, // Optional: Change font weight
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(
                                            255, 100, 100, 100), // Border color
                                        width: 1, // Border width
                                      ),
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(
                                        color: Color.fromARGB(255, 100, 100,
                                            100), // Border color for enabled state
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(
                                        color: Colors
                                            .indigo, // Border color for focused state
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 20),
                                  ),
                                  baseStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize:
                                        13, // Customize the font size of the selected item
                                    color: Color(0xff4962AD),
                                  ),
                                ),
                                enabled: checkIn != '--/--'
                                    ? false
                                    : true, // Display selected item
                                dropdownBuilder:
                                    (context, VehicleOwner? selectedItem) {
                                  return AutoSizeText(
                                    vehicle_selected_name != ""
                                        ? vehicle_selected_name
                                        : 'Select vehicle', // Default text if no user is selected
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15, // Max font size
                                      color: checkIn != '--/--'
                                          ? Colors.grey
                                          : Color(0xff4962AD),
                                    ),
                                    maxLines:
                                        1, // Ensure the text stays on one line
                                    minFontSize:
                                        12, // Set the minimum font size
                                    overflow: TextOverflow
                                        .ellipsis, // Truncate with '...'
                                  );
                                },
                                // Enable search functionality
                                popupProps:
                                    PopupPropsMultiSelection.modalBottomSheet(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search Name',
                                      hintStyle: const TextStyle(
                                          color: Colors
                                              .grey), // Customize hint text color
                                      filled: true,
                                      fillColor: Colors.grey
                                          .shade200, // Customize background color of the search box
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Customize border radius of the search box
                                        borderSide: const BorderSide(
                                            color: Colors.blue,
                                            width:
                                                2), // Customize border color and width
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Border radius when not focused
                                        borderSide: const BorderSide(
                                            color: Colors.grey,
                                            width:
                                                1), // Border color and width when enabled
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Border radius when focused
                                        borderSide: const BorderSide(
                                            color: Colors.indigo,
                                            width:
                                                1.5), // Border color and width when focused
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors
                                            .black), // Customize text style
                                  ),
                                  modalBottomSheetProps:
                                      const ModalBottomSheetProps(
                                    backgroundColor: Color.fromARGB(255, 255,
                                        255, 255), // Set background color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(
                                            10), // Set the top border radius to 10
                                      ),
                                    ),
                                  ),
                                  containerBuilder: (context, popupWidget) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 10,
                                          bottom:
                                              5), // Set padding from above and below
                                      child: popupWidget,
                                    );
                                  },
                                  itemBuilder: _customPopupItemBuilderExample4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  if (!isForceCheckOutSuccess)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Container(
                        //   width: 75,
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey.shade300,
                        //     boxShadow: [
                        //       BoxShadow(
                        //           color: Colors.grey.shade600,
                        //           blurRadius: 5,
                        //           spreadRadius: 1,
                        //           offset: const Offset(4, 4)),
                        //       const BoxShadow(
                        //           color: Colors.white,
                        //           blurRadius: 5,
                        //           spreadRadius: 1,
                        //           offset: Offset(-4, -4))
                        //     ],
                        //     borderRadius:
                        //         const BorderRadius.all(Radius.circular(100)),
                        //   ),
                        //   margin: const EdgeInsets.only(top: 40),
                        //   child: MaterialButton(
                        //     onPressed: () async {
                        //       _getCurrentLocation().then((value) {
                        //         setState(() {
                        //           Users.lat = value.latitude;
                        //           Users.long = value.longitude;
                        //         });
                        //       });
                        //       _goToMe(Users.lat, Users.long);
                        //     },
                        //     color: Colors.blue,
                        //     textColor: Colors.white,
                        //     padding: const EdgeInsets.all(16),
                        //     shape: const CircleBorder(),
                        //     child: const Icon(
                        //       FontAwesomeIcons.mapLocationDot,
                        //       size: 40,
                        //     ),
                        //   ),
                        // ),
                        checkIn == '--/--'
                            ? Container(
                                margin: const EdgeInsets.only(top: 18),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  // boxShadow: [
                                  //   BoxShadow(
                                  //       color: Colors.grey.shade600,
                                  //       blurRadius: 5,
                                  //       spreadRadius: 1,
                                  //       offset: const Offset(4, 4)),
                                  //   const BoxShadow(
                                  //       color: Colors.white,
                                  //       blurRadius: 5,
                                  //       spreadRadius: 1,
                                  //       offset: Offset(-4, -4))
                                  // ],
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                ),
                                child: Center(
                                  // Centers the button in the container
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        80, // Screen width minus left and right paddings
                                    child: MaterialButton(
                                      onPressed: () async {
                                        setState(() {
                                          _isLoadingButtonClick = true;
                                        });
                                        try {
                                          _startLocationService();
                                          tz.initializeTimeZone();
                                          var bangkok =
                                              tz.getLocation('Asia/Bangkok');
                                          var now = tz.TZDateTime.now(bangkok);
                                          if (Users.customer.isEmpty) {
                                            _showMyDialog('Check-in error',
                                                'Customer must not be empty!');
                                          } else if (Users.customer ==
                                                  'PEC Other' &&
                                              (remark.isEmpty ||
                                                  remark == '')) {
                                            _showMyDialog('Check-in error',
                                                'Remark must not be empty when select other!');
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

                                            await addRecordDetails(
                                              "${placemark[0].name} ${placemark[0].subLocality} ${placemark[0].thoroughfare} ${placemark[0].subAdministrativeArea}  ${placemark[0].locality} ${placemark[0].administrativeArea} ${placemark[0].postalCode}  ${placemark[0].country}",
                                              Users.location_index,
                                              DateFormat('hh:mm a').format(now),
                                              DateFormat('yyyy-MM-dd H:m:s')
                                                  .format(now),
                                            );
                                          }
                                        } catch (e) {
                                          _showMyDialog("Network Error",
                                              "Error cannot check-in to database");
                                          setState(() {
                                            _isErrorCheckinPage = true;
                                          });
                                        } finally {
                                          setState(() {
                                            _isLoadingButtonClick = false;
                                          });
                                        }
                                      },
                                      color: Colors.green,
                                      textColor: Colors.white,
                                      padding: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        // Rectangular shape with small corner radius
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _isLoadingButtonClick
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : const Text(
                                              "Check-in",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.only(top: 18),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 80,
                                    child: MaterialButton(
                                        onPressed: () async {
                                          setState(() {
                                            _isLoadingButtonClick = true;
                                          });
                                          try {
                                            _getRecord();
                                            tz.initializeTimeZone();
                                            var bangkok =
                                                tz.getLocation('Asia/Bangkok');
                                            var now =
                                                tz.TZDateTime.now(bangkok);

                                            _startLocationService();

                                            now = tz.TZDateTime.now(bangkok);
                                            _goToMe(Users.lat, Users.long);

                                            List<Placemark> placemark =
                                                await placemarkFromCoordinates(
                                                    Users.lat, Users.long);

                                            setState(() {
                                              locationCheckout =
                                                  "${placemark[0].name} ${placemark[0].subLocality} ${placemark[0].thoroughfare} ${placemark[0].subAdministrativeArea}  ${placemark[0].locality} ${placemark[0].administrativeArea} ${placemark[0].postalCode}  ${placemark[0].country}";
                                              locationIndexCheckout =
                                                  Users.location_index;
                                              timeOutCheckout =
                                                  DateFormat('hh:mm a')
                                                      .format(now);
                                              timeStampOutCheckout =
                                                  DateFormat('yyyy-MM-dd H:m:s')
                                                      .format(now);
                                              docdate =
                                                  DateFormat('dd MMMM yyyy')
                                                      .format(now);
                                            });

                                            checkOutRadiusCheck(
                                                    Users.lat, Users.long)
                                                .then((okToCheckout) {
                                              debugPrint("$okToCheckout");
                                              if (okToCheckout['isWithin']) {
                                                setState(() {
                                                  checkOut =
                                                      DateFormat('hh:mm a')
                                                          .format(now);
                                                });
                                                updateRecordDetails(
                                                    locationCheckout,
                                                    locationIndexCheckout,
                                                    timeOutCheckout,
                                                    timeStampOutCheckout);
                                              } else if (!okToCheckout[
                                                  'isWithin']) {
                                                _showMyForceCheckOutDialog(
                                                    'Check-out blocked',
                                                    'You are ${okToCheckout['km']} km away from your check-in location. '
                                                        'Within a 2 km radius is allowed.');
                                              }
                                            });
                                          } catch (e) {
                                            _showMyDialog("Network Error",
                                                "Error cannot check-out to database");
                                            setState(() {
                                              _isErrorCheckinPage = true;
                                            });
                                          } finally {
                                            setState(() {
                                              _isLoadingButtonClick = false;
                                            });
                                          }
                                        },
                                        color: Colors.red,
                                        textColor: Colors.white,
                                        padding: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "Check-out",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        )),
                                  ),
                                ),
                              )
                      ],
                    )
                  else if (isForceCheckOutSuccess)
                    Container(
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
        : _isErrorCheckinPage
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    const Text("Network Error",
                        style: TextStyle(color: Colors.red, fontSize: 18)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _getRecord, // Retry data fetching
                      child: const Text("Retry"),
                    ),
                  ],
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
              fontWeight: FontWeight.w400,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.symmetric(vertical: 0),
          decoration: !isSelected
              ? null
              : BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                ),
          child: ListTile(
            selected: isSelected,
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.code}\n',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4962AD),
                    ),
                  ),
                  TextSpan(
                    text: '${item.nameEN}\n',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '${item.nameTH}\n',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextSpan(
                    text: '${item.province_th} ${item.tambon_th}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          color: Colors.grey, // Color of the divider line
          thickness: 1, // Thickness of the line
          indent: 16, // Left padding for the divider line
          endIndent: 16, // Right padding for the divider line
        ),
      ],
    );
  }

  Widget _customPopupItemBuilderExample3(
      BuildContext context, item, bool isSelected) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.symmetric(vertical: 0),
          decoration: !isSelected
              ? null
              : BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                ),
          child: ListTile(
            selected: isSelected,
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4962AD),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          color: Colors.grey, // Color of the divider line
          thickness: 1, // Thickness of the line
          indent: 16, // Left padding for the divider line
          endIndent: 16, // Right padding for the divider line
        ),
      ],
    );
  }

  Widget _customPopupItemBuilderExample4(
      BuildContext context, VehicleOwner item, bool isSelected) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.symmetric(vertical: 0),
          decoration: !isSelected
              ? null
              : BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.red,
                ),
          child: ListTile(
            selected: isSelected,
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Name : ${item.vehicle}\n',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4962AD),
                    ),
                  ),
                  TextSpan(
                    text: 'Owner : ${item.owner}\n',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          color: Colors.grey, // Color of the divider line
          thickness: 1, // Thickness of the line
          indent: 16, // Left padding for the divider line
          endIndent: 16, // Right padding for the divider line
        ),
      ],
    );
  }

  Future<List<UserModel>> getData(filter) async {
    //  var res = await http.post(Uri.parse(API.getRowCheck), body: {
    //   'user_code': Users.id,
    // });
    var response = await Dio().get(
      "https://www.pecsystem.net/check-in/getCustomer.php",
      queryParameters: {"filter": filter},
    );

    final data = jsonDecode(response.data);
    // print(UserModel.fromJsonList(data));
    if (data != null) {
      return UserModel.fromJsonList(data);
    }

    return [];
  }
}
