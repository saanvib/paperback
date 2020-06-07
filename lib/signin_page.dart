import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paperback/home_page.dart';
import 'package:paperback/password_field.dart';
import 'package:paperback/register_page.dart';
import 'dart:io' show Platform;

import 'google_register_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
  ],
);

class SignInPage extends StatefulWidget {
  final String title = 'Paperback';
  @override
  State<StatefulWidget> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (BuildContext context) {
        return Center(
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    Center(
                        child: Text(
                      'Paperback',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                    )),
                    SizedBox(
                      height: 30,
                    ),
                    Center(
                        child: Text(
                      'Sign in',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                    )),
                    _EmailPasswordForm(),
                    Platform.isIOS ? AppleSignInSection() : Container(),
                    _GoogleSignInSection(),
                    Container(
                      width: double.infinity,
                      child: FlatButton(
                        child: Text(
                          "New user? Sign Up",
                          style: TextStyle(color: Colors.purpleAccent[400]),
                        ),
                        color: Colors.transparent,
                        onPressed: () {
                          _pushPage(context, RegisterPage());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

void signOutGoogle() async {
  await googleSignIn.signOut();

  print("User Sign Out");
}

class _GoogleSignInSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends State<_GoogleSignInSection> {
  bool isGoogleNewUser;
  bool _success;
  String _userID;
  String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          alignment: Alignment.center,
          child: SignInButton(
            Buttons.Google,
            onPressed: () {
              signInWithGoogle().then((value) {
                if (value) {
                  if (isGoogleNewUser != null && isGoogleNewUser) {
                    _pushReplacementPage(context, GoogleRegisterPage());
                  } else {
                    _pushReplacementPage(context, HomePage(0));
                  }
                } else {
                  setState(() {
                    _success = value;
                  });
                }
              });
            },
          ),
        ),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _success == null
                ? ''
                : (_success
                    ? 'Successfully signed in, uid: ' + _userID
                    : 'Sign in failed: $errorMessage'),
            style: TextStyle(color: Colors.red),
          ),
        )
      ],
    );
  }

//  Widget _signInButton(BuildContext context) {
//    return OutlineButton(
//      splashColor: Colors.grey,
//      onPressed: () {
//        signInWithGoogle().then((value) {
//          if (value) {
//            if (isGoogleNewUser != null && isGoogleNewUser) {
//              _pushReplacementPage(context, GoogleRegisterPage());
//            } else {
//              _pushReplacementPage(context, HomePage(0));
//            }
//          } else {
//            setState(() {
//              _success = value;
//            });
//          }
//        });
//      },
//      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
//      highlightElevation: 0,
//      borderSide: BorderSide(color: Colors.grey),
//      child: Padding(
//        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
//        child: Row(
//          mainAxisSize: MainAxisSize.min,
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: <Widget>[
//            Image(image: AssetImage("images/google-logo.jpg"), height: 35.0),
//            Padding(
//              padding: const EdgeInsets.only(left: 10),
//              child: Text(
//                'Sign in with Google',
//                style: TextStyle(
//                  fontSize: 20,
//                  color: Colors.grey,
//                ),
//              ),
//            )
//          ],
//        ),
//      ),
//    );
//  }

  Future<bool> signInWithGoogle() async {
    //TODO: handle the exception for sign_in_failed

    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      final AuthResult authResult =
          await _auth.signInWithCredential(credential);
      final FirebaseUser user = authResult.user;

      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);
      print("user full name : " + user.displayName);

      QuerySnapshot q = await Firestore.instance
          .collection("users")
          .where("email", isEqualTo: currentUser.email)
          .getDocuments();

      if (authResult.additionalUserInfo.isNewUser || q.documents.isEmpty) {
        isGoogleNewUser = true;
      } else {
        isGoogleNewUser = false;
      }

      print('signInWithGoogle succeeded: $user');
      _success = true;
      return true;
    } catch (error) {
      switch (error.code) {
        case "SIGN_IN_FAILED":
          errorMessage = "An unexpected error occurred while signing.";
          break;
        default:
          errorMessage = "An unexpected error occurred while signing.";
          break;
      }
      print("Sign in failed: error");
      _success = false;
      return false;
    }
  }
}

class AppleSignInSection extends StatefulWidget {
  @override
  _AppleSignInSectionState createState() => _AppleSignInSectionState();
}

class _AppleSignInSectionState extends State<AppleSignInSection> {
  // Determine if Apple SignIn is available
  Future<bool> get appleSignInAvailable => AppleSignIn.isAvailable();
  bool _success;
  bool isNewUser;
  String errorMessage;

