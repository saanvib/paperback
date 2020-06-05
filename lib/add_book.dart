// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:barcode_scan/platform_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:paperback/global_app_data.dart';
import 'package:http/http.dart' as http;

import 'home_page.dart';
import 'model/model_book.dart';

class AddBookPage extends StatefulWidget {
  final String title = 'Add a Book';
  final String userEmail;
  final List<String> userGroups;
  AddBookPage(this.userEmail, this.userGroups);
  @override
  State<StatefulWidget> createState() => AddBookPageState();
}

class AddBookPageState extends State<AddBookPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  String _selectedGroup;
  bool _success;

  @override
  void initState() {
    _selectedGroup = widget.userGroups[0].toString();
    super.initState();
  }

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
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  alignment: Alignment.center,
                  child: RaisedButton(
                    onPressed: () async {
                      var result = await BarcodeScanner.scan();
                      String isbn = result.rawContent;
                      print(isbn); // The barcode content
                      print(
                          'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data');
                      final response = await http.get(
                          'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data');

                      if (response.statusCode == 200) {
                        var jsonResponse = json.decode(response.body);
                        if (jsonResponse != null &&
                            jsonResponse.toString() != "{}") {
                          print(json.decode(response.body)["ISBN:$isbn"]
                              ['title']);
                          print(json.decode(response.body)["ISBN:$isbn"]
                              ['authors'][0]["name"]);
                          _titleController.text =
                              json.decode(response.body)["ISBN:$isbn"]['title'];
                          _authorController.text =
                              json.decode(response.body)["ISBN:$isbn"]
                                  ['authors'][0]["name"];
                          setState(() {
                            _success = true;
                          });
                        } else {
                          print("json null");
                          setState(() {
                            _success = false;
                          });
                        }
                      } else {
                        print("status code :" + response.statusCode.toString());
                        setState(() {
                          _success = false;
                        });
                      }
//                      Book.addBook(
//                          json.decode(response.body)['title'],
//                          json.decode(response.body)['authors'][0]["name"],
//                          widget.userEmail,
//                          _selectedGroup);
                      //_pushReplacementPage(context, HomePage(2));
                    },
                    // TODO: check if book already exists in database?
                    child: const Text('Scan Book'),
                  ),
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Book Title'),
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Please enter the title of your book. Capitalize as necessary.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: 'Book Author'),
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Please enter the author of your book. Capitalize as necessary.';
                    }
                    return null;
                  },
                ),
                widget.userGroups != null
                    ? DropdownButton<String>(
                        hint: new Text('Select Group'),
                        items: loadGroupList(),
                        value: _selectedGroup,
                        onChanged: (value) {
                          setState(() {
                            _selectedGroup = value;
                          });
                        },
                        isExpanded: true,
                      )
                    : Text("Loading ... "),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  alignment: Alignment.center,
                  child: RaisedButton(
                    onPressed: () async {
                      {
                        Book.addBook(
                            _titleController.text,
                            _authorController.text,
                            widget.userEmail,
                            _selectedGroup);
                        setState(() {
                          _success = null;
                        });
                        _pushReplacementPage(context, HomePage(2));
                      }
                    },
                    // TODO: check if book already exists in database?
                    child: const Text('Submit'),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(_success == null
                      ? ''
                      : (_success
                          ? 'Scan successful. Review and hit submit.  '
                          : 'Scan could not find the book. Please add manually.')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> loadGroupList() {
    List<DropdownMenuItem<String>> groupList = [];
    for (var i = 0; i < widget.userGroups.length; i++) {
      groupList.add(new DropdownMenuItem(
        child: new Text(GlobalAppData.groupMap[widget.userGroups[i]]),
        value: widget.userGroups[i].toString(),
      ));
    }

    return groupList;
  }

  void _pushReplacementPage(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed

    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }
}
