import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_string/random_string.dart';

class GlobalAppData {
  static Map<String, String> userMap = new Map(); //{"email":"Full name"}
  static Map<String, String> groupMap = new Map();
  static Map<String, List<String>> memberMap =
      new Map(); //{"email":["group_code1", "group_code2"]}
  static String userEmail;
  static bool isInitialized = false;

  static final GlobalAppData _singleton = new GlobalAppData._internal();

  factory GlobalAppData() {
    return _singleton;
  }

  static Map<String, String> getUserMap() {
    if (isInitialized)
      return userMap;
    else
      return null;
  }

  static Map<String, String> getGroupMap() {
    if (isInitialized)
      return groupMap;
    else
      return null;
  }

  static Map<String, List<String>> getMemberMap() {
    if (isInitialized)
      return memberMap;
    else
      return null;
  }

  static String getUserEmail() {
    if (isInitialized)
      return userEmail;
    else
      return null;
  }

  void resetState() {
    isInitialized = false;
  }

  GlobalAppData._internal();

  Future<bool> init(bool reload) async {
    if (isInitialized && !reload) return true;

    if (reload) isInitialized = false;

    print("init started");
    final FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (user == null || user.email == null) {
      print("getCurrentUser: Email is null");
      return false;
    }

    QuerySnapshot q = await Firestore.instance
        .collection("users")
        .where("email", isEqualTo: user.email)
        .getDocuments();

    if (q.documents.isEmpty) {
      String newGroupId = "g_" + randomAlphaNumeric(6);
      await Firestore.instance.collection('users').add({
        "full_name": user.displayName,
        "email": user.email,
        "group_code": [newGroupId],
      });
      await Firestore.instance.collection("groups").add({
        "group_code": newGroupId,
        "members": [user.email],
        "group_name": "Default Group",
      });
    }

    userEmail = user.email;
    print("usermail - $userEmail");

    QuerySnapshot groupDocs = await Firestore.instance
        .collection("groups")
        .where("members", arrayContains: userEmail)
        .getDocuments();

    // if the user does not exist in database - take them to registration
    List<String> memberList = new List<String>();
    for (DocumentSnapshot doc in groupDocs.documents) {
      groupMap[doc["group_code"]] = doc["group_name"];
      for (String m in doc["members"]) {
        if ((memberList == null) || !memberList.contains(m)) memberList.add(m);
      }

      QuerySnapshot docs = await Firestore.instance
          .collection("users")
          .where("email", whereIn: memberList)
          .getDocuments();
      for (DocumentSnapshot doc in docs.documents) {
        userMap[doc["email"]] = doc["full_name"].toString();
        memberMap[doc["email"]] = List.from(doc["group_code"]);
      }
      print(userMap);
    }
    isInitialized = true;
    print("**********init ended");
    print("userMap: ");
    print(userMap);
    print("groupMap: ");
    print(groupMap);
    print("userEmail: ");
    print(userEmail);
    print("memberMap");
    print(memberMap);

    return true;
  }
}
