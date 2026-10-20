import 'package:flutter/material.dart';

class DividerBlockRenderer extends StatelessWidget {
  const DividerBlockRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(thickness: 1.5),
    );
  }
}
