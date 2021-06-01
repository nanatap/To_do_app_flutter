import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(title: 'Todo List', home: new TodoList());
  }
}

class TodoList extends StatefulWidget {
  @override
  createState() => new TodoListState();
}

class TodoListState extends State<TodoList> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference items = FirebaseFirestore.instance.collection('todo');
  final Stream<QuerySnapshot> _todoStream =
      FirebaseFirestore.instance.collection('todo').snapshots();

  void _addTodoItem(String task) {
    if (task.length > 0) {
      items
          .add({
            'text': task,
            'time': DateTime.now(),
          })
          .then((value) => print("items Added"))
          .catchError((error) => print("Failed to add items: $error"));
    }
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Todo List')),
      body: _buildTodoList(),
      floatingActionButton: new FloatingActionButton(
          onPressed: _pushAddTodoScreen,
          tooltip: 'Add task',
          child: new Icon(Icons.add)),
    );
  }

  Widget _buildTodoList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _todoStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }

        return new ListView(
          children: snapshot.data.docs.map((DocumentSnapshot document) {
            return _buildTodoItem(
                document.data()['text'].toString(), document.id);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTodoItem(String todoText, dynamic documentid) {
    return Container(
      child: new ListTile(
          title: new Text(todoText),
          onTap: () => _promptRemoveTodoItem(documentid, todoText)),
    );
  }

  void _pushAddTodoScreen() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new Scaffold(
          appBar: new AppBar(title: new Text('Add a new task')),
          body: new TextField(
            autofocus: true,
            onSubmitted: (val) {
              _addTodoItem(val);
              Navigator.pop(context);
            },
            decoration: new InputDecoration(
                hintText: 'Enter something to do...',
                contentPadding: const EdgeInsets.all(16.0)),
          ));
    }));
  }

  void _removeTodoItem(dynamic documentid) {
    FirebaseFirestore.instance
        .collection("todo")
        .doc(documentid)
        .delete()
        .then((_) {
      print("success!");
    });
  }

  void _promptRemoveTodoItem(dynamic documentid, String text) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text('Mark "${text}" as done?'),
              actions: <Widget>[
                new FlatButton(
                    child: new Text('CANCEL'),
                    onPressed: () => Navigator.of(context).pop()),
                new FlatButton(
                    child: new Text('MARK AS DONE'),
                    onPressed: () {
                      _removeTodoItem(documentid);
                      Navigator.of(context).pop();
                    })
              ]);
        });
  }
}
