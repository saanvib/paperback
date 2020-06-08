import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'global_app_data.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage();
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const TextStyle optionStyle = TextStyle(fontSize: 30);
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    Firestore.instance
        .collection("users")
        .where("email", isEqualTo: GlobalAppData.userEmail)
        .getDocuments()
        .then((value) {
      _nameController.text = value.documents[0].data["full_name"];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                ),
                Text(
                  'Edit Profile',
                  style: optionStyle,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  alignment: Alignment.center,
                  child: RaisedButton(
                    color: Colors.purple,
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        setState(() {
                          Firestore.instance
                              .collection("users")
                              .where("email",
                                  isEqualTo: GlobalAppData.userEmail)
                              .getDocuments()
                              .then((value) async {
                            await Firestore.instance
                                .collection("users")
                                .document(value.documents[0].documentID)
                                .updateData(
                                    {"full_name": _nameController.text});
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                  builder: (_) => HomePage(0)),
                            );
                          });
                        });
                      }
                    },
                    child:
                        Text("Submit", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    _nameController.dispose();
    super.dispose();
  }
}
