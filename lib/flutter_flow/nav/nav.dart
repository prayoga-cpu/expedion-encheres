import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';

import '/app_shell.dart';
import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? ChoixDevisWidget() : AccueilWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) =>
              appStateNotifier.loggedIn ? ChoixDevisWidget() : AccueilWidget(),
        ),
        FFRoute(
          name: MesDevisWidget.routeName,
          path: MesDevisWidget.routePath,
          requireAuth: true,
          builder: (context, params) => MesDevisWidget(),
        ),
        FFRoute(
          name: ConfirmerLesDetailsWidget.routeName,
          path: ConfirmerLesDetailsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => ConfirmerLesDetailsWidget(
            quoteId: params.getParam('quoteId', ParamType.String) ?? '',
          ),
        ),
        FFRoute(
          name: SuiviDeLivraisonWidget.routeName,
          path: SuiviDeLivraisonWidget.routePath,
          requireAuth: true,
          builder: (context, params) => SuiviDeLivraisonWidget(
            quoteId: params.getParam('quoteId', ParamType.String) ?? '',
          ),
        ),
        FFRoute(
          name: FormDemandeDevisWidget.routeName,
          path: FormDemandeDevisWidget.routePath,
          builder: (context, params) => FormDemandeDevisWidget(),
        ),
        FFRoute(
          name: FormDevisPaiementDirecteWidget.routeName,
          path: FormDevisPaiementDirecteWidget.routePath,
          builder: (context, params) => FormDevisPaiementDirecteWidget(),
        ),
        FFRoute(
          name: ParametreWidget.routeName,
          path: ParametreWidget.routePath,
          builder: (context, params) => ParametreWidget(),
        ),
        FFRoute(
          name: MesPaiementsWidget.routeName,
          path: MesPaiementsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => MesPaiementsWidget(),
        ),
        FFRoute(
          name: SInscrireWidget.routeName,
          path: SInscrireWidget.routePath,
          builder: (context, params) => SInscrireWidget(),
        ),
        FFRoute(
          name: SeConnecterWidget.routeName,
          path: SeConnecterWidget.routePath,
          builder: (context, params) => SeConnecterWidget(),
        ),
        FFRoute(
          name: AccueilWidget.routeName,
          path: AccueilWidget.routePath,
          // `/accueil?section=tarifs` — the marketing page's `#anchor`s, for
          // links that arrive from another page and cannot scroll in place.
          builder: (context, params) => AccueilWidget(
            section: params.getParam('section', ParamType.String),
          ),
        ),
        FFRoute(
          name: WEBFormDDpayDirectWidget.routeName,
          path: WEBFormDDpayDirectWidget.routePath,
          builder: (context, params) => WEBFormDDpayDirectWidget(),
        ),
        FFRoute(
          name: FormulaireDeDevisParBordereauWidget.routeName,
          path: FormulaireDeDevisParBordereauWidget.routePath,
          builder: (context, params) => FormulaireDeDevisParBordereauWidget(),
        ),
        FFRoute(
          name: ContactWidget.routeName,
          path: ContactWidget.routePath,
          builder: (context, params) => ContactWidget(),
        ),
        FFRoute(
          name: WEBHomepageLogedinWidget.routeName,
          path: WEBHomepageLogedinWidget.routePath,
          builder: (context, params) => WEBHomepageLogedinWidget(),
        ),
        FFRoute(
          name: EspacePersonnelWidget.routeName,
          path: EspacePersonnelWidget.routePath,
          requireAuth: true,
          builder: (context, params) => EspacePersonnelWidget(),
        ),
        FFRoute(
          name: ChoixDevisWidget.routeName,
          path: ChoixDevisWidget.routePath,
          builder: (context, params) => ChoixDevisWidget(),
        ),
        FFRoute(
          name: WEBFormDDevisWidget.routeName,
          path: WEBFormDDevisWidget.routePath,
          builder: (context, params) => WEBFormDDevisWidget(),
        ),
        FFRoute(
          name: FormulaireDemandeDeDevisRetraitAuxEncheresWidget.routeName,
          path: FormulaireDemandeDeDevisRetraitAuxEncheresWidget.routePath,
          builder: (context, params) =>
              FormulaireDemandeDeDevisRetraitAuxEncheresWidget(),
        ),
        FFRoute(
          name: PageModifInfoPersoWidget.routeName,
          path: PageModifInfoPersoWidget.routePath,
          requireAuth: true,
          builder: (context, params) => PageModifInfoPersoWidget(),
        ),
        FFRoute(
          name: FaqWidget.routeName,
          path: FaqWidget.routePath,
          builder: (context, params) => FaqWidget(),
        ),
        // The footer's Legal column. Public: a visitor has to be able to read
        // the terms before signing up to anything.
        FFRoute(
          name: CgvWidget.routeName,
          path: CgvWidget.routePath,
          builder: (context, params) => CgvWidget(),
        ),
        FFRoute(
          name: MentionsLegalesWidget.routeName,
          path: MentionsLegalesWidget.routePath,
          builder: (context, params) => MentionsLegalesWidget(),
        ),
        FFRoute(
          name: ConfidentialiteWidget.routeName,
          path: ConfidentialiteWidget.routePath,
          builder: (context, params) => ConfidentialiteWidget(),
        ),
        FFRoute(
          name: CookiesWidget.routeName,
          path: CookiesWidget.routePath,
          builder: (context, params) => CookiesWidget(),
        ),
        FFRoute(
          name: PageContactDevisWidget.routeName,
          path: PageContactDevisWidget.routePath,
          builder: (context, params) => PageContactDevisWidget(
            numDevis: params.getParam(
              'numDevis',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: PageValidationDevisWidget.routeName,
          path: PageValidationDevisWidget.routePath,
          requireAuth: true,
          builder: (context, params) => PageValidationDevisWidget(
            tarifAssADV: params.getParam(
              'tarifAssADV',
              ParamType.int,
            ),
            tarifAssSTD: params.getParam(
              'tarifAssSTD',
              ParamType.int,
            ),
            typeDevisChoisi: params.getParam(
              'typeDevisChoisi',
              ParamType.String,
            ),
            quoteID: params.getParam(
              'quoteID',
              ParamType.String,
            ),
            devisValideOuPas: params.getParam(
              'devisValideOuPas',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: PaiementWidget.routeName,
          path: PaiementWidget.routePath,
          requireAuth: true,
          // A full page, not a dialog. showDialog's overlay/barrier stack
          // behaved unreliably here in production (see the confirm-devis
          // flow that pushes this route) — a plain routed page is the
          // pattern already exercised everywhere else in this app.
          builder: (context, params) => XpdPage(
            current: XpdDestination.none,
            body: SafeArea(
              top: true,
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400.0),
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: PaiementWidget(
                        tarifADV: params.getParam('tarifADV', ParamType.int),
                        quoteID: params.getParam('quoteID', ParamType.String),
                        tarifSTD: params.getParam('tarifSTD', ParamType.int),
                        quoteNum:
                            params.getParam('quoteNum', ParamType.String),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        FFRoute(
          name: PageAdresseclientWidget.routeName,
          path: PageAdresseclientWidget.routePath,
          builder: (context, params) => PageAdresseclientWidget(),
        ),
        FFRoute(
          name: MotDePasseOublieWidget.routeName,
          path: MotDePasseOublieWidget.routePath,
          builder: (context, params) => MotDePasseOublieWidget(),
        ),
        FFRoute(
          name: DetailsDevisWidget.routeName,
          path: DetailsDevisWidget.routePath,
          requireAuth: true,
          builder: (context, params) => DetailsDevisWidget(
            prenom: params.getParam(
              'prenom',
              ParamType.String,
            ),
            nom: params.getParam(
              'nom',
              ParamType.String,
            ),
            email: params.getParam(
              'email',
              ParamType.String,
            ),
            telephone: params.getParam(
              'telephone',
              ParamType.String,
            ),
            queSouhaitezVous: params.getParam(
              'queSouhaitezVous',
              ParamType.String,
            ),
            adRetrait: params.getParam(
              'adRetrait',
              ParamType.String,
            ),
            codePostalRetrait: params.getParam(
              'codePostalRetrait',
              ParamType.String,
            ),
            villeRetrait: params.getParam(
              'villeRetrait',
              ParamType.String,
            ),
            nomHDV: params.getParam(
              'nomHDV',
              ParamType.String,
            ),
            telRetrait: params.getParam(
              'telRetrait',
              ParamType.String,
            ),
            montant: params.getParam(
              'montant',
              ParamType.int,
            ),
            tranche: params.getParam(
              'tranche',
              ParamType.String,
            ),
            dateDeVente: params.getParam(
              'dateDeVente',
              ParamType.String,
            ),
            numBordereau: params.getParam(
              'numBordereau',
              ParamType.String,
            ),
            bordereauAcquite: params.getParam(
              'bordereauAcquite',
              ParamType.String,
            ),
            descriptionObjet: params.getParam(
              'descriptionObjet',
              ParamType.String,
            ),
            longueur: params.getParam(
              'longueur',
              ParamType.String,
            ),
            largeur: params.getParam(
              'largeur',
              ParamType.String,
            ),
            hauteur: params.getParam(
              'hauteur',
              ParamType.String,
            ),
            poids: params.getParam(
              'poids',
              ParamType.String,
            ),
            objetProtege: params.getParam(
              'objetProtege',
              ParamType.String,
            ),
            adLivraison: params.getParam(
              'adLivraison',
              ParamType.String,
            ),
            codePostalLiv: params.getParam(
              'codePostalLiv',
              ParamType.String,
            ),
            villeLiv: params.getParam(
              'villeLiv',
              ParamType.String,
            ),
            paysLiv: params.getParam(
              'paysLiv',
              ParamType.String,
            ),
            telLiv: params.getParam(
              'telLiv',
              ParamType.String,
            ),
            nomDestinataire: params.getParam(
              'nomDestinataire',
              ParamType.String,
            ),
            commentaire: params.getParam(
              'commentaire',
              ParamType.String,
            ),
            conditionsGenerals: params.getParam(
              'conditionsGenerals',
              ParamType.bool,
            ),
          ),
        ),
        FFRoute(
          name: PaiementSuccessWidget.routeName,
          path: PaiementSuccessWidget.routePath,
          builder: (context, params) => PaiementSuccessWidget(
            sessionId: params.getParam(
              'session_id',
              ParamType.String,
            ),
            recordId: params.getParam(
              'recordId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: PaiementCancelWidget.routeName,
          path: PaiementCancelWidget.routePath,
          builder: (context, params) => PaiementCancelWidget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/accueil';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
