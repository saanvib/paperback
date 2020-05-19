// ignore: avoid_web_libraries_in_flutter
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:paperback/home_widgets.dart';
import 'package:paperback/signin_page.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
final FirebaseAuth _auth = FirebaseAuth.instance;

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
//TODO: add chosen group
  //TODO: add my groups

  @override
  void initState() {
    super.initState();
    getCurrentUser().then((result) {
      // If we need to rebuild the widget with the resulting data,
      // make sure to use `setState`
      setState(() {
        userEmail = result;
        // print("Inside setState $result $userEmail");
      });
    });
  }

  List<Widget> _widgetOptions = <Widget>[
    //TODO: pass chosengroup
    Groups(userEmail),
    Browse(userEmail),
    Shelf(userEmail),
  ];

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
                      Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => SignInPage()));
                    },
                  ),
                ]),
            body: _widgetOptions.elementAt(widget._activeTab),
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
    return user.email;
  }

  void signOutGoogle() async {
    await googleSignIn.signOut();

    print("User Sign Out");
  }
}
