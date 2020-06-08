import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'global_app_data.dart';

class ManageGroups extends StatefulWidget {
  ManageGroups();
  @override
  _ManageGroupsState createState() => _ManageGroupsState();
}

class _ManageGroupsState extends State<ManageGroups> {
  static const TextStyle optionStyle = TextStyle(fontSize: 30);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Groups"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 30,
            ),
            Text(
              'Your Groups',
              style: optionStyle,
            ),
            StreamBuilder(
                stream: Firestore.instance
                    .collection('groups')
                    .where("members", arrayContains: GlobalAppData.userEmail)
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
                        itemBuilder: (context, index) => _buildGroupList(
                            index, context, snapshot.data.documents[index]),
                      );
                  }
                }),
          ],
        ),
      ),
    );
  }

  static Widget _buildGroupList(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
          ),
          Text(documentSnapshot.data["group_name"]),
          SizedBox(
            width: 30,
          ),
          RaisedButton(
            child: Text("Leave Group"),
            onPressed: () {
              String groupCode = documentSnapshot.data["group_code"].toString();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: new Text("Leave Group?"),
                    content: new Text(
                        "Are you sure you want to leave this group: ${documentSnapshot.data["group_name"]}?"),
                    actions: <Widget>[
                      new FlatButton(
                          child: new Text("Leave"),
                          onPressed: () {
                            Firestore.instance
                                .collection("users")
                                .where("email",
                                    isEqualTo: GlobalAppData.userEmail)
                                .getDocuments()
                                .then(
                              (value) {
                                Firestore.instance
                                    .collection('users')
                                    .document(value.documents[0].documentID)
                                    .updateData({
                                  "group_code":
                                      FieldValue.arrayRemove([groupCode])
                                });
                                Navigator.of(context).pop();
                              },
                            );
                            Firestore.instance
                                .collection("groups")
                                .where("group_code", isEqualTo: groupCode)
                                .getDocuments()
                                .then(
                              (value) {
                                if ((List.from(value
                                                .documents[0].data["members"])
                                            .length ==
                                        1) &&
                                    (List.from(
                                            value.documents[0].data["members"])
                                        .contains(GlobalAppData.userEmail))) {
                                  Firestore.instance
                                      .collection('groups')
                                      .document(value.documents[0].documentID)
                                      .delete();
                                } else {
                                  Firestore.instance
                                      .collection('groups')
                                      .document(value.documents[0].documentID)
                                      .updateData({
                                    "members": FieldValue.arrayRemove(
                                        [GlobalAppData.userEmail])
                                  });
                                }
                                Navigator.of(context).pop();
                              },
                            );
                          }),
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
            },
          )
        ],
      ),
    );
  }
}
