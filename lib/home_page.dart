// ignore: avoid_web_libraries_in_flutter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paperback/edit_profile.dart';
import 'package:paperback/manage_groups.dart';
import 'package:paperback/signin_page.dart';

import 'add_book.dart';
import 'global_app_data.dart';
import 'home_widgets.dart';
import 'model/model_book.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
GlobalAppData appData = new GlobalAppData();

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  final String title = 'Home Page';
  int _activeTab;
  HomePage(this._activeTab);
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  static const TextStyle optionStyle = TextStyle(fontSize: 30);
  static String userEmail;
  static List<String> userGroups;
  String userFullName;
  String userInitials;
  static bool isInitialized = false;
  @override
  void initState() {
    super.initState();
  }

  List<Widget> _widgetOptions;

  void _onItemTapped(int index) {
    setState(() {
      widget._activeTab = index;
    });
  }

  static void resetInit() {
    isInitialized = false;
  }

  Future<bool> init() async {
    bool initDone;
    if (!isInitialized)
      initDone = await appData.init(true);
    else
      initDone = await appData.init(false);

    userEmail = GlobalAppData.userEmail;
    print("init $userEmail");
    userGroups = GlobalAppData.memberMap[userEmail];
    userFullName = GlobalAppData.userMap[userEmail];
    print(userFullName);
    userInitials = userFullName.split(" ").length > 1
        ? userFullName.split(" ")[0][0] + userFullName.split(" ")[1][0]
        : userFullName[0];
    userInitials = userInitials.toUpperCase();

    _widgetOptions = <Widget>[
      Groups(userEmail, userGroups, userFullName),
      Browse(userEmail, userGroups, userFullName),
      Shelf(userEmail, userGroups, userFullName),
    ];
    isInitialized = true;

    return initDone;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return buildApp(context, snapshot);
      },
    );
  }

  Widget buildApp(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasData)
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _pushPage(context, AddBookPage(userEmail, userGroups));
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.purple,
        ),
        appBar: AppBar(
          title: Text("Home"),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: _widgetOptions.elementAt(widget._activeTab)),
        drawer: Drawer(
          child: (isInitialized)
              ? ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    UserAccountsDrawerHeader(
                      accountName: Text(userFullName),
                      accountEmail: Text(userEmail),
                      currentAccountPicture: CircleAvatar(
                        child: new Text(userInitials),
                      ),
                    ),
//                    Container(
//                      padding: EdgeInsets.symmetric(horizontal: 70),
//                      child: RaisedButton(
//                        color: Colors.purple,
//                        child: Text(
//                          "Reset Password",
//                          style: TextStyle(color: Colors.white),
//                        ),
//                        onPressed: () async {
//                          _auth.currentUser().then((value) {
//                            List<UserInfo> providerData = value.providerData;
//                            print(providerData.length);
//                            for (UserInfo userInfo in providerData) {
//                              switch (userInfo.providerId) {
//                                case "Google":
//                                  {
//                                    print(
//                                        "Google auth - ignoring password reset");
//                                  }
//                                  break;
//
//                                default:
//                                  {
//                                    _auth.sendPasswordResetEmail(
//                                        email: value.email);
//                                    print("Provider ... " + value.providerId);
//                                    _auth.signOut();
//                                    Navigator.of(context).pushReplacement(
//                                        MaterialPageRoute<void>(
//                                            builder: (_) => SignInPage()));
//                                  }
//                                  break;
//                              }
//                            }
//                          });
//                          Navigator.pop(context);
//                        },
//                      ),
//                    ),
                    ListTile(
                      leading: Icon(Icons.person_pin),
                      title: Text(
                        "Edit Profile",
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pop(context);
                        _pushPage(context, ProfilePage());
                      },
                    ),

                    ListTile(
                      leading: Icon(Icons.people),
                      title: Text(
                        "Manage groups",
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pop(context);
                        _pushPage(context, ManageGroups());
                      },
                    ),

                    Divider(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 70),
                      child: RaisedButton(
                        color: Colors.purple,
                        child: Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () async {
                          await _auth.signOut();
                          signOutGoogle();
                          resetInit();
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                  builder: (_) => SignInPage()));
                        },
                      ),
                    )
                  ],
                )
              : Text("Loading.. "),
        ),
        endDrawer: Drawer(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                child: Column(
                  children: [
                    Text(
                      'Notifications',
                      style: optionStyle,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                        "Please accept return or deliver the books from list below. ")
                  ],
                ),
              ),
              StreamBuilder(
                  stream: Firestore.instance
                      .collection('books')
                      .where("owner_email", isEqualTo: userEmail)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return new Text('Loading...');
                      default:
                        return new ListView.builder(
                          padding: const EdgeInsets.all(10),
                          scrollDirection: Axis.vertical,
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data.documents.length,
                          itemBuilder: (context, index) => _buildListItem(
                              index, context, snapshot.data.documents[index]),
                        );
                    }
                  }),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              title: Text('Browse'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.playlist_add_check),
              title: Text('My Shelf'),
            ),
          ],
          currentIndex: widget._activeTab,
//selectedItemColor: MyColors.lemonDark,
          onTap: _onItemTapped,
        ),
      );
    else
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
  }

  static Widget _buildListItem(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    return (documentSnapshot["status"] == "checkout_requested") ||
            (documentSnapshot["status"] == "return_requested")
        ? ListTile(
            title: Text(documentSnapshot["title"]),
            subtitle: (documentSnapshot["status"] == "checkout_requested")
                ? Text("This book has been requested by " +
                    documentSnapshot["checked_out_to_email"])
                : Text(documentSnapshot["checked_out_to_email"] +
                    " would like to return the book."),
            trailing: (documentSnapshot["status"] == "checkout_requested")
                ? RaisedButton(
                    color: Colors.purple,
                    onPressed: () {
                      Book.checkoutBook(documentSnapshot["book_id"]);
                    },
                    child: Text(
                      "Deliver",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : RaisedButton(
                    color: Colors.purple,
                    onPressed: () {
                      Book.returnBook(documentSnapshot["book_id"]);
                    },
                    child: Text(
                      "Accept Return",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          )
        : Container();
  }

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<String> getCurrentUser() async {
    final FirebaseUser user = await _auth.currentUser();
    // Similarly we can get email as well
    // print(user.email);

    if (user == null || user.email == null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => SignInPage()));
      return null;
    } else {
      print("User email is " + user.email);
      return user.email;
    }

//    return "rishi.bhargava@gmail.com";
  }

  void signOutGoogle() async {
    await googleSignIn.disconnect();

    print("User Sign Out");
  }
}
