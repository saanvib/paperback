// ignore: avoid_web_libraries_in_flutter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paperback/signin_page.dart';

import 'home_widgets.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

//TODO: test if the user is logged out then redirect to home page.
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

  @override
  void initState() {
    super.initState();
    getCurrentUser().then((result) {
      // If we need to rebuild the widget with the resulting data,
      // make sure to use `setState`
      //userEmail = result;
      userEmail = result;
      Firestore.instance
          .collection('users')
          .where("email", isEqualTo: userEmail)
          .getDocuments()
          .then((value) {
        setState(() {
          userGroups = List.from(value.documents[0].data["group_code"]);
          print("groups: ");
          print(userGroups);
          // print("Inside setState $result $userEmail");
          _widgetOptions = <Widget>[
            Groups(userEmail, userGroups),
            Browse(userEmail, userGroups),
            Shelf(userEmail, userGroups),
          ];
        });
      });
    });
  }

  List<Widget> _widgetOptions;

  void _onItemTapped(int index) {
    setState(() {
      widget._activeTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return userEmail == null
        ? Text("Loading ... ")
        : Scaffold(
            appBar: AppBar(title: Text(widget.title),
                // leading: new Container(),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: null,
                  ),
                  IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () async {
                      await _auth.signOut();
                      signOutGoogle();
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                              builder: (_) => SignInPage()));
                    },
                  ),
                ]),
            body: (userEmail != null &&
                    userGroups != null &&
                    _widgetOptions != null)
                ? _widgetOptions.elementAt(widget._activeTab)
                : Container(
                    child: Text("Loading ..."),
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
  }

  getCurrentUser() async {
    final FirebaseUser user = await _auth.currentUser();
    // Similarly we can get email as well
    // print(user.email);

    if (user == null || user.email == null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => SignInPage()));
    } else {
      print("User email is " + user.email);
    }

    return user.email;
  }

  void signOutGoogle() async {
    await googleSignIn.signOut();

    print("User Sign Out");
  }
}
