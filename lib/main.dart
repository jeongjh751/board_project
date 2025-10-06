import 'package:flutter/material.dart';
import 'screens/board_list_screen.dart';

void main() {
  runApp(const BoardApp());
}

class BoardApp extends StatelessWidget {
  const BoardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '게시판',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BoardListScreen(),
    );
  }
}