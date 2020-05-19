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
                TextFormField(
                  controller: _groupCodeController,
                  decoration: const InputDecoration(labelText: 'Group Code'),
                  validator: (String value) {
//                    if (value.isEmpty) {
//                      return 'Please enter your group code';
//                    }
                    return null;
                  },
                ),
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

  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    _emailController.dispose();
    _passwordController.dispose();
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
        _success = true;
        _userEmail = user.email;
        // TODO: handle radio button and scenario with creating new group
        // TODO: check if the user exists and give error
        // TODO: take group name (home page?)
        if (_groupCodeController.text != "") {
          Firestore.instance.collection('users').add({
            "full_name": _nameController.text,
            "email": _emailController.text,
            "group_code": [_groupCodeController.text],
          });
          Firestore.instance
              .collection("groups")
              .where("group_code", isEqualTo: _groupCodeController.text)
              .getDocuments()
              .then((e) {
            Firestore.instance
                .collection('groups')
                .document(e.documents[0].documentID)
                .updateData({
              "members": FieldValue.arrayUnion([_emailController.text])
            });
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
            "members": [_emailController.text]
          });
        }
        _auth.currentUser().then((val) {
          if (val != null) {
            _pushPage(context, HomePage(0));
          } else {
            _pushPage(context, SignInPage());
          }
        });
      });
    } else {
      _success = false;
    }
  }
}
