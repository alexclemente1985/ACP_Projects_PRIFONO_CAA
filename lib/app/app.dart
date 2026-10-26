import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/features/splash/splash_page.dart';

class PrifonoApp extends StatelessWidget {
  const PrifonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const SplashPage(),
        );
      },
    );
  }
}