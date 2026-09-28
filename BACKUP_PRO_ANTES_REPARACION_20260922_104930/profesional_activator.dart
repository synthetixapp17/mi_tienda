import 'package:flutter/material.dart';
import 'pro_features.dart';

class ProfesionalActivator {
  const ProfesionalActivator._();

  static Future<void> abrir(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfesionalScreen(),
      ),
    );
  }
}
