import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:paperback/borrowed_books_tile.dart';
import 'package:paperback/browse_books_tile.dart';

import 'my_books_tile.dart';

class Groups extends StatefulWidget {
  final String userEmail;
  final String userFullName;
  final List<String> userGroups;
  Groups(this.userEmail, this.userGroups, this.userFullName);
  @override
  State<StatefulWidget> createState() =>
      GroupsState(userEmail, userGroups, userFullName);
}

class GroupsState extends State<Groups> {
  static const TextStyle optionStyle = TextStyle(fontSize: 30);
  String _selectedGroup;
  List<String> members;
  String userEmail;
  List<String> userGroups;
  List<String> userGroupNames;
  String userFullName;
  List<DropdownMenuItem<String>> groupDropDown;
  @override
  GroupsState(this.userEmail, this.userGroups, this.userFullName);

  @override
  void initState() {
    loadGroupList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 20),
        Text(
          "My Groups",
          style: optionStyle,
        ),
        groupDropDown != null
            ? DropdownButton<String>(
                hint: new Text('Select A Group'),
                items: groupDropDown,
                value: userGroups[0].toString(),
                onChanged: (value) {
                  Firestore.instance
                      .collection("groups")
                      .where("group_code", isEqualTo: value)
                      .getDocuments()
                      .then((res) => {
                            setState(() {
                              _selectedGroup = value;
                              members =
                                  List.from(res.documents[0].data["members"]);
                            })
                          });
                },
                isExpanded: false,
              )
            : Text("Loading ..."),
        SizedBox(height: 20),
        Center(
            child: Text(
                "Invite your friends with the following code: $_selectedGroup")),
        SizedBox(height: 10),
        Text(
          "Members",
          style: TextStyle(fontSize: 25),
        ),
        members != null
            ? ListView.builder(
                padding: const EdgeInsets.all(10),
                scrollDirection: Axis.vertical,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) =>
                    _buildGroupListItem(index, context, members[index]),
              )
            : Text("Please select a group.")
      ],
    );
  }

  void loadGroupList() {
    List<DropdownMenuItem<String>> gDropDown = [];
    loadGroupNames().then((value) {
      for (var i = 0; i < userGroups.length; i++) {
        gDropDown.add(new DropdownMenuItem(
          child: new Text(userGroupNames[i]),
          value: userGroups[i].toString(),
        ));
      }
      setState(() {
        groupDropDown = List.from(gDropDown);
      });
    });

    return;
  }

  Future<void> loadGroupNames() async {
    userGroupNames = new List(userGroups.length);
    for (var i = 0; i < userGroups.length; i++) {
      var doc = await Firestore.instance
          .collection("groups")
          .where("group_code", isEqualTo: userGroups[i].toString())
          .getDocuments();

      userGroupNames[i] = doc.documents[0].data["group_name"].toString();
    }
    return;
  }

  static Widget _buildGroupListItem(
      int index, BuildContext context, String member) {
    return Text(member);
  }
}

class Shelf extends StatefulWidget {
  final String userEmail;
  final List<String> userGroups;
  final String userFullName;
  Shelf(this.userEmail, this.userGroups, this.userFullName);
  @override
  State<StatefulWidget> createState() => ShelfState();
}

class ShelfState extends State<Shelf> with SingleTickerProviderStateMixin {
  static const TextStyle optionStyle = TextStyle(fontSize: 30);
  TabController tabController;
  int selectedIndex;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.index = 0;
    selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          TabBar(
            labelColor: Colors.deepPurple,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            tabs: [
              Tab(
                text: "My Books",
              ),
              Tab(
                text: "Borrowed Books",
              ),
            ],
            controller: tabController,
          ),
          SizedBox(
            height: 30,
          ),
          selectedIndex != null && selectedIndex == 0
              ? Text(
                  'My Books',
                  style: optionStyle,
                )
              : Text(
                  'Borrowed Books',
                  style: optionStyle,
                ),
          SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 10,
          ),
          selectedIndex != null && selectedIndex == 0
              ? StreamBuilder(
                  stream: Firestore.instance
                      .collection('books')
                      .where("owner_email", isEqualTo: widget.userEmail)
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
                  })
              : StreamBuilder(
                  stream: Firestore.instance
                      .collection('books')
                      .where("checked_out_to_email",
                          isEqualTo: widget.userEmail)
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
                          itemBuilder: (context, index) =>
                              _buildBorrowedListItem(index, context,
                                  snapshot.data.documents[index]),
                        );
                    }
                  }),
          SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  static Widget _buildBorrowedListItem(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    return BorrowedBooksTile(documentSnapshot);
  }

  static Widget _buildListItem(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    return MyBooksTile(documentSnapshot);
  }
}

class Browse extends StatefulWidget {
  final String userEmail;
  final String userFullName;
  final List<String> userGroups;
  Browse(this.userEmail, this.userGroups, this.userFullName);
  @override
  State<StatefulWidget> createState() => BrowseState();
}

class BrowseState extends State<Browse> {
  static const TextStyle optionStyle = TextStyle(fontSize: 30);
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 30,
          ),
          Text(
            'Browse Books',
            style: optionStyle,
          ),
          StreamBuilder(
              stream: Firestore.instance
                  .collection('books')
                  .where("status", isEqualTo: "not_checked_out")
                  .where("group_id", whereIn: widget.userGroups)
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
    );
  }

  Widget _buildListItem(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    return BrowseBooksTile(documentSnapshot, widget.userEmail);
  }
}
