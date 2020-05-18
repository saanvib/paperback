import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_string/random_string.dart';

var db = Firestore.instance;

class Book {
  static addBook(String title, String author, String owner) {
    String bookId = "b_" + randomAlphaNumeric(10);
    db.collection('books').add({
      "title": title,
      "author": author,
      "owner_email": owner,
      "book_id": bookId,
      "status": "not_checked_out",
    });
  }

  static checkoutBook(String bookId) {
    db
        .collection("books")
        .where("book_id", isEqualTo: bookId)
        .getDocuments()
        .then((querySnapshot) {
      for (int i = 0; i < querySnapshot.documents.length; i++) {
        var a = querySnapshot.documents[i];
        db
            .collection('books')
            .document(a.documentID)
            .updateData({"status": "checked_out"});
      }
    });
  }

  static returnBook(String bookId) {
    db
        .collection("books")
        .where("book_id", isEqualTo: bookId)
        .getDocuments()
        .then((querySnapshot) {
      for (int i = 0; i < querySnapshot.documents.length; i++) {
        var a = querySnapshot.documents[i];
        db.collection('books').document(a.documentID).updateData(
            {"status": "not_checked_out", "checked_out_to_email": ""});
      }
    });
  }

  static deleteBook(String bookId) {
    db
        .collection("books")
        .where("book_id", isEqualTo: bookId)
        .getDocuments()
        .then((querySnapshot) {
      for (int i = 0; i < querySnapshot.documents.length; i++) {
        var a = querySnapshot.documents[i];
        db.collection('books').document(a.documentID).delete();
      }
    });
  }

  static requestCheckout(String bookId, String checkedOutToEmail) {
    db
        .collection("books")
        .where("book_id", isEqualTo: bookId)
        .getDocuments()
        .then((querySnapshot) {
      for (int i = 0; i < querySnapshot.documents.length; i++) {
        var a = querySnapshot.documents[i];
        db.collection('books').document(a.documentID).updateData({
          "status": "checkout_requested",
          "checked_out_to_email": checkedOutToEmail
        });
      }
    });
  }

  static returnRequest(String bookId) {
    db
        .collection("books")
        .where("book_id", isEqualTo: bookId)
        .getDocuments()
        .then((querySnapshot) {
      for (int i = 0; i < querySnapshot.documents.length; i++) {
        var a = querySnapshot.documents[i];
        db
            .collection('books')
            .document(a.documentID)
            .updateData({"status": "return_requested"});
      }
    });
  }
}
