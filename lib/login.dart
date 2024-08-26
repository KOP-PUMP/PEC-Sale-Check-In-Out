import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kop_checkin/homescreen.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:http/http.dart' as http;
import 'api/api.dart';
// import 'services/location_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color.fromRGBO(12, 45, 92, 1);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late SharedPreferences sharedPreferences;

  vaildateUserEmail() async {
    try {
      var res = await http.post(Uri.parse(API.validateEmail),
          body: {'username': _emailController.text.trim()});
      if (res.statusCode == 200) {
        var resBody = jsonDecode(res.body);
        if (resBody['emailFound'] == true) {
          showSnackBar('Please enter your Password in PEC');
        }
      }
    } catch (e) {
      showSnackBar('Error orred');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible =
        KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          isKeyboardVisible
              ? SizedBox(
                  height: screenHeight / 20,
                )
              : Container(
                  height: screenHeight / 3,
                  width: screenWidth,
                  decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(55))),
                  child: Center(
                      child: Image(
                    image: const AssetImage('assets/images/logo.png'),
                    height: screenHeight / 5,
                  )),
                ),
          Container(
            margin: EdgeInsets.only(
                top: screenHeight / 15, bottom: screenHeight / 25),
            child: Text(
              "Login",
              style:
                  TextStyle(fontSize: screenWidth / 18, fontFamily: "NexaBold"),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth / 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fieldTitle('Username'),
                customField(
                    'Username or Phone Number', _emailController, false),
                fieldTitle('Password'),
                customField('Password', _passwordController, true),
                Container(
                  margin: const EdgeInsets.only(top: 32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: GestureDetector(
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Email in still empty!")));
                        } else if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Paswword in still empty !")));
                        } else {
                          var res =
                              await http.post(Uri.parse(API.login), body: {
                            'username': _emailController.text.trim(),
                            'password': _passwordController.text.trim()
                          });

                          if (res.statusCode == 200) {
                            var resBody = jsonDecode(res.body);
                            if (resBody['success'] == true) {
                              showSnackBar('Login Suceess');
                              setState(() {
                                Users.username = resBody['username'];
                                Users.id = resBody['user_id'];
                                // Users.name_surname_en =
                                //     resBody['name_surname_en'];
                                // Users.name_surname_th =
                                //     resBody['name_surname_th'];
                                Users.pec_group = resBody['pec_group'];
                                Users.department = resBody['department'];
                                Users.position = resBody['position'];
                              });

                              sharedPreferences =
                                  await SharedPreferences.getInstance();
                              sharedPreferences.setString('username',
                                  resBody['username']);
                              // sharedPreferences.setString('name_surname_en',
                              //     resBody['name_surname_en']);
                              // sharedPreferences.setString('name_surname_th',
                              //     resBody['name_surname_th']);
                              sharedPreferences.setString(
                                  'pec_group', resBody['pec_group']);
                              sharedPreferences.setString(
                                  'department', resBody['department']);
                              sharedPreferences.setString(
                                  'position', resBody['position']);
                              sharedPreferences.setString(
                                  'employeeID', resBody['user_id']);
                              sharedPreferences
                                  .setString('employeeUser', email)
                                  .then((_) {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreeen()));
                              });
                            } else {
                              showSnackBar('User or Password is Incorrect');
                            }
                          }
            

                          try {
                          
                          } catch (e) {
                            String error = '';

                            if (e.toString() ==
                                "RangeError (index): Invalid value: Valid value range is empty: 0") {
                              setState(() {
                                error = 'Employee is not exist';
                              });
                            } else {
                              setState(() {
                                error = 'Error occured';
                              });
                            }
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(error)));
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // void newMethod(Position value) {
  //   return setState(() {
  //     Users.lat = value.latitude;
  //     Users.long = value.longitude;
  //   });
  // }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(fontSize: screenWidth / 26, fontFamily: "NexaBold"),
      ),
    );
  }

  Widget customField(
      String hint, TextEditingController controller, bool obscureText) {
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth / 50),
      width: screenWidth,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(2, 2))
          ]),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth / 6,
            child: Icon(
              Icons.person,
              color: primary,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
              child: Padding(
            padding: EdgeInsets.only(right: screenWidth / 12),
            child: TextFormField(
              enableSuggestions: false,
              obscureText: obscureText,
              controller: controller,
              autocorrect: false,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint),
              maxLines: 1,
            ),
          ))
        ],
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
}
