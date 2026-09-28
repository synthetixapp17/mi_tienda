import 'package:flutter/material.dart';
import 'pro_features.dart';

class ProfesionalActivator {
  const ProfesionalActivator._();

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => ProfesionalScreen(
        modoOscuro: false,
        onAbrirSidebar: () {},
      ),
    );
  }
}
