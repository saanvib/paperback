// ignore: avoid_web_libraries_in_flutter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paperback/signin_page.dart';

import 'add_book.dart';
import 'home_widgets.dart';
import 'model/model_book.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userFullName;
  String userInitials;
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
          userFullName = value.documents[0].data["full_name"];
          userInitials = userFullName.split(" ").length > 1
              ? userFullName.split(" ")[0][0] + userFullName.split(" ")[1][0]
              : userFullName[0];
          userInitials = userInitials.toUpperCase();
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

  void _openEndDrawer() {
    _scaffoldKey.currentState.openEndDrawer();
  }

  void _closeEndDrawer() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return (userFullName == null || userEmail == null || userInitials == null)
        ? Text("Loading ... ")
        : Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _pushPage(context, AddBookPage(userEmail, userGroups));
              },
              child: Icon(Icons.add),
              backgroundColor: Colors.purple,
            ),
            appBar: AppBar(
              title: Text(widget.title),
              // leading: new Container(),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                  ),
                ),
              ],
            ),
            body: (userEmail != null &&
                    userGroups != null &&
                    _widgetOptions != null)
                ? _widgetOptions.elementAt(widget._activeTab)
                : Container(
                    child: Text("Loading ..."),
                  ),
            drawer: Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    accountName: Text(userFullName),
                    accountEmail: Text(userEmail),
                    currentAccountPicture: CircleAvatar(
                      child: new Text(userInitials),
                    ),
                  ),
//                  ListTile(
//                    title: Text('Edit Profile'),
//                    onTap: () {
//                      // Update the state of the app
//                      // ...
//                      // Then close the drawer
//                      Navigator.pop(context);
//                    },
//                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 70),
                    child: RaisedButton(
                      child: Text("Logout"),
                      onPressed: () async {
                        await _auth.signOut();
                        signOutGoogle();
                        Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                                builder: (_) => SignInPage()));
                      },
                    ),
                  )
                ],
              ),
            ),
            endDrawer: Drawer(
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(15),
                  ),
                  const Text(
                    'Notifications',
                    style: optionStyle,
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
                                  index,
                                  context,
                                  snapshot.data.documents[index]),
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
  }

  static Widget _buildListItem(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    return (documentSnapshot["status"] == "checkout_requested") ||
            (documentSnapshot["status"] == "return_requested")
        ? ListTile(
            title: Text(documentSnapshot["title"]),
            subtitle: (documentSnapshot["status"] == "checkout_requested")
                ? Text("Book requested by " +
                    documentSnapshot["checked_out_to_email"])
                : Text(documentSnapshot["checked_out_to_email"] +
                    " would like to return the book."),
            trailing: (documentSnapshot["status"] == "checkout_requested")
                ? RaisedButton(
                    onPressed: () {
                      Book.checkoutBook(documentSnapshot["book_id"]);
                    },
                    child: Text("Deliver"),
                  )
                : RaisedButton(
                    onPressed: () {
                      Book.returnBook(documentSnapshot["book_id"]);
                    },
                    child: Text("Accept Return"),
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
