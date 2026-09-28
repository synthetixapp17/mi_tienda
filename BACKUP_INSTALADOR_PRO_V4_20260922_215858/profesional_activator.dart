import 'package:flutter/material.dart';
import 'pro_features.dart';

class ProfesionalActivator {
  const ProfesionalActivator._();

  static Future<void> abrir(
    BuildContext context, {
    required VoidCallback onAbrirSidebar,
    required bool modoOscuro,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfesionalScreen(
          onAbrirSidebar: onAbrirSidebar,
          modoOscuro: modoOscuro,
        ),
      ),
    );
  }
}
