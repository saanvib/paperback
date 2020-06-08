import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:paperback/borrowed_books_tile.dart';
import 'package:paperback/browse_books_tile.dart';
import 'package:paperback/global_app_data.dart';
import 'package:random_string/random_string.dart';
import 'package:share/share.dart';

import 'home_page.dart';
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
  static const TextStyle optionStyle = TextStyle(fontSize: 20);
  String _selectedGroup;
  List<String> members;
  String userEmail;
  List<String> userGroups;
//  List<String> userGroupNames;
  String userFullName;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _groupCodeController = TextEditingController();
  List<DropdownMenuItem<String>> groupDropDown;
  @override
  GroupsState(this.userEmail, this.userGroups, this.userFullName);
  bool _success;

  @override
  void initState() {
    super.initState();
    _selectedGroup = userGroups[0].toString();
    Firestore.instance
        .collection("groups")
        .where("group_code", isEqualTo: _selectedGroup)
        .getDocuments()
        .then((res) => {
              setState(() {
                members = List.from(res.documents[0].data["members"]);
              })
            });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 40),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            "Welcome, Book Worm, to your own private library. Create your own group or join an existing one.\  "
            "And then... Voila! Borrow and lend books among your friends. It\'s that simple!",
            style: TextStyle(fontSize: 15),
          ),
        ),
        SizedBox(
          height: 30,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlatButton(
              color: Colors.purple,
              child: Text(
                "Create Group",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _createNewGroupDialog();
              },
            ),
            SizedBox(
              width: 30,
            ),
            FlatButton(
              color: Colors.purple,
              child: Text(
                "Join a Group",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _addNewGroupDialog();
              },
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        Divider(),
        SizedBox(
          height: 30,
        ),
        Text(
          "My Groups",
          style: optionStyle,
        ),
        StreamBuilder(
            stream: Firestore.instance
                .collection('groups')
                .where("group_code", whereIn: userGroups)
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return new Text('Loading...');
                default:
                  return new DropdownButton<String>(
                    hint: new Text('Select A Group'),
                    value: _selectedGroup,
                    items: snapshot.data.documents
                        .map((DocumentSnapshot document) {
                      return new DropdownMenuItem<String>(
                        value: document.data['group_code'],
                        child: new Text(document.data['group_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      Firestore.instance
                          .collection("groups")
                          .where("group_code", isEqualTo: value)
                          .getDocuments()
                          .then((res) => {
                                setState(() {
                                  _selectedGroup = value;
                                  members = List.from(
                                      res.documents[0].data["members"]);
                                })
                              });
                    },
                    isExpanded: false,
                  );
              }
            }),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("You group code is: $_selectedGroup: "),
            FlatButton(
              onPressed: () {
                Share.share(
                    'I would like to exchange books with you and this app (https://paperback.omniate.com) helps to keep track. \ '
                    'Use group code $_selectedGroup at registration time to join my group. ',
                    subject: 'Lets share books!');
              },
              child: Text(
                "Invite friends",
                style: TextStyle(color: Colors.purple),
              ),
            )
          ],
        ),
        SizedBox(height: 30),
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
            : Text("Please select a group above.")
      ],
    );
  }

  void _addNewGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: new Text("Join a Group"),
            content: Container(
              height: 150,
              child: Column(
                children: [
                  Text("This will add you to an existing group."),
                  TextFormField(
                    controller: _groupCodeController,
                    decoration: const InputDecoration(labelText: 'Group Code'),
                    validator: (String value) {
                      if (value.isEmpty) {
                        return 'Please enter the group code';
                      }
                      return null;
                    },
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: Text(_success == null
                        ? ''
                        : (_success
                            ? 'Successfully added group'
                            : 'Failed to add group. Wrong group code?')),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Add"),
                onPressed: () async {
                  String newGroupId = _groupCodeController.text;

                  QuerySnapshot e = await Firestore.instance
                      .collection("groups")
                      .where("group_code", isEqualTo: newGroupId)
                      .getDocuments();

                  if (e.documents.isEmpty) {
                    setState(() {
                      _success = false;
                    });
                  } else {
                    Firestore.instance
                        .collection("users")
                        .where("email", isEqualTo: userEmail)
                        .getDocuments()
                        .then((value) {
                      Firestore.instance
                          .collection('users')
                          .document(value.documents[0].documentID)
                          .updateData({
                        "group_code": FieldValue.arrayUnion([newGroupId])
                      });
                    });
                    Firestore.instance
                        .collection("groups")
                        .where("group_code", isEqualTo: newGroupId)
                        .getDocuments()
                        .then((v) {
                      Firestore.instance
                          .collection("groups")
                          .document(v.documents[0].documentID)
                          .updateData({
                        "members": FieldValue.arrayUnion([userEmail])
                      });
                      setState(() {
                        HomePageState.resetInit();
                      });
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _createNewGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Create a Group"),
          content: Container(
            height: 130,
            child: Column(
              children: [
                Text("This will create a new group."),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Group Name'),
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Enter a group name.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Add"),
              onPressed: () async {
                String newGroupId = "g_" + randomAlphaNumeric(6);

                await Firestore.instance.collection("groups").add({
                  "group_code": newGroupId,
                  "members": [userEmail],
                  "group_name": _titleController.text,
                });
                Firestore.instance
                    .collection("users")
                    .where("email", isEqualTo: userEmail)
                    .getDocuments()
                    .then((value) {
                  Firestore.instance
                      .collection('users')
                      .document(value.documents[0].documentID)
                      .updateData({
                    "group_code": FieldValue.arrayUnion([newGroupId])
                  });

                  setState(() {
                    HomePageState.resetInit();
                    Navigator.of(context).pop();
                  });
                });
              },
            ),
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Widget _buildGroupListItem(
      int index, BuildContext context, String member) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: ListTile(
          leading: Icon(Icons.person),
          title: Text(GlobalAppData.userMap[member]),
          subtitle: Text(member),
        ));
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
                        return snapshot.data.documents.isEmpty
                            ? Column(
                                children: [
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Text(
                                        "You have not added any books to your shelf. Use the + button below to add books. "),
                                  ),
                                ],
                              )
                            : new ListView.builder(
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
                        return snapshot.data.documents.isEmpty
                            ? Column(
                                children: [
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Text(
                                        "You have not borrowed any books. You can borrow books from friends in your group by using the browse tab."),
                                  ),
                                ],
                              )
                            : new ListView.builder(
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
                    return snapshot.data.documents.isEmpty
                        ? Column(
                            children: [
                              SizedBox(
                                height: 30,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                    "There are no books to borrow in your group. Either all books are checked \ "
                                    "out or there are no books added to your groups or you don't have any friends in your group. "),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                    "Invite your friends to your group or join another group from home page. "),
                              ),
                            ],
                          )
                        : new ListView.builder(
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
