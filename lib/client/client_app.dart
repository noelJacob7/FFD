import 'package:flutter/material.dart';

class ClientApp extends StatelessWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client')),
      body:Center(
        child: Text('Welcome to the client side'),
      )
    );
  }
}
