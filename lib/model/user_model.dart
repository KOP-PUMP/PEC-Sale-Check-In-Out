class UserModel {
  final String id;
  // final DateTime createdAt;
  final String name;
  final String code;
  final String nameEN;
  final String nameTH;
  final String province_th;
  final String tambon_th;
  final String address_en;


  final String customer_name_show;
  // final String avatar;

  UserModel({
    required this.id,
    required this.code,
    required this.name,
    required this.nameEN,
    required this.customer_name_show,
    required this.nameTH,
    required this.province_th,
    required this.tambon_th,
    required this.address_en,
    // required this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        id: json["id"],
        code: json["customer_code"],
        name: json["customer"],
        nameEN: json["customer_EN"],
        customer_name_show: json["customer_name_show"],
        nameTH: json["company_name_th"],
        province_th: json["province_th"],
        tambon_th: json["tambon_th"],
        address_en: json["address_en"],
        
        // // avatar: json["avatar"],
        );
  }

  static List<UserModel> fromJsonList(List list) {
    return list.map((item) => UserModel.fromJson(item)).toList();
  }

  ///this method will prevent the override of toString
  String userAsString() {
    return '#${this.id} ${this.code} ${this.name} ${this.nameEN} ';
  }

  ///this method will prevent the override of toString
  bool userFilterByCreationDate(String filter) {
    return this.nameEN.toString().contains(filter) || this.name.toString().contains(filter);
       
  }

  ///custom comparing function to check if two users are equal
  bool isEqual(UserModel model) {
    return this.id == model.id;
  }

  @override
  String toString() => '$customer_name_show';
 
}
