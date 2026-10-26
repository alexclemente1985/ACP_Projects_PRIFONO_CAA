import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/features/settings/settings_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppScope(
      settings: SettingsController(),
      child: const PrifonoApp(),
    ),
  );
}
