import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kop_checkin/api/api.dart';
import 'package:kop_checkin/model/industry.dart';
import 'package:kop_checkin/model/user.dart';
import 'package:http/http.dart' as http;

class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key});

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final _code = TextEditingController();
  final _customerNameEN = TextEditingController();
  final _customerNameTH = TextEditingController();
  String industry_category = '';
  @override
  double screenHeight = 0;
  double screenWidth = 0;

  UserModel? _selectedCustomer;
  List<UserModel> userList = [];

  Future<List<UserModel>> getData(filter) async {
    //  var res = await http.post(Uri.parse(API.getRowCheck), body: {
    //   'user_code': Users.id,
    // });
    var response = await Dio().get(
      "https://www.project1.ts2337.com/checkin_App/api_sql/user/getIndustry.php",
      queryParameters: {"filter": filter},
    );

    final data = jsonDecode(response.data);
    //  print('date' + response.data);
    if (data != null) {
      return UserModel.fromJsonList(data);
    }

    return [];
  }

  Future addCustomer() async {
    await http.post(Uri.parse(API.addCustomer), body: {
      'pec_code': Users.username,
      'pec_group': Users.pec_group,
      'code': _code.text.trim(),
      'company_name_en': _customerNameEN.text.trim(),
      'company_name_th': _customerNameTH.text.trim(),
      'industry_category': industry_category,
    });
  }

  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 50,
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'New Customer',
                style: TextStyle(
                    color: Colors.black54,
                    fontFamily: 'NexaBold',
                    fontSize: screenWidth / 15),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "(A-Z)",
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: "NexaBold",
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      // alignment: Alignment.centerLeft,
                      child: const Text(
                        "Customer Name EN",
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: "NexaBold",
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: 75.0,
                        child: TextFormField(
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]+')),
                          ],
                          keyboardType: TextInputType.text,
                          controller: _code,
                          cursorColor: Colors.black54,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            hintText: "",
                            hintStyle: TextStyle(
                              color: Colors.black54,
                              fontFamily: "NexaBold",
                              fontSize: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: 275,
                        child: TextFormField(
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]+')),
                          ],
                          keyboardType: TextInputType.text,
                          controller: _customerNameEN,
                          cursorColor: Colors.black54,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            hintText: "",
                            hintStyle: TextStyle(
                              color: Colors.black54,
                              fontFamily: "NexaBold",
                              fontSize: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            textField("", "Customer Name TH", _customerNameTH, 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: DropdownSearch<UserModel>(
                      items: userList,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "Customer",
                          filled: true,
                        ),
                      ),
                      selectedItem: _selectedCustomer,
                      onChanged: (UserModel? data) => setState(() {
                        industry_category = data!.value.toString();
                        _selectedCustomer = data;
                      }),
                      asyncItems: (filter) => getData(filter),
                      compareFn: (i, s) => i.isEqual(s),
                      popupProps: PopupPropsMultiSelection.modalBottomSheet(
                        showSearchBox: true,
                        itemBuilder: _customPopupItemBuilderExample2,
                        favoriteItemProps: FavoriteItemProps(
                          showFavoriteItems: true,
                          favoriteItemBuilder: (context, item, isSelected) {
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
                                    item.name,
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.indigo),
                                  ),
                                  const Padding(
                                      padding: EdgeInsets.only(left: 8)),
                                  isSelected
                                      ? const Icon(Icons.check_box_outlined)
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
                borderRadius: const BorderRadius.all(Radius.circular(100)),
              ),
              margin: const EdgeInsets.only(top: 40),
              child: MaterialButton(
                onPressed: () async {
                  String code = _code.text.trim();
                  String customer_en = _customerNameEN.text.trim();
                  String customer_th = _customerNameTH.text.trim();
                  if (code.isEmpty ||
                      customer_th.isEmpty ||
                      customer_en.isEmpty) {
                    _showMyDialog("Missing Value",
                        "Customer Name TH/EN and code are not must be empty!");
                    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    //     content: Text(
                    //         "Customer Name TH/EN and code are not must be empty!")));
                  } else {
                    addCustomer();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Upload Complete !")));
                    _customerNameTH.clear();
                    _customerNameEN.clear();
                    _code.clear();
                    setState(() {
                      _selectedCustomer = null;
                    });
                  }
                },
                color: Colors.blue,
                textColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: const CircleBorder(),
                child: const Icon(
                  FontAwesomeIcons.upload,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget textField(
      String hint, String title, TextEditingController controller, int lenght) {
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
            inputFormatters: [
              LengthLimitingTextInputFormatter(lenght),
            ],
            keyboardType: TextInputType.text,
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

  void showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      ),
    );
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
        title: Text('${item.name}'),
      ),
    );
  }
}
