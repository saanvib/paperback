import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return SingleChildScrollView(
        padding: EdgeInsets.all(8),
        scrollDirection: Axis.vertical,
        child: Column(children: <Widget>[
          buildPanel(),
        ]));
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
            leading: Icon(Icons.book),
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
                        ? RaisedButton(
                            onPressed: () {
                              Book.checkoutBook(widget.doc["book_id"]);
                            },
                            child: Text("Deliver"),
                          )
                        : widget.doc["status"] == "return_requested"
                            ? RaisedButton(
                                onPressed: () {
                                  Book.returnBook(widget.doc["book_id"]);
                                },
                                child: Text("Receive Book"),
                              )
                            : Container()),
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
