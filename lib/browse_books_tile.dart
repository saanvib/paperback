import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'model/model_book.dart';

class BrowseBooksTile extends StatefulWidget {
  final DocumentSnapshot doc;
  final String userEmail;
  BrowseBooksTile(this.doc, this.userEmail);
  @override
  BrowseBooksTileState createState() => new BrowseBooksTileState();
}

class BrowseBooksTileState extends State<BrowseBooksTile>
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
                Text("Owner\'s Email: " + widget.doc["owner_email"].toString()),
                Container(
                    padding: EdgeInsets.all(15),
                    child: ((widget.doc["status"] == "not_checked_out") &&
                            (widget.doc["owner_email"] != widget.userEmail))
                        ? RaisedButton(
                            onPressed: () {
                              Book.requestCheckout(
                                  widget.doc["book_id"], widget.userEmail);
                            },
                            child: Text("Request Checkout"),
                          )
                        : ((widget.doc["status"] == "checkout_requested") &&
                                (widget.doc["owner_email"] != widget.userEmail))
                            ? Text("Your checkout request is being processed.")
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
