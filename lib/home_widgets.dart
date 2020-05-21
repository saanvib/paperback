import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paperback/add_book.dart';
import 'package:paperback/borrowed_books_tile.dart';
import 'package:paperback/browse_books_tile.dart';

import 'my_books_tile.dart';

class Groups extends StatefulWidget {
  final String userEmail;
  final List<String> userGroups;
  Groups(this.userEmail, this.userGroups);
  @override
  State<StatefulWidget> createState() => GroupsState();
}

class GroupsState extends State<Groups> {
  @override
  Widget build(BuildContext context) {
    //TODO: Show the list of groups as dropdown button.
    //TODO: When the user chooses the group, then show the members as email addresses.
    return Text("Groups");
  }
}

class Shelf extends StatefulWidget {
  final String userEmail;
  final List<String> userGroups;
  Shelf(this.userEmail, this.userGroups);
  @override
  State<StatefulWidget> createState() => ShelfState();
}

class ShelfState extends State<Shelf> {
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
            'My Books',
            style: optionStyle,
          ),
          SizedBox(
            height: 20,
          ),
          // TODO: dont like the button style. Change this.
          RaisedButton(
            onPressed: () async {
              _pushPage(
                  context, AddBookPage(widget.userEmail, widget.userGroups));
            },
            child: const Text('Add a Book'),
          ),
          SizedBox(
            height: 10,
          ),
          StreamBuilder(
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
              }),
          SizedBox(
            height: 30,
          ),
          Text(
            'Borrowed Books',
            style: optionStyle,
          ),
          StreamBuilder(
              stream: Firestore.instance
                  .collection('books')
                  .where("checked_out_to_email", isEqualTo: widget.userEmail)
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
                      itemBuilder: (context, index) => _buildBorrowedListItem(
                          index, context, snapshot.data.documents[index]),
                    );
                }
              }),
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

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

class Browse extends StatefulWidget {
  final String userEmail;
  final List<String> userGroups;
  Browse(this.userEmail, this.userGroups);
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
