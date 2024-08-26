

class UserModel {
  final String id;
  final String name;
  final String value;

  UserModel({
    required this.id,
    required this.value,
    required this.name,
    // required this.avatar,
  });

   factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      // createdAt: DateTime.parse(json["createdAt"]),
      name: json["industry"],
      value: json["value"],
    );
  }

  static List<UserModel> fromJsonList(List list) {
    return list.map((item) => UserModel.fromJson(item)).toList();
  }

  ///this method will prevent the override of toString
  String userAsString() {
    return '#${this.id} ${this.name} ${this.value}';
  }

  ///this method will prevent the override of toString
  bool userFilterByCreationDate(String filter) {
    return this.name.toString().contains(filter);
  }

  ///custom comparing function to check if two users are equal
  bool isEqual(UserModel model) {
    return this.id == model.id;
  }

  @override
  String toString() {
    return '$name';
  }
}