  /// Sign in with Apple
  Future<bool> appleSignIn() async {
    try {
      final AuthorizationResult appleResult =
          await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      if (appleResult.error != null) {
        print(appleResult.error);
      }

      final AuthCredential credential =
          OAuthProvider(providerId: 'apple.com').getCredential(
        accessToken:
            String.fromCharCodes(appleResult.credential.authorizationCode),
        idToken: String.fromCharCodes(appleResult.credential.identityToken),
      );

      AuthResult firebaseResult = await _auth.signInWithCredential(credential);
      FirebaseUser user = firebaseResult.user;

      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await _auth.currentUser();
      print("user full name : " + user.displayName);
      assert(user.uid == currentUser.uid);

      QuerySnapshot q = await Firestore.instance
          .collection("users")
          .where("email", isEqualTo: currentUser.email)
          .getDocuments();

      if (firebaseResult.additionalUserInfo.isNewUser || q.documents.isEmpty) {
        isNewUser = true;
      } else {
        isNewUser = false;
      }

      print('appleSignIn succeeded: $user');
      _success = true;

      return true;
    } catch (error) {
      print(error);

      switch (error.code) {
        case "SIGN_IN_FAILED":
          errorMessage = "An unexpected error occurred while signing.";
          break;
        default:
          errorMessage = "An unexpected error occurred while signing.";
          break;
      }
      print("Sign in failed: error");
      _success = false;
      return _success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          alignment: Alignment.center,
          child: FutureBuilder(
            future: appleSignInAvailable,
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return AppleSignInButton(
                  onPressed: () {
                    appleSignIn().then((value) {
                      if (value) {
                        if (isNewUser != null && isNewUser) {
                          _pushReplacementPage(context, GoogleRegisterPage());
                        } else {
                          _pushReplacementPage(context, HomePage(0));
                        }
                      } else {
                        setState(() {
                          _success = value;
                        });
                      }
                    });
                  },
                );
              } else {
                return Container();
              }
            },
          ),
        ),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _success == null
                ? ''
                : (_success
                    ? 'Successfully signed in.'
                    : 'Sign in failed: $errorMessage'),
            style: TextStyle(color: Colors.red),
          ),
        )
      ],
    );
  }
}

void _pushPage(BuildContext context, Widget page) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

void _pushReplacementPage(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

class _EmailPasswordForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EmailPasswordFormState();
}

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(color: Colors.blue[100]),
    );
  }
}

class _EmailPasswordFormState extends State<_EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _success;
  String _userEmail;
  String errorMessage;
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: RaisedButton(
              color: Colors.purple,
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  _signInWithEmailAndPassword().whenComplete(() {
                    if (_success != null && _success)
                      _pushReplacementPage(context, HomePage(0));
                  });
                }
              },
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _success == null
                  ? ''
                  : (_success
                      ? 'Successfully signed in ' + _userEmail
                      : errorMessage != null
                          ? 'Sign in failed: $errorMessage'
                          : 'Sign in failed'),
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Example code of how to sign in with email and password.
  Future<String> _signInWithEmailAndPassword() async {
    FirebaseUser user;
    try {
      user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ))
          .user;
    } catch (error) {
      switch (error.code) {
        case "ERROR_INVALID_EMAIL":
          errorMessage = "Your email address appears to be malformed.";
          break;
        case "ERROR_WRONG_PASSWORD":
          errorMessage = "Your password is wrong.";
          break;
        case "ERROR_USER_NOT_FOUND":
          errorMessage = "User with this email doesn't exist.";
          break;
        case "ERROR_USER_DISABLED":
          errorMessage = "User with this email has been disabled.";
          break;
        case "ERROR_TOO_MANY_REQUESTS":
          errorMessage = "Too many requests. Try again later.";
          break;
        case "ERROR_OPERATION_NOT_ALLOWED":
          errorMessage = "Signing in with Email and Password is not enabled.";
          break;
        default:
          errorMessage = "An undefined Error happened.";
      }
      print("Error Message: $errorMessage");

      setState(() {
        _success = false;

        return errorMessage != null
            ? "Sign in Failed: $errorMessage"
            : "Sign in Failed";
      });
    }

    if (user != null) {
      setState(() {
        _success = true;
        _userEmail = user.email;
        return "Sign in Succeeded for user: $user.email";
      });
    } else {
      setState(() {
        _success = false;
        return "Sign in Failed";
      });
    }

    return "Sign in Failed";
  }
}
