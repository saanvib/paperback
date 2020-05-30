import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paperback/global_app_data.dart';

import 'model/model_book.dart';

class MyBooksTile extends StatefulWidget {
  final DocumentSnapshot doc;
  MyBooksTile(this.doc);
  @override
  MyBooksTileState createState() => new MyBooksTileState();
}

class MyBooksTileState extends State<MyBooksTile>
    with TickerProviderStateMixin {
  bool expand = false;

  AnimationController controller;
  Animation<double> animation, animationView;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    animation = Tween(begin: 0.0, end: 180.0).animate(controller);
    animationView = CurvedAnimation(parent: controller, curve: Curves.linear);

    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildPanel();
  }

  Widget buildPanel() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            leading: (widget.doc['status'] != "not_checked_out" &&
                    widget.doc['status'] != "checked_out")
                ? Icon(
                    Icons.notifications_active,
                    color: Colors.amber,
                  )
                : widget.doc["status"] == "not_checked_out"
                    ? Icon(Icons.book)
                    : Icon(Icons.check_box),
            title: Text(widget.doc["title"]),
            subtitle: Text(widget.doc["author"]),
            trailing: Icon(Icons.more_vert),
            onTap: () {
              togglePanel();
            },
          ),
          SizeTransition(
            sizeFactor: animationView,
            child: Column(
              children: <Widget>[
                Container(
                    padding: EdgeInsets.all(15),
                    child: widget.doc["status"] == "checkout_requested"
                        ? Text(GlobalAppData
                                .userMap[widget.doc["checked_out_to_email"]] +
                            " would like to checkout this book")
                        : widget.doc["status"] == "return_requested"
                            ? Text(GlobalAppData.userMap[
                                    widget.doc["checked_out_to_email"]] +
                                " would like to return this book")
                            : widget.doc["status"] == "checked_out"
                                ? Text(
                                    "This book is currently checked out to " +
                                        GlobalAppData.userMap[
                                            widget.doc["checked_out_to_email"]])
                                : widget.doc["status"] == "not_checked_out"
                                    ? Text(
                                        "This book is currently sitting on your shelf!")
                                    : Container()),
                Container(
                    padding: EdgeInsets.all(15),
                    child: widget.doc["status"] == "checkout_requested"
                        ? RaisedButton(
                            color: Colors.purple,
                            onPressed: () {
                              Book.checkoutBook(widget.doc["book_id"]);
                            },
                            child: Text(
                              "Deliver",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : widget.doc["status"] == "return_requested"
                            ? RaisedButton(
                                color: Colors.purple,
                                onPressed: () {
                                  Book.returnBook(widget.doc["book_id"]);
                                },
                                child: Text(
                                  "Receive Book",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : Container()),
                Container(
                  padding: EdgeInsets.all(15),
                  child: widget.doc["status"] == "not_checked_out"
                      ? RaisedButton(
                          color: Colors.purple,
                          onPressed: () {
                            _showDialog();
                          },
                          child: Text(
                            "Delete Book",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Container(),
                ),
                Divider(height: 0, thickness: 0.5),
                Container(
                  alignment: Alignment.centerLeft,
                  height: 50,
                  child: Row(
                    children: <Widget>[
                      Spacer(),
                      FlatButton(
                        child: Text(
                          "HIDE",
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                        padding: EdgeInsets.all(0),
                        color: Colors.transparent,
                        onPressed: () {
                          togglePanel();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Delete Book?"),
          content: new Text(
              "This will delete your book from your group\'s book database."),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Delete"),
              onPressed: () {
                Book.deleteBook(widget.doc["book_id"]);
                Navigator.of(context).pop();
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

  void togglePanel() {
    if (!expand) {
      controller.forward();
    } else {
      controller.reverse();
    }
    expand = !expand;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
