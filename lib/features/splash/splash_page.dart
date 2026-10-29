import 'package:flutter/material.dart';
import 'package:prifono_caa/app/l10n/app_localizations.dart';
import 'package:prifono_caa/app/navigation.dart';
import 'package:prifono_caa/app/theme/brand_tokens.dart';
import 'package:prifono_caa/features/about/privox_mark.dart';
import 'package:prifono_caa/features/boards/presentation/boards_list_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _fullDuration = Duration(milliseconds: 2400);
  static const Duration _reducedDuration = Duration(milliseconds: 800);

  /// A marca termina de se desenhar aos 85% e fica parada até o fim, para a
  /// pessoa ver o selo completo antes de a splash sumir.
  static const Interval _markInterval = Interval(0, 0.85);
  static const Interval _textInterval =
      Interval(0.7, 1, curve: Curves.easeIn);

  late final AnimationController _controller = AnimationController(vsync: this);

  bool _started = false;
  bool _navigated = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery só pode ser lido aqui (não no initState). Rodamos uma vez.
    if (_started) return;
    _started = true;

    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller
      ..duration = _reduceMotion ? _reducedDuration : _fullDuration
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goHome();
      })
      ..forward();
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement<void, void>(
      fadeRoute<void>(const BoardsListPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goHome, // toque em qualquer lugar pula a splash
        child: Center(
          child: Semantics(
            label: l10n.appName,
            image: true,
            excludeSemantics: true,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _reduceMotion ? 1.0 : _controller.value;
                final markProgress =
                    _reduceMotion ? 1.0 : _markInterval.transform(t);
                final textOpacity =
                    _reduceMotion ? 1.0 : _textInterval.transform(t);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrivoxMark(
                      size: 160,
                      progress: markProgress,
                      pinkColor: BrandColors.rosa,
                      blueColor: BrandColors.azul,
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: textOpacity,
                      child: Text(
                        l10n.appName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
