import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paperback/borrowed_books_tile.dart';
import 'package:paperback/browse_books_tile.dart';

import 'my_books_tile.dart';

class Groups extends StatefulWidget {
  final String userEmail;
  Groups(this.userEmail);
  @override
  State<StatefulWidget> createState() => GroupsState();
}

class GroupsState extends State<Groups> {
  @override
  Widget build(BuildContext context) {
    return Text("Groups");
  }
}

class Shelf extends StatefulWidget {
  final String userEmail;
  Shelf(this.userEmail);
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
          //TODO: add a button to add new books
          SizedBox(
            height: 30,
          ),
          Text(
            'My Books',
            style: optionStyle,
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
}

class Browse extends StatefulWidget {
  final String userEmail;
  Browse(this.userEmail);
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
              // TODO: filter books only for MY group(s) - saanvi using chosengroup from widget.
              //TODO: go to database and add a field group_id to the books.
              stream: Firestore.instance
                  .collection('books')
                  .where("status", isEqualTo: "not_checked_out")
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
