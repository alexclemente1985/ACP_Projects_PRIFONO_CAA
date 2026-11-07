import 'package:flutter/material.dart';
import 'package:prifono_caa/app/app_scope.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/theme/app_theme.dart';
import 'package:prifono_caa/features/splash/splash_page.dart';

class PrifonoApp extends StatefulWidget {
  const PrifonoApp({super.key});

  @override
  State<PrifonoApp> createState() => _PrifonoAppState();
}

class _PrifonoAppState extends State<PrifonoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A pessoa trocou o idioma do aparelho com o app aberto. Quem decide se
  /// isso importa é o [SettingsController]: só vale na escolha "Automático".
  @override
  void didChangeLocales(List<Locale>? locales) {
    final device =
        locales ?? WidgetsBinding.instance.platformDispatcher.locales;
    AppScope.of(context).settings.deviceLocalesChanged(device);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Sempre explícito: o idioma é decisão do app (ADR-034), nunca do
          // algoritmo de escolha do Flutter.
          locale: settings.effectiveLanguage.locale,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const SplashPage(),
        );
      },
    );
  }
}
