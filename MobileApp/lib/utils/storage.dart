class UserStorage {
  bool isAdmin = false;
  String email = "#Email";
  String? name = "#Name";

  static final UserStorage _instance = UserStorage._internal();
  UserStorage._internal();

  factory UserStorage() {
    return _instance;
  }

}
