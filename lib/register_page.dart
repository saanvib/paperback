// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paperback/password_field.dart';
import 'package:paperback/signin_page.dart';
import 'package:random_string/random_string.dart';

import 'home_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class RegisterPage extends StatefulWidget {
  final String title = 'Registration';
  @override
  State<StatefulWidget> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupCodeController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  bool isNewGroup;
  String groupValue;
  bool _success;
  String _userEmail;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                PasswordFormField(
                  controller: _passwordController,
                ),
                Row(
                  children: <Widget>[
                    Radio(
                      value: "Existing Group",
                      groupValue: groupValue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) {
                        setState(() {
                          groupValue = "Existing Group";
                          isNewGroup = false;
                        });
                      },
                    ),
                    Text(
                      "Existing Group",
                    ),
                    Container(width: 10),
                    Radio(
                      value: "New Group",
                      groupValue: groupValue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) {
                        setState(() {
                          groupValue = "New Group";
                          isNewGroup = true;
                        });
                      },
                    ),
                    Text(
                      "New Group",
                    ),
                  ],
                ),
                (isNewGroup != null && !isNewGroup)
                    ? TextFormField(
                        controller: _groupCodeController,
                        decoration:
                            const InputDecoration(labelText: 'Group Code'),
                        validator: (String value) {
                          if (value.isEmpty) {
                            return 'Please enter the group code';
                          }
                          return null;
                        },
                      )
                    : isNewGroup != null
                        ? TextFormField(
                            controller: _groupNameController,
                            decoration: const InputDecoration(
                                labelText: 'Enter a New Group Name'),
                            validator: (String value) {
                              if (value.isEmpty) {
                                return 'Please enter a group name';
                              }
                              return null;
                            },
                          )
                        : Container(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  alignment: Alignment.center,
                  child: RaisedButton(
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        _register(context);
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(_success == null
                      ? ''
                      : (_success
                          ? 'Successfully registered ' + _userEmail
                          : 'Registration failed')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pushReplacementPage(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    _emailController.dispose();
    _passwordController.dispose();
    _groupCodeController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  // Example code for registration.
  void _register(BuildContext context) async {
    final FirebaseUser user = (await _auth.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    ))
        .user;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
        // TODO: check if the user exists and give error
        if (_groupCodeController.text != "") {
          Firestore.instance
              .collection("groups")
              .where("group_code", isEqualTo: _groupCodeController.text)
              .getDocuments()
              .then((e) {
            if (e.documents.length == 0) {
              //TODO: fix this
              final snackBar = SnackBar(
                content: Text('Wrong group code? Please check again.'),
              );

              // Find the Scaffold in the widget tree and use
              // it to show a SnackBar.
              Scaffold.of(context).showSnackBar(snackBar);
              _success = false;
              return;
            } else
              Firestore.instance
                  .collection('groups')
                  .document(e.documents[0].documentID)
                  .updateData({
                "members": FieldValue.arrayUnion([_emailController.text])
              });
          });
          Firestore.instance.collection('users').add({
            "full_name": _nameController.text,
            "email": _emailController.text,
            "group_code": [_groupCodeController.text],
          });
        } else {
          String newGroupId = "g_" + randomAlphaNumeric(6);
          Firestore.instance.collection('users').add({
            "full_name": _nameController.text,
            "email": _emailController.text,
            "group_code": [newGroupId],
          });
          Firestore.instance.collection("groups").add({
            "group_code": newGroupId,
            "members": [_emailController.text],
            "group_name": _groupNameController.text,
          });
        }
        _success = true;
        _auth.currentUser().then((val) {
          if (val != null) {
            _pushReplacementPage(context, HomePage(0));
          } else {
            _pushReplacementPage(context, SignInPage());
          }
        });
      });
    } else {
      _success = false;
    }
  }
}
