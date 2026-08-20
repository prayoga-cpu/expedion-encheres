import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

/// The app's language unless the visitor picks another one.
///
/// Fixed to French rather than resolved from the device: this is a French
/// product for French auction houses, and much of the copy that is not routed
/// through [kTranslationsMap] is French either way. It is also
/// `supportedLocales.first`, so it stays the fallback for any device locale the
/// app does not translate.
const Locale kDefaultLocale = Locale('fr');

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['fr', 'en', 'es', 'it'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? frText = '',
    String? enText = '',
    String? esText = '',
    String? itText = '',
  }) =>
      [frText, enText, esText, itText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // MES-DEVIS
  {
    'fncdd7uq': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    '5u1y11xk': {
      'fr': 'Aperçu de vos devis',
      'en': 'Preview of your quotes',
      'es': 'Vista previa de sus cotizaciones',
      'it': 'Anteprima dei tuoi preventivi',
    },
    'snzeghnb': {
      'fr': 'Nouveau \nbordereau',
      'en': 'New slip',
      'es': 'Nuevo resbalón',
      'it': 'Nuova\nricevuta',
    },
    'lrypswbl': {
      'fr': 'Total',
      'en': 'Total',
      'es': 'Total',
      'it': 'Totale',
    },
    '5fepikxh': {
      'fr': 'Validés',
      'en': 'Validated',
      'es': 'Validado',
      'it': 'convalidato',
    },
    '0ka76c6r': {
      'fr': 'Payés',
      'en': 'Paid',
      'es': 'Pagado',
      'it': 'Pagato',
    },
    '55zhpkpn': {
      'fr': 'Recherchez le numéro du  bordereau ..',
      'en': 'Find the receipt number...',
      'es': 'Encuentra el número de recibo...',
      'it': 'Trova il numero della ricevuta...',
    },
    '1o9dyksd': {
      'fr': 'Statut',
      'en': 'Status',
      'es': 'Estado',
      'it': 'Stato',
    },
    'ip7a4igf': {
      'fr': 'Rechercher...',
      'en': 'To research...',
      'es': 'Para investigar...',
      'it': 'Per fare ricerche...',
    },
    '9plun7m9': {
      'fr': 'Tous',
      'en': 'All',
      'es': 'Todo',
      'it': 'Tutto',
    },
    'uzopkub6': {
      'fr': 'En attente',
      'en': 'On hold',
      'es': 'En espera',
      'it': 'In attesa',
    },
    'nriuufkw': {
      'fr': 'Accepté',
      'en': 'Accepted',
      'es': 'Aceptado',
      'it': 'Accettato',
    },
    '0zxaek5q': {
      'fr': 'Refusé',
      'en': 'Denied',
      'es': 'Denegado',
      'it': 'Negato',
    },
    'fwxj134p': {
      'fr': 'Date',
      'en': 'Date',
      'es': 'Fecha',
      'it': 'Data',
    },
    'wjau7gg0': {
      'fr': 'Rechercher...',
      'en': 'To research...',
      'es': 'Para investigar...',
      'it': 'Per fare ricerche...',
    },
    'ijuwzf4d': {
      'fr': 'Plus récent',
      'en': 'More recent',
      'es': 'Más reciente',
      'it': 'Più recenti',
    },
    '91aw8lbb': {
      'fr': 'Plus ancien',
      'en': 'Older',
      'es': 'Más viejo',
      'it': 'Più vecchio',
    },
    '6c1th9zn': {
      'fr': 'Cette semaine',
      'en': 'This week',
      'es': 'Esta semana',
      'it': 'Questa settimana',
    },
    'uora5ab9': {
      'fr': 'Ce mois',
      'en': 'This month',
      'es': 'Este mes',
      'it': 'Questo mese',
    },
    'clfj04ol': {
      'fr': 'Date de Demande',
      'en': 'Date of Application',
      'es': 'Fecha de solicitud',
      'it': 'Data di applicazione',
    },
    '6p64eaoa': {
      'fr': 'Maison de Ventes',
      'en': 'Auction House',
      'es': 'Casa de subastas',
      'it': 'Casa d\'aste',
    },
    'rti2f7zc': {
      'fr': 'Ville Retrait',
      'en': 'City Retirement',
      'es': 'Jubilación en la ciudad',
      'it': 'Pensionamento in città',
    },
    'ohtw591f': {
      'fr': 'Numéro de Bordereau',
      'en': 'Slip Number',
      'es': 'Número de comprobante',
      'it': 'Numero di slittamento',
    },
    '22bnt4ae': {
      'fr': 'Ville Livraison',
      'en': 'City Delivery',
      'es': 'Entrega en la ciudad',
      'it': 'Consegna in città',
    },
    'ydenye71': {
      'fr': 'Statuts',
      'en': 'Statutes',
      'es': 'Estatutos',
      'it': 'Statuti',
    },
    'je2w5aat': {
      'fr': 'Statut Paiement',
      'en': 'Payment Status',
      'es': 'Estado del pago',
      'it': 'Stato del pagamento',
    },
    'wcp4ovg3': {
      'fr': 'Statut Retrait',
      'en': 'Withdrawal Status',
      'es': 'Estado de retiro',
      'it': 'Stato di ritiro',
    },
    'f9bbppu4': {
      'fr': 'Statut Livraison',
      'en': 'Delivery Status',
      'es': 'Estado de entrega',
      'it': 'Stato di consegna',
    },
    'q6a53wci': {
      'fr': 'ACCEPTER',
      'en': 'ACCEPT',
      'es': 'ACEPTAR',
      'it': 'ACCETTARE',
    },
    '44pw4849': {
      'fr': 'DETAILS',
      'en': 'DETAILS',
      'es': 'DETALLES',
      'it': 'DETTAGLI',
    },
    'tnnxeir6': {
      'fr': 'PAYER',
      'en': 'PAY',
      'es': 'PAGAR',
      'it': 'PAGA',
    },
    'c4jkpi4c': {
      'fr': 'CONTACT',
      'en': 'CONTACT',
      'es': 'CONTACTO',
      'it': 'CONTATTO',
    },
    'wa0ganio': {
      'fr': 'En cours de traitement',
      'en': 'Currently being processed',
      'es': 'Actualmente en proceso',
      'it': 'Attualmente in fase di elaborazione',
    },
    'n7cf4h3u': {
      'fr': 'Date de Demande',
      'en': 'Date of Application',
      'es': 'Fecha de solicitud',
      'it': 'Data di applicazione',
    },
    'j0jyy09k': {
      'fr': 'Maison de Ventes',
      'en': 'Auction House',
      'es': 'Casa de subastas',
      'it': 'Casa d\'aste',
    },
    '8u09ms0n': {
      'fr': 'Ville Retrait',
      'en': 'City Retirement',
      'es': 'Jubilación en la ciudad',
      'it': 'Pensionamento in città',
    },
    't89ujlh2': {
      'fr': 'Numéro de Bordereau',
      'en': 'Slip Number',
      'es': 'Número de comprobante',
      'it': 'Numero di slittamento',
    },
    'ke01v5n7': {
      'fr': 'Ville Livraison',
      'en': 'City Delivery',
      'es': 'Entrega en la ciudad',
      'it': 'Consegna in città',
    },
    '2znxyixj': {
      'fr': 'DETAILS',
      'en': 'DETAILS',
      'es': 'DETALLES',
      'it': 'DETTAGLI',
    },
    '70mde94h': {
      'fr': 'CONTACT',
      'en': 'CONTACT',
      'es': 'CONTACTO',
      'it': 'CONTATTO',
    },
    'vt5055c3': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    'fpvtspp0': {
      'fr': 'Accueil',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'it': 'Benvenuto',
    },
    'apal4ma2': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    '00irxg5n': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    'w073iq8f': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'ocvq8zzq': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    'zuezrt46': {
      'fr': 'FAQ - Questions',
      'en': 'FAQ - Questions',
      'es': 'Preguntas frecuentes',
      'it': 'FAQ - Domande',
    },
    'v2i0v0ek': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    '4muehx9x': {
      'fr': 'Espace Personnel',
      'en': 'Personal Space',
      'es': 'Espacio personal',
      'it': 'Spazio personale',
    },
    'r5nrtaly': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'acll70j7': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
    '8s7i40c8': {
      'fr': 'Mes demandes',
      'en': 'My requests',
      'es': 'Mis peticiones',
      'it': 'Le mie richieste',
    },
  },
  // Form_demande_devis
  {
    'xr6456gw': {
      'fr': 'Demande de devis',
      'en': 'Request for a quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    'e8h1km1j': {
      'fr': 'Sign in to your account to continue',
      'en': 'Sign in to your account to continue',
      'es': 'Inicie sesión en su cuenta para continuar',
      'it': 'Accedi al tuo account per continuare',
    },
    'gpn3jctq': {
      'fr': 'Nom :',
      'en': 'Name :',
      'es': 'Nombre :',
      'it': 'Nome :',
    },
    'e6qspesi': {
      'fr': 'Prénom :',
      'en': 'First name :',
      'es': 'Nombre de pila :',
      'it': 'Nome :',
    },
    'h8rx6dzc': {
      'fr': 'E-mail :',
      'en': 'Email:',
      'es': 'Correo electrónico:',
      'it': 'E-mail:',
    },
    '7aqolkz4': {
      'fr': 'Téléphone :',
      'en': 'Phone :',
      'es': 'Teléfono :',
      'it': 'Telefono :',
    },
    'p4nbaduh': {
      'fr': 'inserrez une piece d\'identiter',
      'en': 'Insert a piece of identification.',
      'es': 'Inserte un documento de identificación.',
      'it': 'Inserire un documento d\'identità.',
    },
    'yb8dff67': {
      'fr': 'En tant que particulier que souhaitez-vous?',
      'en': 'As an individual, what do you want?',
      'es': 'Como individuo, ¿qué deseas?',
      'it': 'Come individuo, cosa desideri?',
    },
    'gzfkdqms': {
      'fr': 'En tant que particulier que souhaitez-vous?',
      'en': 'As an individual, what do you want?',
      'es': 'Como individuo, ¿qué deseas?',
      'it': 'Come individuo, cosa desideri?',
    },
    'y3aqdifl': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'kg7cnn6d': {
      'fr': 'Autre expédition de biens - Other ',
      'en': 'Other shipment of goods - Other',
      'es': 'Otro envío de mercancías - Otros',
      'it': 'Altre spedizioni di merci - Altro',
    },
    '9nyj1yir': {
      'fr': 'Retrait enchères - Withdraw your lots in an auction house',
      'en': 'Withdraw your lots in an auction house',
      'es': 'Retira tus lotes en una casa de subastas',
      'it': 'Ritira i tuoi lotti in una casa d\'aste',
    },
    '9kn3dr05': {
      'fr':
          'Demander un devis avant achat/vente aux enchères - Ask for a quote before purchase/Auctions',
      'en': 'Request a quote before purchase/auction',
      'es': 'Solicite una cotización antes de la compra/subasta',
      'it': 'Richiedi un preventivo prima dell\'acquisto/asta',
    },
    'qafmyze8': {
      'fr': 'Souhaitez-vous une assurance ad valorem ?',
      'en': 'Do you want ad valorem insurance?',
      'es': '¿Quieres un seguro ad valorem?',
      'it': 'Vuoi un\'assicurazione ad valorem?',
    },
    'husjbsy0': {
      'fr': 'Souhaitez-vous une assurance ad valorem ?',
      'en': 'Do you want ad valorem insurance?',
      'es': '¿Quieres un seguro ad valorem?',
      'it': 'Vuoi un\'assicurazione ad valorem?',
    },
    '6x9soe4b': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'e9kzmh5c': {
      'fr': 'Oui',
      'en': 'Yes',
      'es': 'Sí',
      'it': 'SÌ',
    },
    'lauoiyac': {
      'fr': 'Non',
      'en': 'No',
      'es': 'No',
      'it': 'NO',
    },
    'bur3cag1': {
      'fr': 'Ne se prononce pas',
      'en': 'No comment',
      'es': 'Sin comentarios',
      'it': 'No comment',
    },
    '8lmynnbb': {
      'fr': 'Retrait',
      'en': 'Withdrawal',
      'es': 'Retiro',
      'it': 'Ritiro',
    },
    '8jwgvye1': {
      'fr': 'Adresse de retrait : ',
      'en': 'Collection address:',
      'es': 'Dirección de recogida:',
      'it': 'Indirizzo di ritiro:',
    },
    'tvc4wc74': {
      'fr': 'Code postal de retrait : ',
      'en': 'Pickup postal code:',
      'es': 'Código postal de recogida:',
      'it': 'Codice postale di ritiro:',
    },
    'be3tgsni': {
      'fr': 'Ville de retrait :',
      'en': 'City of withdrawal:',
      'es': 'Ciudad de retiro:',
      'it': 'Città di ritiro:',
    },
    'r23f86t3': {
      'fr': 'Nom de la maison de ventes :',
      'en': 'Name of the auction house:',
      'es': 'Nombre de la casa de subastas:',
      'it': 'Nome della casa d\'aste:',
    },
    'y7bir9i4': {
      'fr': 'Téléphone de retrait :',
      'en': 'Telephone number for withdrawal:',
      'es': 'Número de teléfono para retiro:',
      'it': 'Numero di telefono per il prelievo:',
    },
    'pnr1mzl3': {
      'fr': 'Marchandise',
      'en': 'Merchandise',
      'es': 'Mercancías',
      'it': 'Merce',
    },
    'e2an0wna': {
      'fr': 'Montant de la marchandise :',
      'en': 'Amount of merchandise:',
      'es': 'Cantidad de mercancía:',
      'it': 'Quantità di merce:',
    },
    '9btrn4g5': {
      'fr': 'Tranche tarif',
      'en': 'Price range',
      'es': 'Gama de precios',
      'it': 'Fascia di prezzo',
    },
    '2m49pdco': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'as6cje6g': {
      'fr': 'Jusqu\'à 150 €',
      'en': 'Up to €150',
      'es': 'Hasta 150€',
      'it': 'Fino a € 150',
    },
    'h1r1w6p7': {
      'fr': 'Jusqu\'à 250 €',
      'en': 'Up to €250',
      'es': 'Hasta 250€',
      'it': 'Fino a €250',
    },
    'kc3s6gzu': {
      'fr': 'Jusqu\'à 500 €',
      'en': 'Up to €500',
      'es': 'Hasta 500€',
      'it': 'Fino a € 500',
    },
    'hab4dyyx': {
      'fr': 'Jusqu\'à 1000 €',
      'en': 'Up to €1000',
      'es': 'Hasta 1000€',
      'it': 'Fino a € 1000',
    },
    '9vae0s3k': {
      'fr': 'Jusqu\'à 1500 €',
      'en': 'Up to €1500',
      'es': 'Hasta 1500€',
      'it': 'Fino a € 1500',
    },
    'p2l89mhm': {
      'fr': 'Jusqu\'à 2000 €',
      'en': 'Up to €2000',
      'es': 'Hasta 2000€',
      'it': 'Fino a € 2000',
    },
    'kst5yg3i': {
      'fr': 'Jusqu\'à 2500 €',
      'en': 'Up to €2500',
      'es': 'Hasta 2500€',
      'it': 'Fino a € 2500',
    },
    'a9ob28bu': {
      'fr': 'Jusqu\'à 3000 €',
      'en': 'Up to €3000',
      'es': 'Hasta 3000€',
      'it': 'Fino a € 3000',
    },
    'o3itfqti': {
      'fr': 'Jusqu\'à 3500 €',
      'en': 'Up to €3500',
      'es': 'Hasta 3500€',
      'it': 'Fino a € 3500',
    },
    'ihiaereo': {
      'fr': 'Jusqu\'à 4000 €',
      'en': 'Up to €4000',
      'es': 'Hasta 4000€',
      'it': 'Fino a €4000',
    },
    'ce2139x8': {
      'fr': 'Jusqu\'à 4500 €',
      'en': 'Up to €4500',
      'es': 'Hasta 4500€',
      'it': 'Fino a €4500',
    },
    'a3md1369': {
      'fr': 'Jusqu\'à 5000 €',
      'en': 'Up to €5000',
      'es': 'Hasta 5000€',
      'it': 'Fino a € 5000',
    },
    'pc62gaon': {
      'fr': 'Tranche tarif',
      'en': 'Price range',
      'es': 'Gama de precios',
      'it': 'Fascia di prezzo',
    },
    'fawk1m26': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    '0156c3pa': {
      'fr': 'Oui',
      'en': 'Yes',
      'es': 'Sí',
      'it': 'SÌ',
    },
    '94j6na4c': {
      'fr': 'Non',
      'en': 'No',
      'es': 'No',
      'it': 'NO',
    },
    'obse0dba': {
      'fr': 'inserrez votre bordereau d\'achat',
      'en': 'Insert your purchase slip',
      'es': 'Inserte su comprobante de compra',
      'it': 'Inserisci la ricevuta d\'acquisto',
    },
    'or4bdcrn': {
      'fr': 'N°Bordereau :',
      'en': 'Order No.:',
      'es': 'N.º de pedido:',
      'it': 'Numero d\'ordine:',
    },
    '686yck2z': {
      'fr': 'D\'escription de l\'objet :',
      'en': 'Description of the item:',
      'es': 'Descripción del artículo:',
      'it': 'Descrizione dell\'articolo:',
    },
    '3hx2ommc': {
      'fr': 'Longueur de l\'objet',
      'en': 'Object length',
      'es': 'Longitud del objeto',
      'it': 'Lunghezza dell\'oggetto',
    },
    'h8ue8fg7': {
      'fr': 'Largeur de l\'objet',
      'en': 'Object width',
      'es': 'Ancho del objeto',
      'it': 'Larghezza dell\'oggetto',
    },
    '53t78nxm': {
      'fr': 'Hauteur de l\'objet',
      'en': 'Object height',
      'es': 'Altura del objeto',
      'it': 'Altezza dell\'oggetto',
    },
    'ddc5woam': {
      'fr': 'Poids de l\'objet',
      'en': 'Weight of the object',
      'es': 'Peso del objeto',
      'it': 'Peso dell\'oggetto',
    },
    '7ssslv9c': {
      'fr': 'Livraison',
      'en': 'Delivery',
      'es': 'Entrega',
      'it': 'Consegna',
    },
    'l2r3xixs': {
      'fr': 'inserrez votre bordereau d\'achat',
      'en': 'Insert your purchase slip',
      'es': 'Inserte su comprobante de compra',
      'it': 'Inserisci la ricevuta d\'acquisto',
    },
    'n6r8n1mr': {
      'fr': 'Poids de l\'objet',
      'en': 'Weight of the object',
      'es': 'Peso del objeto',
      'it': 'Peso dell\'oggetto',
    },
    'g1llq9si': {
      'fr': 'Valider',
      'en': 'To validate',
      'es': 'Para validar',
      'it': 'Per convalidare',
    },
  },
  // Form_Devis_PaiementDirecte
  {
    '0qmoygh5': {
      'fr': 'Demande de devis',
      'en': 'Request for a quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    '2d7wwk5r': {
      'fr': 'Sign in to your account to continue',
      'en': 'Sign in to your account to continue',
      'es': 'Inicie sesión en su cuenta para continuar',
      'it': 'Accedi al tuo account per continuare',
    },
    'oaz61550': {
      'fr': 'Selectionez une destinaton d\'expedition',
      'en': 'Select a shipping destination',
      'es': 'Seleccione un destino de envío',
      'it': 'Seleziona una destinazione di spedizione',
    },
    '9zq8fkws': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'zsnoc0ar': {
      'fr': 'France',
      'en': 'France',
      'es': 'Francia',
      'it': 'Francia',
    },
    'yf7iyx14': {
      'fr': 'Europe',
      'en': 'Europe',
      'es': 'Europa',
      'it': 'Europa',
    },
    'osdxnvzz': {
      'fr': 'Monde',
      'en': 'World',
      'es': 'Mundo',
      'it': 'Mondo',
    },
    'sli6nxqr': {
      'fr': 'Poids',
      'en': 'Weight',
      'es': 'Peso',
      'it': 'Peso',
    },
    'ibxywxn1': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'n1z2mr2x': {
      'fr': '1 Kg',
      'en': '1 kg',
      'es': '1 kilogramo',
      'it': '1 chilogrammo',
    },
    'qh7r375t': {
      'fr': '2 Kg',
      'en': '2 kg',
      'es': '2 kilos',
      'it': '2 kg',
    },
    '4xu01r98': {
      'fr': '5 Kg',
      'en': '5 kg',
      'es': '5 kilos',
      'it': '5 kg',
    },
    'wlu1zb0l': {
      'fr': '10 Kg',
      'en': '10 kg',
      'es': '10 kilos',
      'it': '10 chili',
    },
    '0w582g5w': {
      'fr': '20 Kg',
      'en': '20 kg',
      'es': '20 kilos',
      'it': '20 chili',
    },
    'zjsexx3l': {
      'fr': 'Taille',
      'en': 'Size',
      'es': 'Tamaño',
      'it': 'Misurare',
    },
    'mbi5gz6t': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    '8u3ze3rr': {
      'fr': 'XS  enveloppe 30x20x3 (53cm)',
      'en': 'XS envelope 30x20x3 (53cm)',
      'es': 'Sobre XS 30x20x3 (53cm)',
      'it': 'Busta XS 30x20x3 (53 cm)',
    },
    'i2pfkg9l': {
      'fr': 'S  boite chaussures 30x20x15 (65cm)',
      'en': 'S shoe box 30x20x15 (65cm)',
      'es': 'Caja de zapatos S 30x20x15 (65cm)',
      'it': 'Scatola da scarpe S 30x20x15 (65cm)',
    },
    '9xu3sj9t': {
      'fr': 'M  30X30X30 (90cm)',
      'en': 'M 30X30X30 (90cm)',
      'es': 'M 30X30X30 (90cm)',
      'it': 'M 30X30X30 (90cm)',
    },
    'cq714v61': {
      'fr': 'L  50X50X50 (150cm)',
      'en': 'L 50X50X50 (150cm)',
      'es': 'Largo 50X50X50 (150cm)',
      'it': 'L 50X50X50 (150cm)',
    },
    'mxozz90x': {
      'fr': 'XL  80X60X60 (200cm)',
      'en': 'XL 80X60X60 (200cm)',
      'es': 'XL 80X60X60 (200cm)',
      'it': 'XL 80X60X60 (200cm)',
    },
    'nj9lm693': {
      'fr': 'TARIF :  ',
      'en': 'PRICE:',
      'es': 'PRECIO:',
      'it': 'PREZZO:',
    },
    'rt60u0lr': {
      'fr': 'Coordonnées Destinataire',
      'en': 'Recipient\'s contact information',
      'es': 'Información de contacto del destinatario',
      'it': 'Informazioni di contatto del destinatario',
    },
    '922q62z3': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'r1fcmnj3': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    'j99ipg82': {
      'fr': 'E-mail',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    'k0ic8mgr': {
      'fr': 'Téléphone',
      'en': 'Phone',
      'es': 'Teléfono',
      'it': 'Telefono',
    },
    'elp4n5f8': {
      'fr': 'Nature des objets',
      'en': 'Nature of objects',
      'es': 'Naturaleza de los objetos',
      'it': 'Natura degli oggetti',
    },
    'wwjetaf0': {
      'fr': 'Description de l\'objet :',
      'en': 'Item description:',
      'es': 'Descripción del artículo:',
      'it': 'Descrizione dell\'articolo:',
    },
    'cp5zoqeb': {
      'fr': 'inserrez votre bordereau d\'achat',
      'en': 'Insert your purchase slip',
      'es': 'Inserte su comprobante de compra',
      'it': 'Inserisci la ricevuta d\'acquisto',
    },
    'jisbk83k': {
      'fr': 'N° de bbordereau:',
      'en': 'Order form number:',
      'es': 'Número de formulario de pedido:',
      'it': 'Numero del modulo d\'ordine:',
    },
    'zgtz6dda': {
      'fr': 'Lieu de retrait',
      'en': 'Pick-up location',
      'es': 'Lugar de recogida',
      'it': 'Luogo di ritiro',
    },
    '6ux9m3bt': {
      'fr': 'Nom de la maison de ventes ',
      'en': 'Name of the auction house',
      'es': 'Nombre de la casa de subastas',
      'it': 'Nome della casa d\'aste',
    },
    '20d3c9wi': {
      'fr': 'Adresse de retrait ',
      'en': 'Collection address',
      'es': 'Dirección de recogida',
      'it': 'Indirizzo di ritiro',
    },
    '2gq1ql7m': {
      'fr': 'Code postal retrait',
      'en': 'Postal code for withdrawal',
      'es': 'Código postal para retiro',
      'it': 'Codice postale per il prelievo',
    },
    '5najy4jb': {
      'fr': 'Ville de retrait',
      'en': 'City of withdrawal',
      'es': 'Ciudad de retirada',
      'it': 'Città di ritiro',
    },
    'sek3qhk3': {
      'fr': 'Lieu de livraison',
      'en': 'Delivery location',
      'es': 'Lugar de entrega',
      'it': 'Luogo di consegna',
    },
    'wxntx8w8': {
      'fr': 'Adresse de livraison L1',
      'en': 'Delivery address L1',
      'es': 'Dirección de entrega L1',
      'it': 'Indirizzo di consegna L1',
    },
    'n49zzd82': {
      'fr': 'Adresse de livraison L2',
      'en': 'Delivery address L2',
      'es': 'Dirección de entrega L2',
      'it': 'Indirizzo di consegna L2',
    },
    '4ae45mm8': {
      'fr': 'Code postal',
      'en': 'Postal code',
      'es': 'Código Postal',
      'it': 'Codice Postale',
    },
    'h30ps8wc': {
      'fr': 'Ville de livraison',
      'en': 'City of delivery',
      'es': 'Ciudad de entrega',
      'it': 'Città di consegna',
    },
    'g51t1cnz': {
      'fr': 'Pays de livraison',
      'en': 'Country of delivery',
      'es': 'País de entrega',
      'it': 'Paese di consegna',
    },
    'rjp7ylyt': {
      'fr': 'Téléphone livraison',
      'en': 'Telephone delivery',
      'es': 'Entrega telefónica',
      'it': 'Consegna telefonica',
    },
    '90blh973': {
      'fr': 'D\'escription de l\'objet',
      'en': 'Description of the object',
      'es': 'Descripción del objeto',
      'it': 'Descrizione dell\'oggetto',
    },
    'rgailnr0': {
      'fr': 'Valider',
      'en': 'To validate',
      'es': 'Para validar',
      'it': 'Per convalidare',
    },
  },
  // parametre
  {
    'p3llsagy': {
      'fr': 'Profile Settings',
      'en': 'Profile Settings',
      'es': 'Configuración del perfil',
      'it': 'Impostazioni del profilo',
    },
    'xuzmw6es': {
      'fr': 'Infomations personnelles',
      'en': 'Personal information',
      'es': 'Información personal',
      'it': 'Informazioni personali',
    },
    '0spiwn9c': {
      'fr': 'Update your personal information',
      'en': 'Update your personal information',
      'es': 'Actualice su información personal',
      'it': 'Aggiorna le tue informazioni personali',
    },
    'o69ba1dd': {
      'fr': 'Mes fichiers',
      'en': 'My files',
      'es': 'Mis archivos',
      'it': 'I miei file',
    },
    '6yqjh6ut': {
      'fr': 'Manage your business information',
      'en': 'Manage your business information',
      'es': 'Administre la información de su negocio',
      'it': 'Gestisci le informazioni della tua attività',
    },
    'jfpgn54j': {
      'fr': 'Mes addresses',
      'en': 'My addresses',
      'es': 'Mis direcciones',
      'it': 'I miei indirizzi',
    },
    'v0ul109a': {
      'fr': 'Update your billing address',
      'en': 'Update your billing address',
      'es': 'Actualice su dirección de facturación',
      'it': 'Aggiorna il tuo indirizzo di fatturazione',
    },
    'l4fj1dn9': {
      'fr': 'Mes bordereaux',
      'en': 'My slips',
      'es': 'Mis deslices',
      'it': 'I miei scivoloni',
    },
    'w5vjr8kk': {
      'fr': 'Update your billing address',
      'en': 'Update your billing address',
      'es': 'Actualice su dirección de facturación',
      'it': 'Aggiorna il tuo indirizzo di fatturazione',
    },
    '2ivra48z': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'es': 'Contraseña',
      'it': 'Password',
    },
    'x0gm6frr': {
      'fr': 'Update your billing address',
      'en': 'Update your billing address',
      'es': 'Actualice su dirección de facturación',
      'it': 'Aggiorna il tuo indirizzo di fatturazione',
    },
    '3hed0y9v': {
      'fr': 'App Preferences',
      'en': 'App Preferences',
      'es': 'Preferencias de la aplicación',
      'it': 'Preferenze dell\'app',
    },
    '3870t10p': {
      'fr': 'Notifications',
      'en': 'Notifications',
      'es': 'Notificaciones',
      'it': 'Notifiche',
    },
    'wurvrnya': {
      'fr': 'Quote updates and reminders',
      'en': 'Quote updates and reminders',
      'es': 'Actualizaciones de cotizaciones y recordatorios',
      'it': 'Aggiornamenti e promemoria delle quotazioni',
    },
    'fhs8b105': {
      'fr': 'Email Notifications',
      'en': 'Email Notifications',
      'es': 'Notificaciones por correo electrónico',
      'it': 'Notifiche e-mail',
    },
    'a66hvz3i': {
      'fr': 'Receive quotes via email',
      'en': 'Receive quotes via email',
      'es': 'Recibir cotizaciones por correo electrónico',
      'it': 'Ricevi preventivi via email',
    },
    'wj86ewyo': {
      'fr': 'Language',
      'en': 'Language',
      'es': 'Idioma',
      'it': 'Lingua',
    },
    'd7yh5lh1': {
      'fr': 'English (US)',
      'en': 'English (US)',
      'es': 'Inglés (EE. UU.)',
      'it': 'Inglese (Stati Uniti)',
    },
    'tmtmqw13': {
      'fr': 'Support & Legal',
      'en': 'Support & Legal',
      'es': 'Soporte y legal',
      'it': 'Supporto e legale',
    },
    '4rsdcac3': {
      'fr': 'Help & Support',
      'en': 'Help & Support',
      'es': 'Ayuda y soporte',
      'it': 'Aiuto e supporto',
    },
    'rsijo3jc': {
      'fr': 'Privacy Policy',
      'en': 'Privacy Policy',
      'es': 'política de privacidad',
      'it': 'politica sulla riservatezza',
    },
    '34fxsex9': {
      'fr': 'Terms of Service',
      'en': 'Terms of Service',
      'es': 'Condiciones de servicio',
      'it': 'Termini di servizio',
    },
    'le79ahjy': {
      'fr': 'Sign Out',
      'en': 'Sign Out',
      'es': 'Desconectar',
      'it': 'Disconnessione',
    },
    '70rp5ld8': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    'g4q998eg': {
      'fr': 'Home',
      'en': 'Home',
      'es': 'Hogar',
      'it': 'Casa',
    },
    'vmrhk91q': {
      'fr': 'Demande de devis',
      'en': 'Request for a quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    'r9bipnsv': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'dwdoba78': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'h04ahmyo': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    '0nwfc6uz': {
      'fr': 'Mon suivi',
      'en': 'My tracking',
      'es': 'Mi seguimiento',
      'it': 'Il mio monitoraggio',
    },
    '1s5pc3y5': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    'k2ox940y': {
      'fr': 'Mon profile',
      'en': 'My profile',
      'es': 'Mi perfil',
      'it': 'Il mio profilo',
    },
    'x6ctorvs': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'hv1k4bt3': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
  },
  // MesPaiements
  {
    'ivk0wt6f': {
      'fr': 'Total Payments This Month',
      'en': 'Total Payments This Month',
      'es': 'Pagos totales de este mes',
      'it': 'Totale pagamenti questo mese',
    },
    'kk2xxroe': {
      'fr': '\$2,847.50',
      'en': '\$2,847.50',
      'es': '\$2,847.50',
      'it': '\$2.847,50',
    },
    'wqbbgvs1': {
      'fr': '12 transactions',
      'en': '12 transactions',
      'es': '12 transacciones',
      'it': '12 transazioni',
    },
    'v78uszn5': {
      'fr': '+15.2%',
      'en': '+15.2%',
      'es': '+15,2%',
      'it': '+15,2%',
    },
    'mb06i9wf': {
      'fr': 'Recent Payments',
      'en': 'Recent Payments',
      'es': 'Pagos recientes',
      'it': 'Pagamenti recenti',
    },
    'fpq6n9bw': {
      'fr': 'View All',
      'en': 'View All',
      'es': 'Ver todo',
      'it': 'Visualizza tutto',
    },
    'bwjot7ml': {
      'fr': 'Creative Agency',
      'en': 'Creative Agency',
      'es': 'Agencia creativa',
      'it': 'Agenzia creativa',
    },
    'f6kv0siw': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    '7xu09z6t': {
      'fr': 'Home',
      'en': 'Home',
      'es': 'Hogar',
      'it': 'Casa',
    },
    'njbbfkmh': {
      'fr': 'Demande de devis',
      'en': 'Request for a quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    'oeqliatt': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'cpsps5yg': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'yc2m3070': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    'wj01zz0f': {
      'fr': 'Mon suivi',
      'en': 'My tracking',
      'es': 'Mi seguimiento',
      'it': 'Il mio monitoraggio',
    },
    'r2m6csbi': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    '5rovzrsa': {
      'fr': 'Mon profile',
      'en': 'My profile',
      'es': 'Mi perfil',
      'it': 'Il mio profilo',
    },
    'w4d01akr': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    '29ezk2wk': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
  },
  // S-INSCRIRE
  {
    'h2x7sreb': {
      'fr': 'Créer un compte',
      'en': 'Create an account',
      'es': 'Crear una cuenta',
      'it': 'Creare un account',
    },
    'lzs8fxi9': {
      'fr':
          'Rejoignez de nombreux utilisateurs et commencez votre aventure dès aujourd\'hui !',
      'en': 'Join many other users and start your adventure today!',
      'es': '¡Únete a muchos otros usuarios y comienza tu aventura hoy!',
      'it':
          'Unisciti a molti altri utenti e inizia la tua avventura oggi stesso!',
    },
    'k4zv53eg': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'dojes7jj': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'yreodfod': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    '592os5af': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    '4y9i2dxu': {
      'fr': 'Email Address',
      'en': 'Email Address',
      'es': 'Dirección de correo electrónico',
      'it': 'Indirizzo e-mail',
    },
    '6iezf6h9': {
      'fr': 'Email Address',
      'en': 'Email Address',
      'es': 'Dirección de correo electrónico',
      'it': 'Indirizzo e-mail',
    },
    'vh2q8zya': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'es': 'Contraseña',
      'it': 'Password',
    },
    'nljo66ib': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'es': 'Contraseña',
      'it': 'Password',
    },
    'ouxyr1va': {
      'fr': 'Confirmationmot depasse',
      'en': 'Confirm password',
      'es': 'Confirmar Contraseña',
      'it': 'Conferma password',
    },
    'nes2zms3': {
      'fr': 'Confirmationmot depasse',
      'en': 'Confirm password',
      'es': 'Confirmar Contraseña',
      'it': 'Conferma password',
    },
    'qnkb1cdz': {
      'fr': 'Adresse client',
      'en': 'Customer address',
      'es': 'Dirección del cliente',
      'it': 'Indirizzo del cliente',
    },
    'b4401tpy': {
      'fr': 'Adresse  L1 *',
      'en': 'Address L1 *',
      'es': 'Dirección L1 *',
      'it': 'Indirizzo L1 *',
    },
    'bqhe2bhn': {
      'fr': 'Adresse  L1 *',
      'en': 'Address L1 *',
      'es': 'Dirección L1 *',
      'it': 'Indirizzo L1 *',
    },
    'fhcjg21y': {
      'fr': 'Adresse L2',
      'en': 'Address L2',
      'es': 'Dirección L2',
      'it': 'Indirizzo L2',
    },
    'w165r893': {
      'fr': 'Adresse L2',
      'en': 'Address L2',
      'es': 'Dirección L2',
      'it': 'Indirizzo L2',
    },
    '2mg5bz76': {
      'fr': 'Code postal*',
      'en': 'Postal code*',
      'es': 'Código Postal*',
      'it': 'Codice Postale*',
    },
    'mvw6di69': {
      'fr': 'Code postal*',
      'en': 'Postal code*',
      'es': 'Código Postal*',
      'it': 'Codice Postale*',
    },
    '5828ki5q': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    'p4wwj9mk': {
      'fr': 'Ville*',
      'en': 'City*',
      'es': 'Ciudad*',
      'it': 'Città*',
    },
    'c3vs4bgn': {
      'fr': 'Pays*',
      'en': 'Country*',
      'es': 'País*',
      'it': 'Paese*',
    },
    'brlme96d': {
      'fr': 'Pays*',
      'en': 'Country*',
      'es': 'País*',
      'it': 'Paese*',
    },
    '6bv7dy2l': {
      'fr': 'Téléphone*',
      'en': 'Phone*',
      'es': 'Teléfono*',
      'it': 'Telefono*',
    },
    'y63vkwsh': {
      'fr': 'Téléphone*',
      'en': 'Phone*',
      'es': 'Teléfono*',
      'it': 'Telefono*',
    },
    'g9qgmqw8': {
      'fr': 'utiliser la même adresse \npour la livraison.',
      'en': 'use the same address for delivery.',
      'es': 'Utilice la misma dirección para la entrega.',
      'it': 'utilizzare lo stesso indirizzo per la consegna.',
    },
    'heiemxwi': {
      'fr': 'Adresse de livraison',
      'en': 'Delivery address',
      'es': 'Dirección de entrega',
      'it': 'Indirizzo di consegna',
    },
    'aow6cbql': {
      'fr': 'Adresse livraison L1 *',
      'en': 'Delivery address L1 *',
      'es': 'Dirección de entrega L1 *',
      'it': 'Indirizzo di consegna L1 *',
    },
    'ak56btva': {
      'fr': 'Adresse livraison L1 *',
      'en': 'Delivery address L1 *',
      'es': 'Dirección de entrega L1 *',
      'it': 'Indirizzo di consegna L1 *',
    },
    'pnytn8qx': {
      'fr': 'Adresse livraison L2',
      'en': 'Delivery address L2',
      'es': 'Dirección de entrega L2',
      'it': 'Indirizzo di consegna L2',
    },
    'u2ruemf0': {
      'fr': 'Adresse livraison L2',
      'en': 'Delivery address L2',
      'es': 'Dirección de entrega L2',
      'it': 'Indirizzo di consegna L2',
    },
    '4ua9wanj': {
      'fr': 'Code postal*',
      'en': 'Postal code*',
      'es': 'Código Postal*',
      'it': 'Codice Postale*',
    },
    'ynn6pbaf': {
      'fr': 'Code postal livraison*',
      'en': 'Delivery postal code*',
      'es': 'Código postal de entrega*',
      'it': 'Codice postale di consegna*',
    },
    'zr2nzbc2': {
      'fr': 'Ville*',
      'en': 'City*',
      'es': 'Ciudad*',
      'it': 'Città*',
    },
    'x8o72red': {
      'fr': 'Ville livraison*',
      'en': 'Delivery city*',
      'es': 'Ciudad de entrega*',
      'it': 'Città di consegna*',
    },
    'mv6xevdf': {
      'fr': 'Pays livraison*',
      'en': 'Delivery country*',
      'es': 'País de entrega*',
      'it': 'Paese di consegna*',
    },
    'j7o7bp8j': {
      'fr': 'Pays livraison*',
      'en': 'Delivery country*',
      'es': 'País de entrega*',
      'it': 'Paese di consegna*',
    },
    's7cip6qm': {
      'fr': 'Téléphone livraison*',
      'en': 'Telephone delivery*',
      'es': 'Entrega telefónica*',
      'it': 'Consegna telefonica*',
    },
    'ilxe2bdy': {
      'fr': 'Téléphone livraison*',
      'en': 'Telephone delivery*',
      'es': 'Entrega telefónica*',
      'it': 'Consegna telefonica*',
    },
    'gzx29mfb': {
      'fr': 'J’accepte les conditions générales\n.',
      'en': 'I accept the terms and conditions.\n\n',
      'es': 'Acepto los términos y condiciones.\n\n',
      'it': 'Accetto i termini e le condizioni.\n\n',
    },
    'x1hq9hk2': {
      'fr': 'J’accepte la politique de confidentialité.',
      'en': 'I accept the privacy policy.',
      'es': 'Acepto la política de privacidad.',
      'it': 'Accetto l\'informativa sulla privacy.',
    },
    'aeolwjzo': {
      'fr': 'Créer un compte',
      'en': 'Create an account',
      'es': 'Crear una cuenta',
      'it': 'Creare un account',
    },
    'kkh64ryl': {
      'fr': 'Vous avez déjà un compte ?',
      'en': 'Do you already have an account?',
      'es': '¿Ya tienes una cuenta?',
      'it': 'Hai già un account?',
    },
    'ypg51qkt': {
      'fr': 'Se connecter',
      'en': 'Log in',
      'es': 'Acceso',
      'it': 'Login',
    },
    'tgmq3fiw': {
      'fr': 'Créer un compte',
      'en': 'Create an account',
      'es': 'Crear una cuenta',
      'it': 'Creare un account',
    },
  },
  // SE-CONNECTER
  {
    'asyfmddz': {
      'fr': 'Content de vous revoir',
      'en': 'Glad to see you again',
      'es': 'Me alegro de verte de nuevo',
      'it': 'Sono felice di rivederti',
    },
    'geumol3r': {
      'fr':
          'Connectez-vous à votre compte pour effectuer et suivre vos demandes',
      'en': 'Log in to your account to submit and track your requests',
      'es':
          'Inicie sesión en su cuenta para enviar y realizar un seguimiento de sus solicitudes.',
      'it': 'Accedi al tuo account per inviare e monitorare le tue richieste',
    },
    'y6pocxj7': {
      'fr': 'Vous n\'avez pas de compte ?',
      'en': 'You don\'t have an account?',
      'es': '¿No tienes una cuenta?',
      'it': 'Non hai un account?',
    },
    'k0ml94mu': {
      'fr': 'S\'inscrire',
      'en': 'Register',
      'es': 'Registro',
      'it': 'Registro',
    },
    'tnfmnwhr': {
      'fr': 'Email',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    'x4f9uar0': {
      'fr': 'Entrez votre  email',
      'en': 'Enter your email',
      'es': 'Introduce tu correo electrónico',
      'it': 'Inserisci la tua email',
    },
    '5w88z7md': {
      'fr': 'Mot de passe',
      'en': 'Password',
      'es': 'Contraseña',
      'it': 'Password',
    },
    'jvpirn4r': {
      'fr': 'Entrez votre mot de passe',
      'en': 'Enter your password',
      'es': 'Ingrese su contraseña',
      'it': 'Inserisci la tua password',
    },
    'gxpzgcjo': {
      'fr': 'Mot de passe oublié ?',
      'en': 'Forgot your password?',
      'es': '¿Olvidaste tu contraseña?',
      'it': 'Hai dimenticato la password?',
    },
    'smm0rtuw': {
      'fr': 'Se connecter',
      'en': 'Log in',
      'es': 'Acceso',
      'it': 'Login',
    },
    'h5oc8wgs': {
      'fr': 'Se connecter',
      'en': 'Log in',
      'es': 'Acceso',
      'it': 'Login',
    },
  },
  // ACCUEIL
  {
    'ink9zdky': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    'x7iapl7r': {
      'fr': 'Accueil',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'it': 'Benvenuto',
    },
    'bu5e8zza': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    'nwkmvoz5': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    '4ng1s0aq': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'r553ecpv': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    'upxosv25': {
      'fr': 'FAQ - Questions',
      'en': 'FAQ - Questions',
      'es': 'Preguntas frecuentes',
      'it': 'FAQ - Domande',
    },
    'p4di10cd': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'j462679b': {
      'fr': 'Espace Personnel',
      'en': 'Personal Space',
      'es': 'Espacio personal',
      'it': 'Spazio personale',
    },
    '3s7qxejr': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'ab0zcet6': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
    'l45r0pzx': {
      'fr': 'Binvenue sur EXPEDION ENCHERES',
      'en': 'Welcome to EXPEDION AUCTIONS',
      'es': 'Bienvenido a SUBASTAS EXPEDION',
      'it': 'Benvenuti a EXPEDION AUCTIONS',
    },
    'lgwa9txb': {
      'fr': 'DEVIS RAPIDE ET AU MEILLEUR PRIX DE VOS EXPEDITIONS',
      'en': 'GET A FAST QUOTE AT THE BEST PRICE FOR YOUR SHIPMENTS',
      'es': 'OBTENGA UNA COTIZACIÓN RÁPIDA AL MEJOR PRECIO PARA SUS ENVÍOS',
      'it':
          'OTTIENI UN PREVENTIVO VELOCE AL MIGLIOR PREZZO PER LE TUE SPEDIZIONI',
    },
    'brnwrg83': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    'd1srw42p': {
      'fr': 'Présentation de nos services et nos avantages  ',
      'en': 'Presentation of our services and our advantages',
      'es': 'Presentación de nuestros servicios y nuestras ventajas',
      'it': 'Presentazione dei nostri servizi e dei nostri vantaggi',
    },
    'siik3vgm': {
      'fr':
          'Une offre pour particuliers, professionnels de l\'art, commissaires-priseur et de justice.',
      'en':
          'An offer for individuals, art professionals, auctioneers and the judiciary.',
      'es':
          'Una oferta para particulares, profesionales del arte, subastadores y poder judicial.',
      'it':
          'Un\'offerta rivolta a privati, professionisti dell\'arte, banditori d\'asta e magistratura.',
    },
    'pglsehsn': {
      'fr': 'Particulier',
      'en': 'Particular',
      'es': 'Particular',
      'it': 'Particolare',
    },
    'c9pi57ow': {
      'fr':
          'Vous bénéficiez de tarifs abordables grâce à notre outil de recueil de demandes de devis.\nNous avons de ce fait la possibilité d’apprécier au mieux votre demande dans des délais rapides.',
      'en':
          'You benefit from affordable rates thanks to our quote request tool.\n\nThis allows us to best assess your request quickly.',
      'es':
          'Benefíciate de tarifas asequibles gracias a nuestra herramienta de solicitud de presupuesto.\n\nEsto nos permite evaluar tu solicitud con rapidez y eficacia.',
      'it':
          'Grazie al nostro strumento di richiesta preventivo, potrai beneficiare di tariffe convenienti.\n\nQuesto ci consente di valutare al meglio la tua richiesta in tempi rapidi.',
    },
    'm9pq232j': {
      'fr': 'Professionnel de l\'art',
      'en': 'Art professional',
      'es': 'Profesional del arte',
      'it': 'Professionista dell\'arte',
    },
    '95dtmo6u': {
      'fr':
          'En tant que professionnel du monde de l\'art,vous êtes à la recherche de solutions de transport adaptées à votre besoin\net au meilleur prix pour répondre aux exigences de votre clientèle',
      'en':
          'As an art professional, you are looking for transport solutions tailored to your needs\nand at the best price to meet your clients\' requirements',
      'es':
          'Como profesional del arte, busca soluciones de transporte adaptadas a sus necesidades y al mejor precio para satisfacer las necesidades de sus clientes.',
      'it':
          'Come professionista dell\'arte, stai cercando soluzioni di trasporto su misura per le tue esigenze\ne al miglior prezzo per soddisfare le richieste dei tuoi clienti.',
    },
    '9l0celf6': {
      'fr': 'Hotel des ventes',
      'en': 'Auction House',
      'es': 'Casa de subastas',
      'it': 'Casa d\'aste',
    },
    '1pilww92': {
      'fr':
          'Vous êtes une maison de ventes aux encheres et vous recherchez des prestataires pour effectuer tout type de transport pour vous-même ou votre clientèle.\nVous recherchez une solution logistique adaptée à votre entreprise.',
      'en':
          'You are an auction house and you are looking for service providers to handle all types of transportation for yourself or your clients.\n\nYou are looking for a logistics solution tailored to your business.',
      'es':
          'Eres una casa de subastas y buscas proveedores de servicios que se encarguen de todo tipo de transporte para ti o tus clientes.\n\nBuscas una solución logística adaptada a tu negocio.',
      'it':
          'Sei una casa d\'aste e stai cercando fornitori di servizi che gestiscano tutti i tipi di trasporto per te o per i tuoi clienti.\n\nCerchi una soluzione logistica su misura per la tua attività.',
    },
    'y831pdug': {
      'fr': 'Particulier',
      'en': 'Particular',
      'es': 'Particular',
      'it': 'Particolare',
    },
    'qmxv04kq': {
      'fr':
          'Vous bénéficiez de tarifs abordables grâce à notre outil de recueil de demandes de devis.\nNous avons de ce fait la possibilité d’apprécier au mieux votre demande dans des délais rapides.',
      'en':
          'You benefit from affordable rates thanks to our quote request tool.\n\nThis allows us to best assess your request quickly.',
      'es':
          'Benefíciate de tarifas asequibles gracias a nuestra herramienta de solicitud de presupuesto.\n\nEsto nos permite evaluar tu solicitud con rapidez y eficacia.',
      'it':
          'Grazie al nostro strumento di richiesta preventivo, potrai beneficiare di tariffe convenienti.\n\nQuesto ci consente di valutare al meglio la tua richiesta in tempi rapidi.',
    },
    'jfx5p3sk': {
      'fr': 'Hotel des ventes',
      'en': 'Auction House',
      'es': 'Casa de subastas',
      'it': 'Casa d\'aste',
    },
    '8s3z56pb': {
      'fr':
          'Vous êtes une maison de ventes aux encheres et vous recherchez des prestataires pour effectuer tout type de transport pour vous-même ou votre clientèle.\nVous recherchez une solution logistique adaptée à votre entreprise.',
      'en':
          'You are an auction house and you are looking for service providers to handle all types of transportation for yourself or your clients.\n\nYou are looking for a logistics solution tailored to your business.',
      'es':
          'Eres una casa de subastas y buscas proveedores de servicios que se encarguen de todo tipo de transporte para ti o tus clientes.\n\nBuscas una solución logística adaptada a tu negocio.',
      'it':
          'Sei una casa d\'aste e stai cercando fornitori di servizi che gestiscano tutti i tipi di trasporto per te o per i tuoi clienti.\n\nCerchi una soluzione logistica su misura per la tua attività.',
    },
    'xj2ficwc': {
      'fr': 'Professionnel de l\'art',
      'en': 'Art professional',
      'es': 'Profesional del arte',
      'it': 'Professionista dell\'arte',
    },
    '0o9ergyf': {
      'fr':
          'En tant que professionnel du monde de l\'art,vous êtes à la recherche de solutions de transport adaptées à votre besoin\net au meilleur prix pour répondre aux exigences de votre clientèle',
      'en':
          'As an art professional, you are looking for transport solutions tailored to your needs\nand at the best price to meet your clients\' requirements',
      'es':
          'Como profesional del arte, busca soluciones de transporte adaptadas a sus necesidades y al mejor precio para satisfacer las necesidades de sus clientes.',
      'it':
          'Come professionista dell\'arte, stai cercando soluzioni di trasporto su misura per le tue esigenze\ne al miglior prezzo per soddisfare le richieste dei tuoi clienti.',
    },
    '9dqs3yi1': {
      'fr': 'Prêt à \ncommencer ?',
      'en': 'Ready to begin?',
      'es': '¿Listo para comenzar?',
      'it': 'Pronti per iniziare?',
    },
    'u735qm4k': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    '66mh35x3': {
      'fr': 'Contactez Nous',
      'en': 'Contact Us',
      'es': 'Contáctenos',
      'it': 'Contattaci',
    },
    'bnyn0bdn': {
      'fr': 'FAQ',
      'en': 'FAQ',
      'es': 'Preguntas frecuentes',
      'it': 'Domande frequenti',
    },
  },
  // WEB_formDDpayDirect
  {
    'cw3nttco': {
      'fr': 'Paiement de tansport',
      'en': 'Transport payment',
      'es': 'Pago de transporte',
      'it': 'Pagamento del trasporto',
    },
    'eoxq9qfj': {
      'fr':
          'Remplissez le formulaire ci-dessous pour estimer le prix de votre commande et procédez au paiement.',
      'en':
          'Fill out the form below to estimate the price of your order and proceed to payment.',
      'es':
          'Llene el siguiente formulario para estimar el precio de su pedido y proceder al pago.',
      'it':
          'Compila il modulo sottostante per stimare il prezzo del tuo ordine e procedere al pagamento.',
    },
    'e6j42n9g': {
      'fr': 'Destination *',
      'en': 'Destination *',
      'es': 'Destino *',
      'it': 'Destinazione *',
    },
    'p5ck42nc': {
      'fr': 'Selectionez la destination',
      'en': 'Select the destination',
      'es': 'Seleccione el destino',
      'it': 'Seleziona la destinazione',
    },
    '3cttaq4k': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'iyw9rp11': {
      'fr': 'France',
      'en': 'France',
      'es': 'Francia',
      'it': 'Francia',
    },
    'usct3iph': {
      'fr': 'Europe',
      'en': 'Europe',
      'es': 'Europa',
      'it': 'Europa',
    },
    'g8afwl85': {
      'fr': 'Monde',
      'en': 'World',
      'es': 'Mundo',
      'it': 'Mondo',
    },
    'yo7evjba': {
      'fr': 'Poids *',
      'en': 'Weight *',
      'es': 'Peso *',
      'it': 'Peso *',
    },
    '4ip1u39e': {
      'fr': 'Selectionez un poids',
      'en': 'Select a weight',
      'es': 'Seleccione un peso',
      'it': 'Seleziona un peso',
    },
    'oi1d06db': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'lwhe4yum': {
      'fr': '1 Kg',
      'en': '1 kg',
      'es': '1 kilogramo',
      'it': '1 chilogrammo',
    },
    '00z4aucf': {
      'fr': '2 Kg',
      'en': '2 kg',
      'es': '2 kilos',
      'it': '2 kg',
    },
    'e6m7bf4g': {
      'fr': '5 Kg',
      'en': '5 kg',
      'es': '5 kilos',
      'it': '5 kg',
    },
    'pw05aq4l': {
      'fr': '10 Kg',
      'en': '10 kg',
      'es': '10 kilos',
      'it': '10 chili',
    },
    '991cdax2': {
      'fr': '20 Kg',
      'en': '20 kg',
      'es': '20 kilos',
      'it': '20 chili',
    },
    'sx8aoydz': {
      'fr': 'Dimension *',
      'en': 'Dimension *',
      'es': 'Dimensión *',
      'it': 'Dimensione *',
    },
    'fviwr6y5': {
      'fr': 'Selectionez les dimension ',
      'en': 'Select the dimensions',
      'es': 'Seleccione las dimensiones',
      'it': 'Seleziona le dimensioni',
    },
    'od2ye8x9': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'qvb5v5oa': {
      'fr': 'XS  enveloppe 30x20x3 (53cm)',
      'en': 'XS envelope 30x20x3 (53cm)',
      'es': 'Sobre XS 30x20x3 (53cm)',
      'it': 'Busta XS 30x20x3 (53 cm)',
    },
    'mausrod4': {
      'fr': 'S  boite chaussures 30x20x15 (65cm)',
      'en': 'S shoe box 30x20x15 (65cm)',
      'es': 'Caja de zapatos S 30x20x15 (65cm)',
      'it': 'Scatola da scarpe S 30x20x15 (65cm)',
    },
    'ncwrddwq': {
      'fr': 'M  30X30X30 (90cm)',
      'en': 'M 30X30X30 (90cm)',
      'es': 'M 30X30X30 (90cm)',
      'it': 'M 30X30X30 (90cm)',
    },
    'xoiinxe5': {
      'fr': 'L  50X50X50 (150cm)',
      'en': 'L 50X50X50 (150cm)',
      'es': 'Largo 50X50X50 (150cm)',
      'it': 'L 50X50X50 (150cm)',
    },
    'i6awga0o': {
      'fr': 'XL  80X60X60 (200cm)',
      'en': 'XL 80X60X60 (200cm)',
      'es': 'XL 80X60X60 (200cm)',
      'it': 'XL 80X60X60 (200cm)',
    },
    'v83s1u81': {
      'fr': 'TARIF :',
      'en': 'PRICE:',
      'es': 'PRECIO:',
      'it': 'PREZZO:',
    },
    'v2fia04g': {
      'fr': 'Nom *',
      'en': 'Name *',
      'es': 'Nombre *',
      'it': 'Nome *',
    },
    'ku72k40r': {
      'fr': 'Enter your first name',
      'en': 'Enter your first name',
      'es': 'Ingrese su nombre',
      'it': 'Inserisci il tuo nome',
    },
    'uyu6avar': {
      'fr': 'Prénom *',
      'en': 'First name *',
      'es': 'Nombre de pila *',
      'it': 'Nome *',
    },
    'u49b0nvr': {
      'fr': 'Enter your last name',
      'en': 'Enter your last name',
      'es': 'Introduce tu apellido',
      'it': 'Inserisci il tuo cognome',
    },
    'cuw73eds': {
      'fr': 'Email *',
      'en': 'Email *',
      'es': 'Correo electrónico *',
      'it': 'E-mail *',
    },
    't2pp719t': {
      'fr': 'Enter your email address',
      'en': 'Enter your email address',
      'es': 'Introduzca su dirección de correo electrónico',
      'it': 'Inserisci il tuo indirizzo email',
    },
    'iv4qzulg': {
      'fr': 'Téléphone *',
      'en': 'Phone *',
      'es': 'Teléfono *',
      'it': 'Telefono *',
    },
    'n7g1hb5q': {
      'fr': 'Enter your phone number',
      'en': 'Enter your phone number',
      'es': 'Introduce tu número de teléfono',
      'it': 'Inserisci il tuo numero di telefono',
    },
    'pybeoci6': {
      'fr': 'Special Requirements',
      'en': 'Special Requirements',
      'es': 'Requisitos especiales',
      'it': 'Requisiti speciali',
    },
    'weyr5ix6': {
      'fr':
          'Any special requirements, luggage details, accessibility needs, etc.',
      'en':
          'Any special requirements, luggage details, accessibility needs, etc.',
      'es':
          'Cualquier requisito especial, detalles del equipaje, necesidades de accesibilidad, etc.',
      'it':
          'Eventuali esigenze particolari, dettagli sui bagagli, esigenze di accessibilità, ecc.',
    },
    'mf7b2qdb': {
      'fr': 'Inserrez un Bordereau (PDF) *',
      'en': 'Insert a slip (PDF) *',
      'es': 'Insertar un comprobante (PDF) *',
      'it': 'Inserisci una ricevuta (PDF) *',
    },
    'injhihvg': {
      'fr': 'Un pdf a été téléchargé.',
      'en': 'A PDF has been uploaded.',
      'es': 'Se ha cargado un PDF.',
      'it': 'È stato caricato un PDF.',
    },
    '6ana5e3l': {
      'fr': 'Inserrez un Bordereau (PDF)',
      'en': 'Insert a slip (PDF)',
      'es': 'Insertar un comprobante (PDF)',
      'it': 'Inserisci una ricevuta (PDF)',
    },
    '8rcxl0s6': {
      'fr': 'Unee image a été téléchargé.',
      'en': 'An image has been uploaded.',
      'es': 'Se ha cargado una imagen.',
      'it': 'È stata caricata un\'immagine.',
    },
    'afu33gyv': {
      'fr': 'Quote Information',
      'en': 'Quote Information',
      'es': 'Información de cotización',
      'it': 'Informazioni sulla citazione',
    },
    'yh7ix7bn': {
      'fr':
          'We\'ll review your request and send you a detailed quote within 24 hours. All quotes are free and without obligation.',
      'en':
          'We\'ll review your request and send you a detailed quote within 24 hours. All quotes are free and without obligation.',
      'es':
          'Revisaremos su solicitud y le enviaremos un presupuesto detallado en 24 horas. Todos los presupuestos son gratuitos y sin compromiso.',
      'it':
          'Valuteremo la tua richiesta e ti invieremo un preventivo dettagliato entro 24 ore. Tutti i preventivi sono gratuiti e senza impegno.',
    },
    '5ybzbs85': {
      'fr': 'Confirmer',
      'en': 'Confirm',
      'es': 'Confirmar',
      'it': 'Confermare',
    },
    'r83yc20o': {
      'fr': '* Required fields',
      'en': '* Required fields',
      'es': '* Campos obligatorios',
      'it': '* Campi obbligatori',
    },
    '830ziulb': {
      'fr':
          'By submitting this form, you agree to our Terms of Service and Privacy Policy',
      'en':
          'By submitting this form, you agree to our Terms of Service and Privacy Policy',
      'es':
          'Al enviar este formulario, acepta nuestros Términos de servicio y Política de privacidad.',
      'it':
          'Inviando questo modulo, accetti i nostri Termini di servizio e l\'Informativa sulla privacy',
    },
    't96len3g': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    'xg2jcs36': {
      'fr': 'Home',
      'en': 'Home',
      'es': 'Hogar',
      'it': 'Casa',
    },
    'btzli82w': {
      'fr': 'Demande de devis',
      'en': 'Request for a quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    '8u6sev7n': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'gwzmh3i0': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    '7pnzn09f': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    '6ifl45fz': {
      'fr': 'Mon suivi',
      'en': 'My tracking',
      'es': 'Mi seguimiento',
      'it': 'Il mio monitoraggio',
    },
    '5ovsguio': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    '6bic2r12': {
      'fr': 'Mon profile',
      'en': 'My profile',
      'es': 'Mi perfil',
      'it': 'Il mio profilo',
    },
    'zo9r83q3': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'p9z50e8a': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
  },
  // Formulaire-de-devis-par-bordereau
  {
    'heledi1c': {
      'fr': 'Formulaire devis',
      'en': 'Quote form',
      'es': 'Formulario de cotización',
      'it': 'Modulo di preventivo',
    },
    'ecqz1jlv': {
      'fr':
          'Remplissez le formulaire ci-dessous et nous vous fournirons un devis compétitif pour vos besoins en transport.',
      'en':
          'Fill out the form below and we will provide you with a competitive quote for your transport needs.',
      'es':
          'Complete el formulario a continuación y le proporcionaremos una cotización competitiva para sus necesidades de transporte.',
      'it':
          'Compila il modulo sottostante e ti forniremo un preventivo competitivo per le tue esigenze di trasporto.',
    },
    'wqfii7ko': {
      'fr': 'Demande devis par bordereau d\'achat',
      'en': 'Request for a quote via purchase slip',
      'es': 'Solicitud de cotización mediante comprobante de compra',
      'it': 'Richiesta di preventivo tramite scontrino d\'acquisto',
    },
    'dd7rsein': {
      'fr': 'Que souhaitez-vous? *',
      'en': 'What would you like?',
      'es': '¿Qué le gustaría?',
      'it': 'Cosa ti piacerebbe?',
    },
    'vxy3mciq': {
      'fr': 'Selectionez ici',
      'en': 'Select here',
      'es': 'Seleccione aquí',
      'it': 'Seleziona qui',
    },
    '9175afyk': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    '1jleyuie': {
      'fr': 'Retrait enchères',
      'en': 'Auction withdrawal',
      'es': 'Retirada de subasta',
      'it': 'Ritiro dall\'asta',
    },
    '8tzczywk': {
      'fr': 'Souhaitez-vous une assurance AD valorem?  *',
      'en': 'Do you want AD valorem insurance? *',
      'es': '¿Quieres un seguro AD valorem?*',
      'it': 'Vuoi un\'assicurazione AD valorem? *',
    },
    'zopj5xhi': {
      'fr': 'Selectionez ici',
      'en': 'Select here',
      'es': 'Seleccione aquí',
      'it': 'Seleziona qui',
    },
    'atpc4pd9': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'r5w5bnke': {
      'fr': 'OUI - YES',
      'en': 'YES',
      'es': 'SÍ',
      'it': 'SÌ',
    },
    'ylvpdhj6': {
      'fr': 'NON - NO',
      'en': 'NO',
      'es': 'NO',
      'it': 'NO',
    },
    '5m6o7bzs': {
      'fr': 'Ne se prononce pas - not pronounced',
      'en': 'Not pronounced',
      'es': 'No pronunciado',
      'it': 'Non pronunciato',
    },
    'porjfywj': {
      'fr': 'Montant de la marchandise à hauteur de :',
      'en': 'Amount of goods:',
      'es': 'Cantidad de mercancías:',
      'it': 'Quantità di merci:',
    },
    '8h917upp': {
      'fr': 'Selectionez ici',
      'en': 'Select here',
      'es': 'Seleccione aquí',
      'it': 'Seleziona qui',
    },
    'gbjct5e6': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'moea6ki0': {
      'fr': 'Jusqu\'à 150 €',
      'en': 'Up to €150',
      'es': 'Hasta 150€',
      'it': 'Fino a € 150',
    },
    'e92q2ix2': {
      'fr': 'Jusqu\'à 250 €',
      'en': 'Up to €250',
      'es': 'Hasta 250€',
      'it': 'Fino a €250',
    },
    'ypsifoji': {
      'fr': 'Jusqu\'à 500 €',
      'en': 'Up to €500',
      'es': 'Hasta 500€',
      'it': 'Fino a € 500',
    },
    'q7t2ojvd': {
      'fr': 'Jusqu\'à 1000 €',
      'en': 'Up to €1000',
      'es': 'Hasta 1000€',
      'it': 'Fino a € 1000',
    },
    'hgtmku9f': {
      'fr': 'Jusqu\'à 1500 €',
      'en': 'Up to €1500',
      'es': 'Hasta 1500€',
      'it': 'Fino a € 1500',
    },
    '7x3xxnbc': {
      'fr': 'Jusqu\'à 2000 €',
      'en': 'Up to €2000',
      'es': 'Hasta 2000€',
      'it': 'Fino a € 2000',
    },
    'i8zp66ie': {
      'fr': 'Jusqu\'à 2500 €',
      'en': 'Up to €2500',
      'es': 'Hasta 2500€',
      'it': 'Fino a € 2500',
    },
    'aw2568vr': {
      'fr': 'Jusqu\'à 3000 €',
      'en': 'Up to €3000',
      'es': 'Hasta 3000€',
      'it': 'Fino a € 3000',
    },
    'zuj9pxqx': {
      'fr': 'Jusqu\'à 3500 €',
      'en': 'Up to €3500',
      'es': 'Hasta 3500€',
      'it': 'Fino a € 3500',
    },
    '3v7yrtkg': {
      'fr': 'Jusqu\'à 4000 €',
      'en': 'Up to €4000',
      'es': 'Hasta 4000€',
      'it': 'Fino a €4000',
    },
    'kti6lcuu': {
      'fr': 'Jusqu\'à 4500 €',
      'en': 'Up to €4500',
      'es': 'Hasta 4500€',
      'it': 'Fino a €4500',
    },
    'i2tfptij': {
      'fr': 'Jusqu\'à 5000 €',
      'en': 'Up to €5000',
      'es': 'Hasta 5000€',
      'it': 'Fino a € 5000',
    },
    'qsdfozzd': {
      'fr': 'Commentaire',
      'en': 'Comment',
      'es': 'Comentario',
      'it': 'Commento',
    },
    's3qdtido': {
      'fr': 'Exigences particulières, détails, etc.',
      'en': 'Specific requirements, details, etc.',
      'es': 'Requisitos específicos, detalles, etc.',
      'it': 'Requisiti specifici, dettagli, ecc.',
    },
    'k52ooucw': {
      'fr': 'Inserez un Bordereau (PDF) *',
      'en': 'Insert a slip (PDF) *',
      'es': 'Insertar un comprobante (PDF) *',
      'it': 'Inserisci una ricevuta (PDF) *',
    },
    'taftq4ax': {
      'fr': 'Un pdf a été téléchargé.',
      'en': 'A PDF has been uploaded.',
      'es': 'Se ha cargado un PDF.',
      'it': 'È stato caricato un PDF.',
    },
    'qy1s58ny': {
      'fr': 'Un pdf a été téléchargé.',
      'en': 'A PDF has been uploaded.',
      'es': 'Se ha cargado un PDF.',
      'it': 'È stato caricato un PDF.',
    },
    'khfq0k8k': {
      'fr': 'Inserrez une image',
      'en': 'Insert an image',
      'es': 'Insertar una imagen',
      'it': 'Inserisci un\'immagine',
    },
    'kxikq5kl': {
      'fr': 'Une image a été téléchargée.',
      'en': 'An image has been uploaded.',
      'es': 'Se ha cargado una imagen.',
      'it': 'È stata caricata un\'immagine.',
    },
    'dv5wcqrk': {
      'fr': 'Une image a été téléchargé.',
      'en': 'An image has been uploaded.',
      'es': 'Se ha cargado una imagen.',
      'it': 'È stata caricata un\'immagine.',
    },
    'gfduvzpb': {
      'fr': 'Informations sur le devis',
      'en': 'Quote information',
      'es': 'Información de cotización',
      'it': 'Informazioni sulla quotazione',
    },
    'f03mu0av': {
      'fr':
          'Nous étudierons votre demande et vous enverrons un devis détaillé sous 24 heures. Tous nos devis sont gratuits et sans engagement.',
      'en':
          'We will review your request and send you a detailed quote within 24 hours. All our quotes are free and without obligation.',
      'es':
          'Revisaremos su solicitud y le enviaremos un presupuesto detallado en 24 horas. Todos nuestros presupuestos son gratuitos y sin compromiso.',
      'it':
          'Valuteremo la tua richiesta e ti invieremo un preventivo dettagliato entro 24 ore. Tutti i nostri preventivi sono gratuiti e senza impegno.',
    },
    '21hyovyr': {
      'fr': 'Envoyer',
      'en': 'Send',
      'es': 'Enviar',
      'it': 'Inviare',
    },
  },
  // CONTACT
  {
    '7m2t8ufz': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    '0e3clkmt': {
      'fr': 'Entrer en contact',
      'en': 'Get in touch',
      'es': 'Ponte en contacto con nosotros',
      'it': 'Contattaci',
    },
    'qvd8wqfp': {
      'fr':
          'Nous serions ravis d\'avoir de vos nouvelles. Envoyez-nous un message et nous vous répondrons dans les plus brefs délais.',
      'en':
          'We would love to hear from you. Send us a message and we will get back to you as soon as possible.',
      'es':
          'Nos encantaría saber de usted. Envíenos un mensaje y nos pondremos en contacto con usted lo antes posible.',
      'it':
          'Ci piacerebbe sentire la tua opinione. Inviaci un messaggio e ti risponderemo il prima possibile.',
    },
    'as0k1gvp': {
      'fr': 'Envoyez-nous un courriel',
      'en': 'Send us an email',
      'es': 'Envíanos un correo electrónico',
      'it': 'Inviaci un\'e-mail',
    },
    'sg32r0oo': {
      'fr': 'Contact@expedion-encheres.com',
      'en': 'Contact@expedion-encheres.com',
      'es': 'Contacto@expedion-encheres.com',
      'it': 'Contact@expedion-encheres.com',
    },
    '9nn1d2og': {
      'fr': 'Envoyez-nous un message',
      'en': 'Send us a message',
      'es': 'Envíanos un mensaje',
      'it': 'Inviaci un messaggio',
    },
    'sagmmv2b': {
      'fr': 'Message',
      'en': 'Message',
      'es': 'Mensaje',
      'it': 'Messaggio',
    },
    'hfoq2noz': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'qpu4p8d0': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'u1co33ds': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    'lkqg92qz': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    '7j4vt96f': {
      'fr': 'Email',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    'npxhbcy4': {
      'fr': 'Email ',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    's9eur3rx': {
      'fr': 'Sujet',
      'en': 'Subject',
      'es': 'Sujeto',
      'it': 'Soggetto',
    },
    'hiowqdkf': {
      'fr': 'Sujet',
      'en': 'Subject',
      'es': 'Sujeto',
      'it': 'Soggetto',
    },
    'g253gsm2': {
      'fr': 'votre message...',
      'en': 'your message...',
      'es': 'tu mensaje...',
      'it': 'il tuo messaggio...',
    },
    '5276lkcp': {
      'fr': 'votre message...',
      'en': 'your message...',
      'es': 'tu mensaje...',
      'it': 'il tuo messaggio...',
    },
    '8yc77r8s': {
      'fr': 'Envoyer un Message',
      'en': 'Send a message',
      'es': 'Enviar un mensaje',
      'it': 'Invia un messaggio',
    },
    'd9392g77': {
      'fr': 'Appelez-nous',
      'en': 'Call us',
      'es': 'Llámanos',
      'it': 'Chiamaci',
    },
    'o8soa8ss': {
      'fr': '07 74 31 96 74',
      'en': '07 74 31 96 74',
      'es': '07 74 31 96 74',
      'it': '07 74 31 96 74',
    },
  },
  // WEB_HomepageLogedin
  {
    'ifl8uimb': {
      'fr': 'Bienvenue sur EXPEDION ENCHERES',
      'en': 'Welcome to EXPEDION AUCTIONS',
      'es': 'Bienvenido a SUBASTAS EXPEDION',
      'it': 'Benvenuti a EXPEDION AUCTIONS',
    },
    '0ark6fw0': {
      'fr': 'Innovative solutions for the digital age',
      'en': 'Innovative solutions for the digital age',
      'es': 'Soluciones innovadoras para la era digital',
      'it': 'Soluzioni innovative per l\'era digitale',
    },
    'px91je4n': {
      'fr': 'Get Started',
      'en': 'Get Started',
      'es': 'Empezar',
      'it': 'Per iniziare',
    },
    'f4vu3hce': {
      'fr': 'Learn More',
      'en': 'Learn More',
      'es': 'Más información',
      'it': 'Saperne di più',
    },
    'q6xhoubs': {
      'fr': 'Demane devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    'f99toub9': {
      'fr': 'Epédition/retrait Paiement directe',
      'en': 'Shipping/Collection Direct Payment',
      'es': 'Envío/Recogida Pago Directo',
      'it': 'Spedizione/Ritiro Pagamento diretto',
    },
    'advoi800': {
      'fr': 'Our Services',
      'en': 'Our Services',
      'es': 'Nuestros servicios',
      'it': 'I nostri servizi',
    },
    'bfprb6ez': {
      'fr': 'Comprehensive digital solutions tailored to your business needs',
      'en': 'Comprehensive digital solutions tailored to your business needs',
      'es':
          'Soluciones digitales integrales adaptadas a las necesidades de su negocio',
      'it':
          'Soluzioni digitali complete su misura per le esigenze della tua azienda',
    },
    'rl2s6bjd': {
      'fr': 'Web Development',
      'en': 'Web Development',
      'es': 'Desarrollo web',
      'it': 'Sviluppo web',
    },
    'hal7yvl8': {
      'fr':
          'Custom websites and web applications built with modern technologies',
      'en':
          'Custom websites and web applications built with modern technologies',
      'es':
          'Sitios web y aplicaciones web personalizados creados con tecnologías modernas',
      'it':
          'Siti web e applicazioni web personalizzati realizzati con tecnologie moderne',
    },
    'uc5hafvd': {
      'fr': 'Mobile Apps',
      'en': 'Mobile Apps',
      'es': 'Aplicaciones móviles',
      'it': 'Applicazioni mobili',
    },
    'va5q4qo0': {
      'fr': 'Native and cross-platform mobile applications for iOS and Android',
      'en': 'Native and cross-platform mobile applications for iOS and Android',
      'es': 'Aplicaciones móviles nativas y multiplataforma para iOS y Android',
      'it': 'Applicazioni mobili native e multipiattaforma per iOS e Android',
    },
    'mys5juh9': {
      'fr': 'Cloud Solutions',
      'en': 'Cloud Solutions',
      'es': 'Soluciones en la nube',
      'it': 'Soluzioni cloud',
    },
    'w0vsy4nq': {
      'fr': 'Scalable cloud infrastructure and deployment solutions',
      'en': 'Scalable cloud infrastructure and deployment solutions',
      'es':
          'Soluciones de implementación e infraestructura en la nube escalables',
      'it': 'Soluzioni di infrastruttura e distribuzione cloud scalabili',
    },
    'n7g4zlj4': {
      'fr': 'Data Analytics',
      'en': 'Data Analytics',
      'es': 'Análisis de datos',
      'it': 'Analisi dei dati',
    },
    'xxmy76yl': {
      'fr': 'Advanced data analysis and business intelligence solutions',
      'en': 'Advanced data analysis and business intelligence solutions',
      'es':
          'Soluciones avanzadas de análisis de datos e inteligencia empresarial',
      'it': 'Soluzioni avanzate di analisi dei dati e business intelligence',
    },
    'tzwoitel': {
      'fr': 'Cybersecurity',
      'en': 'Cybersecurity',
      'es': 'Ciberseguridad',
      'it': 'Sicurezza informatica',
    },
    'lcc7k60n': {
      'fr': 'Comprehensive security solutions to protect your digital assets',
      'en': 'Comprehensive security solutions to protect your digital assets',
      'es':
          'Soluciones de seguridad integrales para proteger sus activos digitales',
      'it':
          'Soluzioni di sicurezza complete per proteggere i tuoi asset digitali',
    },
    'm66m9em8': {
      'fr': '24/7 Support',
      'en': '24/7 Support',
      'es': 'Soporte 24/7',
      'it': 'Supporto 24 ore su 24, 7 giorni su 7',
    },
    'x8qjx3t1': {
      'fr': 'Round-the-clock technical support and maintenance services',
      'en': 'Round-the-clock technical support and maintenance services',
      'es': 'Servicios de soporte técnico y mantenimiento las 24 horas',
      'it': 'Servizi di supporto tecnico e manutenzione 24 ore su 24',
    },
    '8z7n3wcy': {
      'fr': 'Why Choose TechFlow?',
      'en': 'Why Choose TechFlow?',
      'es': '¿Por qué elegir TechFlow?',
      'it': 'Perché scegliere TechFlow?',
    },
    'fma87lp5': {
      'fr': '500+',
      'en': '500+',
      'es': 'más de 500',
      'it': '500+',
    },
    'c8dv9gy1': {
      'fr': 'Projects Completed',
      'en': 'Projects Completed',
      'es': 'Proyectos completados',
      'it': 'Progetti completati',
    },
    '28ja8i9k': {
      'fr': '98%',
      'en': '98%',
      'es': '98%',
      'it': '98%',
    },
    '9f8b4o13': {
      'fr': 'Client Satisfaction',
      'en': 'Customer Satisfaction',
      'es': 'Satisfacción del cliente',
      'it': 'Soddisfazione del cliente',
    },
    '5h3bjlzu': {
      'fr': '24/7',
      'en': '24/7',
      'es': '24/7',
      'it': '24 ore su 24, 7 giorni su 7',
    },
    'bkdxacek': {
      'fr': 'Support Available',
      'en': 'Support Available',
      'es': 'Soporte disponible',
      'it': 'Supporto disponibile',
    },
    'q0ngdbqq': {
      'fr': 'Ready to Get Started?',
      'en': 'Ready to Get Started?',
      'es': '¿Listo para comenzar?',
      'it': 'Pronti per iniziare?',
    },
    'k7541h0n': {
      'fr': 'Let\'s discuss your project and bring your ideas to life',
      'en': 'Let\'s discuss your project and bring your ideas to life',
      'es': 'Hablemos de tu proyecto y hagamos realidad tus ideas.',
      'it': 'Discutiamo del tuo progetto e diamo vita alle tue idee',
    },
    'vm53prsk': {
      'fr': 'Contact Us Today',
      'en': 'Contact Us Today',
      'es': 'Contáctenos hoy',
      'it': 'Contattaci oggi',
    },
    'krl5wkni': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    '0me6z5y9': {
      'fr': 'Home',
      'en': 'Home',
      'es': 'Hogar',
      'it': 'Casa',
    },
    'twgtlb1a': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    'ugrfgjdk': {
      'fr': 'Mes trajets',
      'en': 'My journeys',
      'es': 'Mis viajes',
      'it': 'I miei viaggi',
    },
    '8d5ouqfq': {
      'fr': 'Demande de devis',
      'en': 'Request for a quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    'y89sceou': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    'o7srome0': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'puggyani': {
      'fr': 'Mon profile',
      'en': 'My profile',
      'es': 'Mi perfil',
      'it': 'Il mio profilo',
    },
    'gl38nllq': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'l917qjfl': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
  },
  // ESPACE-PERSONNEL
  {
    '9i3zjx5u': {
      'fr': 'Compte vérifié',
      'en': 'Verified account',
      'es': 'Cuenta verificada',
      'it': 'Account verificato',
    },
    '4r81kvdj': {
      'fr': 'Verifier votre email',
      'en': 'Verify your email',
      'es': 'Verifica tu correo electrónico',
      'it': 'Verifica la tua email',
    },
    's59cbp15': {
      'fr': 'Informations personnelles',
      'en': 'Personal information',
      'es': 'Información personal',
      'it': 'Informazioni personali',
    },
    'to53x53l': {
      'fr': 'Full Name',
      'en': 'Full Name',
      'es': 'Nombre completo',
      'it': 'Nome e cognome',
    },
    'rgf5igq6': {
      'fr': 'Email Address',
      'en': 'Email Address',
      'es': 'Dirección de correo electrónico',
      'it': 'Indirizzo e-mail',
    },
    'xr6g4tpm': {
      'fr': 'Phone Number',
      'en': 'Phone Number',
      'es': 'Número de teléfono',
      'it': 'Numero di telefono',
    },
    'dffvoe57': {
      'fr': 'Date of Birth',
      'en': 'Date of Birth',
      'es': 'Fecha de nacimiento',
      'it': 'Data di nascita',
    },
    'oceax7em': {
      'fr': 'March 15, 1990',
      'en': 'March 15, 1990',
      'es': '15 de marzo de 1990',
      'it': '15 marzo 1990',
    },
    'ebti9x7j': {
      'fr': 'Address',
      'en': 'Address',
      'es': 'DIRECCIÓN',
      'it': 'Indirizzo',
    },
    'q64o46eh': {
      'fr': 'Account Details',
      'en': 'Account Details',
      'es': 'Detalles de la cuenta',
      'it': 'Dettagli dell\'account',
    },
    'ae9079ln': {
      'fr': 'Member Since',
      'en': 'Member Since',
      'es': 'Miembro desde',
      'it': 'Membro dal',
    },
    'oept8fxe': {
      'fr': 'January 2022',
      'en': 'January 2022',
      'es': 'Enero de 2022',
      'it': 'Gennaio 2022',
    },
    'x1y2511t': {
      'fr': '2+ Years',
      'en': '2+ Years',
      'es': '2+ años',
      'it': '2+ anni',
    },
    'nt595jlb': {
      'fr': 'Account Type',
      'en': 'Account Type',
      'es': 'Tipo de cuenta',
      'it': 'Tipo di account',
    },
    'esy1uyl6': {
      'fr': 'Premium Business',
      'en': 'Premium Business',
      'es': 'Negocio Premium',
      'it': 'Business Premium',
    },
    'smxz0kcp': {
      'fr': 'Active',
      'en': 'Active',
      'es': 'Activo',
      'it': 'Attivo',
    },
    'rl7qavxo': {
      'fr': 'Client ID',
      'en': 'Client ID',
      'es': 'ID de cliente',
      'it': 'ID cliente',
    },
    'hhddsf9w': {
      'fr': 'Preferences',
      'en': 'Preferences',
      'es': 'Preferencias',
      'it': 'Preferenze',
    },
    'sczo1vva': {
      'fr': 'Email Notifications',
      'en': 'Email Notifications',
      'es': 'Notificaciones por correo electrónico',
      'it': 'Notifiche e-mail',
    },
    'h1yblwou': {
      'fr': 'Receive updates and offers',
      'en': 'Receive updates and offers',
      'es': 'Recibe actualizaciones y ofertas',
      'it': 'Ricevi aggiornamenti e offerte',
    },
    '7o32k2gi': {
      'fr': 'SMS Notifications',
      'en': 'SMS Notifications',
      'es': 'Notificaciones SMS',
      'it': 'Notifiche SMS',
    },
    'h0rzu1sf': {
      'fr': 'Important alerts only',
      'en': 'Important alerts only',
      'es': 'Solo alertas importantes',
      'it': 'Solo avvisi importanti',
    },
    'zru1u0cj': {
      'fr': 'Two-Factor Authentication',
      'en': 'Two-Factor Authentication',
      'es': 'Autenticación de dos factores',
      'it': 'Autenticazione a due fattori',
    },
    '6iw760vk': {
      'fr': 'Enhanced security enabled',
      'en': 'Enhanced security enabled',
      'es': 'Seguridad mejorada habilitada',
      'it': 'Sicurezza avanzata abilitata',
    },
    'os618lia': {
      'fr': 'modifier le profil',
      'en': 'edit profile',
      'es': 'editar perfil',
      'it': 'modifica profilo',
    },
    'y2ysttsd': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'qvs1yojv': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    'i2d1g9yg': {
      'fr': 'Accueil',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'it': 'Benvenuto',
    },
    'a9pldtu7': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    'mue6nq42': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    '3atj3rxa': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'zvscylss': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    'synwncas': {
      'fr': 'FAQ - Questions',
      'en': 'FAQ - Questions',
      'es': 'Preguntas frecuentes',
      'it': 'FAQ - Domande',
    },
    'qcei6ale': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'mbjynux7': {
      'fr': 'Espace Personnel',
      'en': 'Personal Space',
      'es': 'Espacio personal',
      'it': 'Spazio personale',
    },
    '4a0kztaw': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'd3a5dq1u': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
  },
  // CHOIX-DEVIS
  {
    '71ds2bl2': {
      'fr': 'Choisissez votre type de devis',
      'en': 'Choose your quote type',
      'es': 'Elige tu tipo de cotización',
      'it': 'Scegli il tipo di preventivo',
    },
    'lvr4yeik': {
      'fr':
          'Sélectionnez l\'option qui correspond le mieux à vos besoins pour obtenir votre devis personnalisé.',
      'en':
          'Select the option that best suits your needs to get your personalized quote.',
      'es':
          'Selecciona la opción que más se adapte a tus necesidades para obtener tu cotización personalizada.',
      'it':
          'Seleziona l\'opzione più adatta alle tue esigenze per ottenere un preventivo personalizzato.',
    },
    'yde5e11u': {
      'fr': 'Demande devis retrait d\'enchères avec bordereau (PDF)',
      'en': 'Request for a quote for auction withdrawal with a receipt (PDF)',
      'es': 'Solicitud de cotización para retirada en subasta con recibo (PDF)',
      'it': 'Richiesta di preventivo per ritiro asta con ricevuta (PDF)',
    },
    'qpnq17hp': {
      'fr':
          'insserez votre bordereau. Notre équipe analysera vos besoins et vous enverra un devis sur mesure dans les plus brefs délais.',
      'en':
          'Insert your slip. Our team will analyze your needs and send you a customized quote as soon as possible.',
      'es':
          'Introduzca su comprobante. Nuestro equipo analizará sus necesidades y le enviará un presupuesto personalizado lo antes posible.',
      'it':
          'Inserisci la tua ricevuta. Il nostro team analizzerà le tue esigenze e ti invierà un preventivo personalizzato il prima possibile.',
    },
    'u0whnid2': {
      'fr': 'Ouvrir',
      'en': 'Open',
      'es': 'Abierto',
      'it': 'Aprire',
    },
    'lme89yq5': {
      'fr': 'Demande devis retrait d\'Enchères avec bordereau autre que PDF',
      'en':
          'Request for a quote for auction withdrawal with a receipt other than PDF',
      'es':
          'Solicitud de cotización para retiro en subasta con recibo distinto a PDF',
      'it':
          'Richiesta di preventivo per ritiro asta con ricevuta diversa dal PDF',
    },
    'p955g0p0': {
      'fr':
          'Complétez un formulaire personnalisé avec tous les détails de votre projet. Notre équipe analysera vos besoins et vous enverra un devis sur mesure dans les plus brefs délais.',
      'en':
          'Complete a personalized form with all the details of your project. Our team will analyze your needs and send you a customized quote as soon as possible.',
      'es':
          'Complete un formulario personalizado con todos los detalles de su proyecto. Nuestro equipo analizará sus necesidades y le enviará un presupuesto personalizado lo antes posible.',
      'it':
          'Compila un modulo personalizzato con tutti i dettagli del tuo progetto. Il nostro team analizzerà le tue esigenze e ti invierà un preventivo personalizzato il prima possibile.',
    },
    'z31kc7pq': {
      'fr': 'Ouvrir',
      'en': 'Open',
      'es': 'Abierto',
      'it': 'Aprire',
    },
    'b1eopx3k': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    '58p9x5jp': {
      'fr': 'Accueil',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'it': 'Benvenuto',
    },
    '2sl6gjuo': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    'stvx2t0k': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    '0lc48hlm': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'yioiqruk': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    'pugnm9vu': {
      'fr': 'FAQ - Questions',
      'en': 'FAQ - Questions',
      'es': 'Preguntas frecuentes',
      'it': 'FAQ - Domande',
    },
    'ci5erdwg': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'lnv6tlbf': {
      'fr': 'Espace Personnel',
      'en': 'Personal Space',
      'es': 'Espacio personal',
      'it': 'Spazio personale',
    },
    '6hbnr48q': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    '76spcqa0': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
  },
  // WEB_formDDevis
  {
    'dhmbzl8d': {
      'fr': 'Formulaire demande de devis',
      'en': 'Quote request form',
      'es': 'Formulario de solicitud de cotización',
      'it': 'Modulo di richiesta preventivo',
    },
    'firjfrpe': {
      'fr':
          'Remplissez le formulaire ci-dessous et nous vous fournirons un devis compétitif pour vos besoins en transport.',
      'en':
          'Fill out the form below and we will provide you with a competitive quote for your transport needs.',
      'es':
          'Complete el formulario a continuación y le proporcionaremos una cotización competitiva para sus necesidades de transporte.',
      'it':
          'Compila il modulo sottostante e ti forniremo un preventivo competitivo per le tue esigenze di trasporto.',
    },
    'spohi6dk': {
      'fr': 'Contact Information',
      'en': 'Contact Information',
      'es': 'Información del contacto',
      'it': 'Informazioni sui contatti',
    },
    'f3k73uzk': {
      'fr': 'Que souhaitez-vous? *',
      'en': 'What would you like?',
      'es': '¿Qué le gustaría?',
      'it': 'Cosa ti piacerebbe?',
    },
    'iwo3mhvu': {
      'fr': 'Selectionez la destination',
      'en': 'Select the destination',
      'es': 'Seleccione el destino',
      'it': 'Seleziona la destinazione',
    },
    'a2j9elgl': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'l34q6tbt': {
      'fr': 'Autre expédition de biens',
      'en': 'Another shipment of goods',
      'es': 'Otro envío de mercancías',
      'it': 'Un\'altra spedizione di merci',
    },
    'sela5t0p': {
      'fr': 'Retrait enchères',
      'en': 'Auction withdrawal',
      'es': 'Retirada de subasta',
      'it': 'Ritiro dall\'asta',
    },
    'mg077mca': {
      'fr': 'Envoyer vos biens',
      'en': 'Send your belongings',
      'es': 'Envía tus pertenencias',
      'it': 'Invia i tuoi effetti personali',
    },
    'ug6r1z3j': {
      'fr': 'Demander un devis avant achat/vente aux enchères',
      'en': 'Request a quote before buying/auctioning',
      'es': 'Solicite una cotización antes de comprar/subasta',
      'it': 'Richiedi un preventivo prima di acquistare/mettere all\'asta',
    },
    'mplmnwt1': {
      'fr': 'Demander un devis avant vente aux enchères',
      'en': 'Request a quote before the auction',
      'es': 'Solicitar cotización antes de la subasta',
      'it': 'Richiedi un preventivo prima dell\'asta',
    },
    'wgyc2257': {
      'fr': 'Souhaitez-vous une assurance AD valorem?  *',
      'en': 'Do you want AD valorem insurance? *',
      'es': '¿Quieres un seguro AD valorem?*',
      'it': 'Vuoi un\'assicurazione AD valorem? *',
    },
    '2bvf7hi8': {
      'fr': 'Selectionez ici',
      'en': 'Select here',
      'es': 'Seleccione aquí',
      'it': 'Seleziona qui',
    },
    '92g1a1bg': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    '0rq2v4o4': {
      'fr': 'OUI - YES',
      'en': 'YES',
      'es': 'SÍ',
      'it': 'SÌ',
    },
    'hjnf5k0v': {
      'fr': 'NON - NO',
      'en': 'NO',
      'es': 'NO',
      'it': 'NO',
    },
    'w1mubpee': {
      'fr': 'Ne se prononce pas - not pronounced',
      'en': 'Not pronounced',
      'es': 'No pronunciado',
      'it': 'Non pronunciato',
    },
    'f1kemmbo': {
      'fr': 'Tranche Montant de la marchandise *',
      'en': 'Tranche Amount of merchandise *',
      'es': 'Tramo Cantidad de mercancía *',
      'it': 'Importo della tranche di merce *',
    },
    'lv1niurk': {
      'fr': 'Selectionez les dimension ',
      'en': 'Select the dimensions',
      'es': 'Seleccione las dimensiones',
      'it': 'Seleziona le dimensioni',
    },
    'ebmee1g9': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'rpo70cuh': {
      'fr': 'Jusqu\'à 150 €',
      'en': 'Up to €150',
      'es': 'Hasta 150€',
      'it': 'Fino a € 150',
    },
    '3ay0oq7j': {
      'fr': 'Jusqu\'à 250 €',
      'en': 'Up to €250',
      'es': 'Hasta 250€',
      'it': 'Fino a €250',
    },
    '1fe18dmn': {
      'fr': 'Jusqu\'à 500 €',
      'en': 'Up to €500',
      'es': 'Hasta 500€',
      'it': 'Fino a € 500',
    },
    '5mr7i7vg': {
      'fr': 'Jusqu\'à 1000 €',
      'en': 'Up to €1000',
      'es': 'Hasta 1000€',
      'it': 'Fino a € 1000',
    },
    'o9h93ay3': {
      'fr': 'Jusqu\'à 1500 €',
      'en': 'Up to €1500',
      'es': 'Hasta 1500€',
      'it': 'Fino a € 1500',
    },
    '5bavl4nh': {
      'fr': 'Jusqu\'à 2000 €',
      'en': 'Up to €2000',
      'es': 'Hasta 2000€',
      'it': 'Fino a € 2000',
    },
    'n56a5wud': {
      'fr': 'Jusqu\'à 2500 €',
      'en': 'Up to €2500',
      'es': 'Hasta 2500€',
      'it': 'Fino a € 2500',
    },
    '8yh80jwb': {
      'fr': 'Jusqu\'à 3000 €',
      'en': 'Up to €3000',
      'es': 'Hasta 3000€',
      'it': 'Fino a € 3000',
    },
    'c7j1cxfg': {
      'fr': 'Jusqu\'à 3500 €',
      'en': 'Up to €3500',
      'es': 'Hasta 3500€',
      'it': 'Fino a € 3500',
    },
    '1trwpbxe': {
      'fr': 'Jusqu\'à 4000 €',
      'en': 'Up to €4000',
      'es': 'Hasta 4000€',
      'it': 'Fino a €4000',
    },
    'p1khso0u': {
      'fr': 'Jusqu\'à 4500 €',
      'en': 'Up to €4500',
      'es': 'Hasta 4500€',
      'it': 'Fino a €4500',
    },
    'ltwhwnlp': {
      'fr': 'Jusqu\'à 5000 €',
      'en': 'Up to €5000',
      'es': 'Hasta 5000€',
      'it': 'Fino a € 5000',
    },
    'x3uobcp1': {
      'fr': 'Nom *',
      'en': 'Name *',
      'es': 'Nombre *',
      'it': 'Nome *',
    },
    'g4l06t70': {
      'fr': 'Enter your first name',
      'en': 'Enter your first name',
      'es': 'Ingrese su nombre',
      'it': 'Inserisci il tuo nome',
    },
    'q8b17lf9': {
      'fr': 'Prénom *',
      'en': 'First name *',
      'es': 'Nombre de pila *',
      'it': 'Nome *',
    },
    'zazeb7v6': {
      'fr': 'Enter your last name',
      'en': 'Enter your last name',
      'es': 'Introduce tu apellido',
      'it': 'Inserisci il tuo cognome',
    },
    '2m3ccgwb': {
      'fr': 'Email *',
      'en': 'Email *',
      'es': 'Correo electrónico *',
      'it': 'E-mail *',
    },
    'pyma3z1r': {
      'fr': 'Enter your email address',
      'en': 'Enter your email address',
      'es': 'Introduzca su dirección de correo electrónico',
      'it': 'Inserisci il tuo indirizzo email',
    },
    '0lmxrjy8': {
      'fr': 'Téléphone *',
      'en': 'Phone *',
      'es': 'Teléfono *',
      'it': 'Telefono *',
    },
    'gpqf77ur': {
      'fr': 'Enter your phone number',
      'en': 'Enter your phone number',
      'es': 'Introduce tu número de teléfono',
      'it': 'Inserisci il tuo numero di telefono',
    },
    'sr2le05e': {
      'fr': 'Special Requirements',
      'en': 'Special Requirements',
      'es': 'Requisitos especiales',
      'it': 'Requisiti speciali',
    },
    'dok3ccp6': {
      'fr':
          'Any special requirements, luggage details, accessibility needs, etc.',
      'en':
          'Any special requirements, luggage details, accessibility needs, etc.',
      'es':
          'Cualquier requisito especial, detalles del equipaje, necesidades de accesibilidad, etc.',
      'it':
          'Eventuali esigenze particolari, dettagli sui bagagli, esigenze di accessibilità, ecc.',
    },
    'lkrs94qs': {
      'fr': 'Inserrez un Bordereau (PDF) *',
      'en': 'Insert a slip (PDF) *',
      'es': 'Insertar un comprobante (PDF) *',
      'it': 'Inserisci una ricevuta (PDF) *',
    },
    'k8m5rvad': {
      'fr': 'Un pdf a été téléchargé.',
      'en': 'A PDF has been uploaded.',
      'es': 'Se ha cargado un PDF.',
      'it': 'È stato caricato un PDF.',
    },
    '2ek9p54z': {
      'fr': 'Inserrez une image',
      'en': 'Insert an image',
      'es': 'Insertar una imagen',
      'it': 'Inserisci un\'immagine',
    },
    'aw254520': {
      'fr': 'Unee image a été téléchargé.',
      'en': 'An image has been uploaded.',
      'es': 'Se ha cargado una imagen.',
      'it': 'È stata caricata un\'immagine.',
    },
    '7p7lcs5j': {
      'fr': 'Informations sur le devis',
      'en': 'Quote information',
      'es': 'Información de cotización',
      'it': 'Informazioni sulla quotazione',
    },
    'yq1b1mc3': {
      'fr':
          'Nous étudierons votre demande et vous enverrons un devis détaillé sous 24 heures. Tous nos devis sont gratuits et sans engagement.',
      'en':
          'We will review your request and send you a detailed quote within 24 hours. All our quotes are free and without obligation.',
      'es':
          'Revisaremos su solicitud y le enviaremos un presupuesto detallado en 24 horas. Todos nuestros presupuestos son gratuitos y sin compromiso.',
      'it':
          'Valuteremo la tua richiesta e ti invieremo un preventivo dettagliato entro 24 ore. Tutti i nostri preventivi sono gratuiti e senza impegno.',
    },
    'eblwojrk': {
      'fr': 'Envoyer',
      'en': 'Send',
      'es': 'Enviar',
      'it': 'Inviare',
    },
    'k5odoo1f': {
      'fr': '* Required fields',
      'en': '* Required fields',
      'es': '* Campos obligatorios',
      'it': '* Campi obbligatori',
    },
    'ctr9taor': {
      'fr':
          'By submitting this form, you agree to our Terms of Service and Privacy Policy',
      'en':
          'By submitting this form, you agree to our Terms of Service and Privacy Policy',
      'es':
          'Al enviar este formulario, acepta nuestros Términos de servicio y Política de privacidad.',
      'it':
          'Inviando questo modulo, accetti i nostri Termini di servizio e l\'Informativa sulla privacy',
    },
    '1mwjh3e7': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    'au09be00': {
      'fr': 'Home',
      'en': 'Home',
      'es': 'Hogar',
      'it': 'Casa',
    },
    '6bloylzu': {
      'fr': 'Demande de devis',
      'en': 'Request for a quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    'scz62o74': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'dtsk16kk': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'rmezwxpq': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    '04vs1jm4': {
      'fr': 'Mon suivi',
      'en': 'My tracking',
      'es': 'Mi seguimiento',
      'it': 'Il mio monitoraggio',
    },
    'mqj8sr80': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    'zgrixwl8': {
      'fr': 'Mon profile',
      'en': 'My profile',
      'es': 'Mi perfil',
      'it': 'Il mio profilo',
    },
    '92le2xii': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'pf1aus4w': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
  },
  // Formulaire-demande-de-devis-retrait-aux-encheres
  {
    'gqwuphmw': {
      'fr': 'Formulaire de demande de devis',
      'en': 'Quote request form',
      'es': 'Formulario de solicitud de cotización',
      'it': 'Modulo di richiesta preventivo',
    },
    't06p672b': {
      'fr':
          'Veuillez remplir tous les champs requis pour obtenir votre devis personnalisé',
      'en':
          'Please fill in all required fields to receive your personalized quote',
      'es':
          'Por favor, rellene todos los campos obligatorios para recibir su cotización personalizada',
      'it':
          'Compila tutti i campi obbligatori per ricevere il tuo preventivo personalizzato',
    },
    'a4ydcc34': {
      'fr': 'Informations personnelles',
      'en': 'Personal information',
      'es': 'Información personal',
      'it': 'Informazioni personali',
    },
    '5rzywa9z': {
      'fr': 'Prénom *',
      'en': 'First name *',
      'es': 'Nombre de pila *',
      'it': 'Nome *',
    },
    'ax1dz33q': {
      'fr': 'Nom *',
      'en': 'Name *',
      'es': 'Nombre *',
      'it': 'Nome *',
    },
    'fiq8xs6g': {
      'fr': 'E-mail *',
      'en': 'Email *',
      'es': 'Correo electrónico *',
      'it': 'E-mail *',
    },
    '8i0w5o50': {
      'fr': 'Téléphone',
      'en': 'Phone',
      'es': 'Teléfono',
      'it': 'Telefono',
    },
    '6djx4rvt': {
      'fr': 'Téléphone *',
      'en': 'Phone *',
      'es': 'Teléfono *',
      'it': 'Telefono *',
    },
    'a74mz5jk': {
      'fr': 'Souhaitez-vous une assurance ad valorem ?',
      'en': 'Do you want ad valorem insurance?',
      'es': '¿Quieres un seguro ad valorem?',
      'it': 'Vuoi un\'assicurazione ad valorem?',
    },
    '7vh5sgle': {
      'fr': 'Selectionez ',
      'en': 'Select',
      'es': 'Seleccionar',
      'it': 'Selezionare',
    },
    'r5mltiss': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'z92z0s8r': {
      'fr': 'OUI - YES',
      'en': 'YES',
      'es': 'SÍ',
      'it': 'SÌ',
    },
    'g44mhedi': {
      'fr': 'NON - NO',
      'en': 'NO',
      'es': 'NO',
      'it': 'NO',
    },
    '7jiw1b3b': {
      'fr': 'Ne se prononce pas - not pronounced',
      'en': 'Not pronounced',
      'es': 'No pronunciado',
      'it': 'Non pronunciato',
    },
    'xooz224p': {
      'fr': 'Informations de retrait',
      'en': 'Withdrawal information',
      'es': 'Información de retiro',
      'it': 'Informazioni sul prelievo',
    },
    '9hlv2j2f': {
      'fr': 'Adresse de retrait *',
      'en': 'Collection address *',
      'es': 'Dirección de recogida *',
      'it': 'Indirizzo di ritiro *',
    },
    '50tk57nk': {
      'fr': 'Code postal *',
      'en': 'Postal code *',
      'es': 'Código Postal *',
      'it': 'Codice Postale *',
    },
    'v26finnx': {
      'fr': 'Lieu de retrait *',
      'en': 'Collection location *',
      'es': 'Lugar de recogida *',
      'it': 'Luogo di ritiro *',
    },
    '5oocw13p': {
      'fr': 'Nom de la maison de ventes',
      'en': 'Name of the auction house',
      'es': 'Nombre de la casa de subastas',
      'it': 'Nome della casa d\'aste',
    },
    '2666zr30': {
      'fr': 'Téléphone de retrait',
      'en': 'Withdrawal phone',
      'es': 'Teléfono de retiro',
      'it': 'Telefono per il prelievo',
    },
    'ek2kcn3e': {
      'fr': 'Détails de la vente',
      'en': 'Sale details',
      'es': 'Detalles de la venta',
      'it': 'Dettagli della vendita',
    },
    'bkpqkokx': {
      'fr': 'Valeur de lot (s)',
      'en': 'Lot value(s)',
      'es': 'Valor(es) del lote',
      'it': 'Valore(i) del lotto',
    },
    'ir74llym': {
      'fr': 'Tarif de la marchandie',
      'en': 'Merchandise price',
      'es': 'Precio de la mercancía',
      'it': 'Prezzo della merce',
    },
    '954d223t': {
      'fr': 'Selectionez la tranche du tarif de la machandise',
      'en': 'Select the merchandise price bracket',
      'es': 'Seleccione el rango de precios de la mercancía',
      'it': 'Seleziona la fascia di prezzo della merce',
    },
    'rv2rqyvp': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'd5zxn2g0': {
      'fr': 'Jusqu\'à 150 €',
      'en': 'Up to €150',
      'es': 'Hasta 150€',
      'it': 'Fino a € 150',
    },
    'tkd42xy5': {
      'fr': 'Jusqu\'à 250 €',
      'en': 'Up to €250',
      'es': 'Hasta 250€',
      'it': 'Fino a €250',
    },
    '3qgun8w1': {
      'fr': 'Jusqu\'à 500 €',
      'en': 'Up to €500',
      'es': 'Hasta 500€',
      'it': 'Fino a € 500',
    },
    '49hkfyt7': {
      'fr': 'Jusqu\'à 1000 €',
      'en': 'Up to €1000',
      'es': 'Hasta 1000€',
      'it': 'Fino a € 1000',
    },
    '356y6grj': {
      'fr': 'Jusqu\'à 1500 €',
      'en': 'Up to €1500',
      'es': 'Hasta 1500€',
      'it': 'Fino a € 1500',
    },
    'agyks0a2': {
      'fr': 'Jusqu\'à 2000 €',
      'en': 'Up to €2000',
      'es': 'Hasta 2000€',
      'it': 'Fino a € 2000',
    },
    'fhinionc': {
      'fr': 'Jusqu\'à 2500 €',
      'en': 'Up to €2500',
      'es': 'Hasta 2500€',
      'it': 'Fino a € 2500',
    },
    'semj759v': {
      'fr': 'Jusqu\'à 3000 €',
      'en': 'Up to €3000',
      'es': 'Hasta 3000€',
      'it': 'Fino a € 3000',
    },
    'vo2x5x5b': {
      'fr': 'Jusqu\'à 3500 €',
      'en': 'Up to €3500',
      'es': 'Hasta 3500€',
      'it': 'Fino a € 3500',
    },
    'fgnm1dwg': {
      'fr': 'Jusqu\'à 4000 €',
      'en': 'Up to €4000',
      'es': 'Hasta 4000€',
      'it': 'Fino a €4000',
    },
    'jiii0kr8': {
      'fr': 'Jusqu\'à 4500 €',
      'en': 'Up to €4500',
      'es': 'Hasta 4500€',
      'it': 'Fino a €4500',
    },
    '3d692jep': {
      'fr': 'Jusqu\'à 5000 €',
      'en': 'Up to €5000',
      'es': 'Hasta 5000€',
      'it': 'Fino a € 5000',
    },
    'u8dgwycs': {
      'fr': 'Date de vente',
      'en': 'Sale date',
      'es': 'Fecha de venta',
      'it': 'Data di vendita',
    },
    'ulgamns6': {
      'fr': 'Bordereaux / Preuve d\'achat',
      'en': 'Receipts / Proof of Purchase',
      'es': 'Recibos / Comprobante de compra',
      'it': 'Ricevute/Prova d\'acquisto',
    },
    '9snhi2ln': {
      'fr': 'N° Bordereau',
      'en': 'Slip No.',
      'es': 'No. de resbalón',
      'it': 'Numero di scontrino',
    },
    'zathrxix': {
      'fr': 'Bordereau acquitté ?',
      'en': 'Receipt paid?',
      'es': '¿Recibo pagado?',
      'it': 'Ricevuta pagata?',
    },
    'z9m9i5lv': {
      'fr': 'Selectionez...',
      'en': 'Select...',
      'es': 'Seleccionar...',
      'it': 'Selezionare...',
    },
    'o3zi3di6': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'gpo7z286': {
      'fr': 'oui',
      'en': 'Yes',
      'es': 'Sí',
      'it': 'SÌ',
    },
    '8s6re8iy': {
      'fr': 'non',
      'en': 'No',
      'es': 'No',
      'it': 'NO',
    },
    'rcydk43t': {
      'fr': 'Description détaillée de l\'objet *',
      'en': 'Detailed description of the item *',
      'es': 'Descripción detallada del artículo *',
      'it': 'Descrizione dettagliata dell\'articolo *',
    },
    'w976t7ez': {
      'fr': 'Dimensions (cm)',
      'en': 'Dimensions (cm)',
      'es': 'Dimensiones (cm)',
      'it': 'Dimensioni (cm)',
    },
    'la2apkc8': {
      'fr': 'Longueur',
      'en': 'Length',
      'es': 'Longitud',
      'it': 'Lunghezza',
    },
    'jzb67ybw': {
      'fr': 'Largeur',
      'en': 'Width',
      'es': 'Ancho',
      'it': 'Larghezza',
    },
    'gz287b6u': {
      'fr': 'Hauteur',
      'en': 'Height',
      'es': 'Altura',
      'it': 'Altezza',
    },
    '4xyrvadw': {
      'fr': 'Poids de l\'objet (kg)',
      'en': 'Weight of the object (kg)',
      'es': 'Peso del objeto (kg)',
      'it': 'Peso dell\'oggetto (kg)',
    },
    'yrfkbyrs': {
      'fr': 'L\'objet est-il déjà protégé ou emballé ?',
      'en': 'Is the item already protected or packaged?',
      'es': '¿El artículo ya está protegido o empaquetado?',
      'it': 'L\'articolo è già protetto o imballato?',
    },
    'z8puz1ip': {
      'fr': 'Search...',
      'en': 'Search...',
      'es': 'Buscar...',
      'it': 'Ricerca...',
    },
    'birmak3z': {
      'fr': 'Non emballé / non protégé - Not packaged / not protected',
      'en': 'Unpackaged / unprotected',
      'es': 'Sin embalaje/sin protección',
      'it': 'Non imballato / non protetto',
    },
    'ls4lqsci': {
      'fr': 'Protégé  - Protected',
      'en': 'Protected',
      'es': 'Protegido',
      'it': 'Protetto',
    },
    '65qlz7g7': {
      'fr': 'Emballé - Packaged',
      'en': 'Packaged',
      'es': 'Empaquetado',
      'it': 'Confezionato',
    },
    'o5rdvkph': {
      'fr': 'Ajouter des images',
      'en': 'Add images',
      'es': 'Añadir imágenes',
      'it': 'Aggiungi immagini',
    },
    'ie4ovvw0': {
      'fr': 'Adresse de livraison',
      'en': 'Delivery address',
      'es': 'Dirección de entrega',
      'it': 'Indirizzo di consegna',
    },
    'p4qiy3pg': {
      'fr': 'Adresse de livraison *',
      'en': 'Delivery address *',
      'es': 'Dirección de entrega *',
      'it': 'Indirizzo di consegna *',
    },
    'lpp84179': {
      'fr': 'Complément d\'adresse',
      'en': 'Additional address information',
      'es': 'Información adicional sobre la dirección',
      'it': 'Informazioni aggiuntive sull\'indirizzo',
    },
    'quhclwxv': {
      'fr': 'Code postal *',
      'en': 'Postal code *',
      'es': 'Código Postal *',
      'it': 'Codice Postale *',
    },
    'nxgs9dwx': {
      'fr': 'Ville l *',
      'en': 'City l *',
      'es': 'Ciudad l *',
      'it': 'Città l *',
    },
    'v3cg5op1': {
      'fr': 'Téléphone de livraison',
      'en': 'Delivery phone',
      'es': 'Teléfono de entrega',
      'it': 'Telefono di consegna',
    },
    '9ktk71lt': {
      'fr': 'Nom du destinataire',
      'en': 'Recipient\'s name',
      'es': 'Nombre del destinatario',
      'it': 'Nome del destinatario',
    },
    'sj1gfp8m': {
      'fr': 'Envoyer',
      'en': 'Button',
      'es': 'Botón',
      'it': 'Pulsante',
    },
    'w50q3e36': {
      'fr': 'Formulaire devis',
      'en': 'Quote form',
      'es': 'Formulario de cotización',
      'it': 'Modulo di preventivo',
    },
  },
  // PageModifInfoPerso
  {
    'esmcfxjx': {
      'fr': 'Modification',
      'en': 'Modification',
      'es': 'Modificación',
      'it': 'Modifica',
    },
    'oth21gc1': {
      'fr': 'Modification',
      'en': 'Edit Profile',
      'es': 'Modificación',
      'it': 'Modifica',
    },
    'zevws96d': {
      'fr': 'Informations personnelles',
      'en': 'Personal information',
      'es': 'Información personal',
      'it': 'Informazioni personali',
    },
    '9vx9ir8o': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    '4oqmkj58': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    '4qgsy9kc': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    'py0lssh7': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    'gaj297r4': {
      'fr': 'Téléphone',
      'en': 'Phone',
      'es': 'Teléfono',
      'it': 'Telefono',
    },
    'jw0htcaa': {
      'fr': 'Téléphone',
      'en': 'Phone',
      'es': 'Teléfono',
      'it': 'Telefono',
    },
    'ewnxokpl': {
      'fr': 'Adresse personnelle du client',
      'en': 'Customer\'s personal address',
      'es': 'Dirección personal del cliente',
      'it': 'Indirizzo personale del cliente',
    },
    'tox7dx5l': {
      'fr': 'Adresse ligne 1',
      'en': 'Address line 1',
      'es': 'Dirección Línea 1',
      'it': 'Indirizzo Linea 1',
    },
    '65elkrk0': {
      'fr': 'Adresse ligne 1',
      'en': 'Address line 1',
      'es': 'Dirección Línea 1',
      'it': 'Indirizzo Linea 1',
    },
    'lmnug7qc': {
      'fr': 'Adresse ligne 2 ',
      'en': 'Address line 2',
      'es': 'Línea de dirección 2',
      'it': 'Indirizzo riga 2',
    },
    'nounmbzb': {
      'fr': 'Adresse ligne 2 (optionnel)',
      'en': 'Address line 2 (optional)',
      'es': 'Línea de dirección 2 (opcional)',
      'it': 'Indirizzo riga 2 (facoltativo)',
    },
    '5lwuborp': {
      'fr': 'Code postal',
      'en': 'Postal code',
      'es': 'Código Postal',
      'it': 'Codice Postale',
    },
    'a9odsdmh': {
      'fr': 'Code postal',
      'en': 'Postal code',
      'es': 'Código Postal',
      'it': 'Codice Postale',
    },
    'p23rj47a': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    '2ig4y6c0': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    'ijpexwei': {
      'fr': 'Pays',
      'en': 'Country',
      'es': 'País',
      'it': 'Paese',
    },
    'gbc1bm6l': {
      'fr': 'Pays',
      'en': 'Country',
      'es': 'País',
      'it': 'Paese',
    },
    'zcl0n9by': {
      'fr': 'Utiliser la même adresse pour la livraison',
      'en': 'Use the same address for delivery',
      'es': 'Utilice la misma dirección para la entrega',
      'it': 'Utilizzare lo stesso indirizzo per la consegna',
    },
    '0qs75dag': {
      'fr': 'Adresse de livraison',
      'en': 'Delivery address',
      'es': 'Dirección de entrega',
      'it': 'Indirizzo di consegna',
    },
    'evqabjj4': {
      'fr': 'Adresse de livraison ligne 1',
      'en': 'Delivery address line 1',
      'es': 'Línea 1 de dirección de entrega',
      'it': 'Indirizzo di consegna riga 1',
    },
    'yl2jbbat': {
      'fr': 'Adresse de livraison ligne 1',
      'en': 'Delivery address line 1',
      'es': 'Línea 1 de dirección de entrega',
      'it': 'Indirizzo di consegna riga 1',
    },
    'fxe8uhjz': {
      'fr': 'Adresse de livraison ligne 2',
      'en': 'Delivery address line 2',
      'es': 'Línea 2 de dirección de entrega',
      'it': 'Indirizzo di consegna riga 2',
    },
    'r7pdqpic': {
      'fr': 'Adresse de livraison ligne 2 (optionnel)',
      'en': 'Delivery address line 2 (optional)',
      'es': 'Línea 2 de dirección de entrega (opcional)',
      'it': 'Indirizzo di consegna riga 2 (facoltativo)',
    },
    'smnpx21s': {
      'fr': 'Code postal',
      'en': 'Postal code',
      'es': 'Código Postal',
      'it': 'Codice Postale',
    },
    '6b9f4wpd': {
      'fr': 'Code postal',
      'en': 'Postal code',
      'es': 'Código Postal',
      'it': 'Codice Postale',
    },
    '98wp8tb9': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    'czi53g4m': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    '09m3o7y2': {
      'fr': 'Pays',
      'en': 'Country',
      'es': 'País',
      'it': 'Paese',
    },
    '3x0289bz': {
      'fr': 'Pays',
      'en': 'Country',
      'es': 'País',
      'it': 'Paese',
    },
    'ytzjx35b': {
      'fr': 'Téléphone de livraison',
      'en': 'Delivery phone',
      'es': 'Teléfono de entrega',
      'it': 'Telefono di consegna',
    },
    'walu8o6s': {
      'fr': 'Téléphone de livraison',
      'en': 'Delivery phone',
      'es': 'Teléfono de entrega',
      'it': 'Telefono di consegna',
    },
    '5lbsjlle': {
      'fr': 'Enregistrer',
      'en': 'Save',
      'es': 'Ahorrar',
      'it': 'Salva',
    },
  },
  // FAQ
  {
    'a51utwlj': {
      'fr': 'Aide et Support ',
      'en': 'Help and Support',
      'es': 'Ayuda y soporte',
      'it': 'Aiuto e supporto',
    },
    'jwhf0in0': {
      'fr':
          'Trouvez rapidement les réponses à vos questions sur notre plateforme de demande de devis.',
      'en':
          'Quickly find answers to your questions on our quote request platform.',
      'es':
          'Encuentre rápidamente respuestas a sus preguntas en nuestra plataforma de solicitud de cotizaciones.',
      'it':
          'Trova rapidamente le risposte alle tue domande sulla nostra piattaforma di richiesta preventivo.',
    },
    'ceggp3x7': {
      'fr': 'Général',
      'en': 'General',
      'es': 'General',
      'it': 'Generale',
    },
    'u1farn8n': {
      'fr': 'Comment fonctionne la plateforme ?',
      'en': 'How does the platform work?',
      'es': '¿Cómo funciona la plataforma?',
      'it': 'Come funziona la piattaforma?',
    },
    'qqf0v11u': {
      'fr':
          'Notre plateforme vous permet de soumettre une demande de devis en quelques clics. Inscrivez-vous et complétez le fomulaire de dedmande de devis en joignant vos documents.',
      'en':
          'Our platform allows you to submit a quote request in just a few clicks. Register and complete the quote request form, attaching your documents.',
      'es':
          'Nuestra plataforma le permite solicitar una cotización con solo unos clics. Regístrese y complete el formulario de solicitud de cotización, adjuntando sus documentos.',
      'it':
          'La nostra piattaforma ti consente di inviare una richiesta di preventivo in pochi clic. Registrati e compila il modulo di richiesta preventivo, allegando i tuoi documenti.',
    },
    'jc5geaau': {
      'fr': 'Poster la demande de devis est-il gratuite ?',
      'en': 'Is submitting a quote request free?',
      'es': '¿Es gratuito enviar una solicitud de cotización?',
      'it': 'L\'invio di una richiesta di preventivo è gratuito?',
    },
    '9m47wj5c': {
      'fr':
          'Oui, notre service est entièrement gratuit pour les particuliers. Vous ne payez rien pour recevoir des devis.',
      'en':
          'Yes, our service is completely free for individuals. You pay nothing to receive quotes.',
      'es':
          'Sí, nuestro servicio es completamente gratuito para particulares. No paga nada por recibir presupuestos.',
      'it':
          'Sì, il nostro servizio è completamente gratuito per i privati. Non pagherai nulla per ricevere preventivi.',
    },
    'zyqqr3hl': {
      'fr': 'Dans quelles régions intervenez-vous ?',
      'en': 'In which regions do you operate?',
      'es': '¿En qué regiones operas?',
      'it': 'In quali regioni operate?',
    },
    'k7sm6fug': {
      'fr':
          'Nous couvrons l\'ensemble du territoire français ainsi que plusieurs pays étangrers grace à nos partenaires. ',
      'en':
          'We cover the entire French territory as well as several foreign countries thanks to our partners.',
      'es':
          'Cubrimos todo el territorio francés así como varios países extranjeros gracias a nuestros socios.',
      'it':
          'Grazie ai nostri partner copriamo l\'intero territorio francese e anche diversi paesi esteri.',
    },
    '2wsqo3xg': {
      'fr': 'Demande de Devis',
      'en': 'Request for a Quote',
      'es': 'Solicitud de cotización',
      'it': 'Richiedi un preventivo',
    },
    'xhuhzqkg': {
      'fr': 'Combien de devis vais-je recevoir ?',
      'en': 'How many quotes will I receive?',
      'es': '¿Cuántas cotizaciones recibiré?',
      'it': 'Quanti preventivi riceverò?',
    },
    '6ghti0p8': {
      'fr':
          'Vous recevrez 2  devis: un avecc assurance standard, l\'autre avec assurance ad valorem. Cela vous permet de comparer les offres et de choisir la meilleure proposition.',
      'en':
          'You will receive two quotes: one with standard insurance, the other with ad valorem insurance. This allows you to compare the offers and choose the best one.',
      'es':
          'Recibirá dos cotizaciones: una con seguro estándar y otra con seguro ad valorem. Esto le permitirá comparar las ofertas y elegir la mejor.',
      'it':
          'Riceverai due preventivi: uno con assicurazione standard, l\'altro con assicurazione ad valorem. Questo ti permetterà di confrontare le offerte e scegliere la migliore.',
    },
    '4bkqogmp': {
      'fr': 'Sous quel délai vais-je recevoir les devis ?',
      'en': 'How long will it take to receive the quotes?',
      'es': '¿Cuanto tiempo tardaré en recibir las cotizaciones?',
      'it': 'Quanto tempo ci vorrà per ricevere i preventivi?',
    },
    '2m1h88d2': {
      'fr':
          'Les premiers devis arrivent généralement sous 24h. L\'ensemble des propositions vous parviennent sous 48h maximum après votre demande dans la plupart des cas.',
      'en':
          'Initial quotes are usually received within 24 hours. In most cases, you will receive all proposals within 48 hours of your request.',
      'es':
          'Las cotizaciones iniciales suelen recibirse en un plazo de 24 horas. En la mayoría de los casos, recibirá todas las propuestas en un plazo de 48 horas desde su solicitud.',
      'it':
          'I preventivi iniziali vengono solitamente ricevuti entro 24 ore. Nella maggior parte dei casi, riceverete tutte le proposte entro 48 ore dalla richiesta.',
    },
    '9k48md3l': {
      'fr': 'Puis-je modifier ma demande après envoi ?',
      'en': 'Can I modify my request after submitting it?',
      'es': '¿Puedo modificar mi solicitud después de enviarla?',
      'it': 'Posso modificare la mia richiesta dopo averla inviata?',
    },
    'gc31kg6m': {
      'fr':
          'Vous pouvez modifier votre demande en nous contactant à patir de votre espace devis',
      'en': 'You can modify your request by contacting us from your quote area',
      'es':
          'Puedes modificar tu solicitud contactándonos desde tu área de cotización',
      'it':
          'Puoi modificare la tua richiesta contattandoci dalla tua area preventivo',
    },
    'j2c1v5ja': {
      'fr': 'Que faire si je ne suis pas satisfait d\'un devis ?',
      'en': 'What should I do if I am not satisfied with a quote?',
      'es': '¿Qué debo hacer si no estoy satisfecho con una cotización?',
      'it': 'Cosa devo fare se non sono soddisfatto di un preventivo?',
    },
    'ljaxdi2j': {
      'fr':
          'Contactez-nous en cliquant sur le boutton contact à partir de votre devis',
      'en': 'Contact us by clicking the contact button on your quote.',
      'es':
          'Contáctanos haciendo clic en el botón de contacto en su cotización.',
      'it':
          'Contattaci cliccando sul pulsante \"Contattaci\" presente sul tuo preventivo.',
    },
    'jmvxwa72': {
      'fr': 'Compte et Données',
      'en': 'Account and Data',
      'es': 'Cuenta y datos',
      'it': 'Account e dati',
    },
    'zo9bpdpe': {
      'fr': 'Mes données personnelles sont-elles protégées ?',
      'en': 'Is my personal data protected?',
      'es': '¿Están protegidos mis datos personales?',
      'it': 'I miei dati personali sono protetti?',
    },
    'e8vmp2li': {
      'fr':
          'Absolument. Nous respectons le RGPD et ne partageons vos données qu\'avec les professionnels susceptibles de répondre à votre demande. Vos informations ne sont jamais vendues à des tiers.',
      'en':
          'Absolutely. We comply with the GDPR and only share your data with professionals who can respond to your request. Your information is never sold to third parties.',
      'es':
          'Por supuesto. Cumplimos con el RGPD y solo compartimos sus datos con profesionales que puedan responder a su solicitud. Su información nunca se vende a terceros.',
      'it':
          'Assolutamente sì. Rispettiamo il GDPR e condividiamo i tuoi dati solo con professionisti in grado di rispondere alla tua richiesta. Le tue informazioni non vengono mai vendute a terzi.',
    },
    'kpw97pqj': {
      'fr': 'Dois-je créer un compte pour faire une demande ?',
      'en': 'Do I need to create an account to make a request?',
      'es': '¿Necesito crear una cuenta para realizar una solicitud?',
      'it': 'Devo creare un account per effettuare una richiesta?',
    },
    'kp8zvasv': {
      'fr':
          'Oui, l\'inscription au compte pemet d\'éviter des sesies récurrente lors de la demande de devis et de sécuriser l\'acces à vos devis.',
      'en':
          'Yes, registering for an account helps avoid recurring logins when requesting quotes and secures access to your quotes.',
      'es':
          'Sí, registrarse para obtener una cuenta ayuda a evitar inicios de sesión recurrentes al solicitar cotizaciones y asegura el acceso a sus cotizaciones.',
      'it':
          'Sì, la registrazione di un account aiuta a evitare accessi ricorrenti quando si richiedono preventivi e garantisce l\'accesso ai propri preventivi.',
    },
    'mu696s4n': {
      'fr': 'Besoin d\'aide supplémentaire ?',
      'en': 'Need more help?',
      'es': '¿Necesitas más ayuda?',
      'it': 'Hai bisogno di ulteriore aiuto?',
    },
    'kgogt990': {
      'fr': 'Nous Contacter',
      'en': 'Contact Us',
      'es': 'Contáctenos',
      'it': 'Contattaci',
    },
    'og0njdeh': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    'wk36iwq5': {
      'fr': 'Accueil',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'it': 'Benvenuto',
    },
    'g7gqcb6m': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    'olbr13pq': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    'fi3inb9l': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'r1c3d180': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    '6wsjpnvu': {
      'fr': 'FAQ - Questions',
      'en': 'FAQ - Questions',
      'es': 'Preguntas frecuentes',
      'it': 'FAQ - Domande',
    },
    'g6jw3vow': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    '9mh0h31b': {
      'fr': 'Espace Personnel',
      'en': 'Personal Space',
      'es': 'Espacio personal',
      'it': 'Spazio personale',
    },
    'n0sphk8b': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'tqcl29o7': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
  },
  // Page_Contact-Devis
  {
    'e2px1giy': {
      'fr': 'Entrer en contact',
      'en': 'Get in touch',
      'es': 'Ponte en contacto con nosotros',
      'it': 'Contattaci',
    },
    'q064d1gc': {
      'fr':
          'Nous serions ravis d\'avoir de vos nouvelles.     Envoyez-nous un message et nous vous répondrons dans les plus brefs délais.',
      'en':
          'We would love to hear from you. Send us a message and we will get back to you as soon as possible.',
      'es':
          'Nos encantaría saber de usted. Envíenos un mensaje y nos pondremos en contacto con usted lo antes posible.',
      'it':
          'Ci piacerebbe sentire la tua opinione. Inviaci un messaggio e ti risponderemo il prima possibile.',
    },
    'p61wm31g': {
      'fr': 'Envoyez-nous un courriel',
      'en': 'Send us an email',
      'es': 'Envíanos un correo electrónico',
      'it': 'Inviaci un\'e-mail',
    },
    '8gz1mb9f': {
      'fr': 'Contact@expedion-encheres.com',
      'en': 'Contact@expedion-encheres.com',
      'es': 'Contacto@expedion-encheres.com',
      'it': 'Contact@expedion-encheres.com',
    },
    'drm01ryv': {
      'fr': 'Envoyez-nous un message',
      'en': 'Send us a message',
      'es': 'Envíanos un mensaje',
      'it': 'Inviaci un messaggio',
    },
    '17nyx3cx': {
      'fr': 'Message',
      'en': 'Message',
      'es': 'Mensaje',
      'it': 'Messaggio',
    },
    '83k2mpty': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'acqi7789': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'hp2oekpu': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    '30e6ib1p': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    'hkekai6y': {
      'fr': 'Email',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    'u976gtkc': {
      'fr': 'Email ',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    'c9ozgqsf': {
      'fr': 'Devis concerné',
      'en': 'Quote concerned',
      'es': 'Cita en cuestión',
      'it': 'Citazione interessata',
    },
    '45cppf8h': {
      'fr': 'Email ',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    'wszwhoy7': {
      'fr': 'Sujet',
      'en': 'Subject',
      'es': 'Sujeto',
      'it': 'Soggetto',
    },
    'aeqo7n8f': {
      'fr': 'Sujet',
      'en': 'Subject',
      'es': 'Sujeto',
      'it': 'Soggetto',
    },
    'gy8djmug': {
      'fr': 'votre message...',
      'en': 'your message...',
      'es': 'tu mensaje...',
      'it': 'il tuo messaggio...',
    },
    'w50p7tv7': {
      'fr': 'Envoyer un Message',
      'en': 'Send a message',
      'es': 'Enviar un mensaje',
      'it': 'Invia un messaggio',
    },
    'hgmab94n': {
      'fr': 'Appelez-nous',
      'en': 'Call us',
      'es': 'Llámanos',
      'it': 'Chiamaci',
    },
    'yyw47uyu': {
      'fr': '07 74 31 96 74',
      'en': '07 74 31 96 74',
      'es': '07 74 31 96 74',
      'it': '07 74 31 96 74',
    },
    'kc10mk8f': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
  },
  // Page_Validation_Devis
  {
    'tfabeimg': {
      'fr': 'EXPEDION',
      'en': 'EXPEDION',
      'es': 'EXPEDION',
      'it': 'EXPEDION',
    },
    '1nwaxghw': {
      'fr': 'Accueil',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'it': 'Benvenuto',
    },
    'cp2u3llk': {
      'fr': 'Demander un devis',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    '1h5fypr5': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    '6znmeqrh': {
      'fr': 'Parametres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'dleq159c': {
      'fr': 'Mes paiement',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    'ytgtqast': {
      'fr': 'FAQ - Questions',
      'en': 'FAQ - Questions',
      'es': 'Preguntas frecuentes',
      'it': 'FAQ - Domande',
    },
    '3krmts93': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    '1npb75tj': {
      'fr': 'Espace Personnel',
      'en': 'Personal Space',
      'es': 'Espacio personal',
      'it': 'Spazio personale',
    },
    'yt0bpi5b': {
      'fr': 'Deconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'it': 'Esci',
    },
    'duf66qd4': {
      'fr': 'se connecter',
      'en': 'log in',
      'es': 'acceso',
      'it': 'login',
    },
    'dbgkl39t': {
      'fr': 'Choisissez votre assurance',
      'en': 'Choose your insurance',
      'es': 'Elige tu seguro',
      'it': 'Scegli la tua assicurazione',
    },
    'jiu8q7xp': {
      'fr':
          'Sélectionnez le type d\'assurance qui correspond le mieux à vos besoins',
      'en': 'Select the type of insurance that best suits your needs',
      'es':
          'Selecciona el tipo de seguro que mejor se adapta a tus necesidades',
      'it':
          'Seleziona la tipologia di assicurazione più adatta alle tue esigenze',
    },
    'ip6ahqx8': {
      'fr': 'Devis avec assurance',
      'en': 'Quote with insurance',
      'es': 'Cotización con seguro',
      'it': 'Preventivo con assicurazione',
    },
    'hzstbv4q': {
      'fr': 'Advalorem',
      'en': 'Advalorem',
      'es': 'Advalorem',
      'it': 'Advalorem',
    },
    'rwfkh9cj': {
      'fr':
          'Couverture complète avec protection maximale de vos biens selon leur valeur réelle',
      'en':
          'Comprehensive coverage with maximum protection for your belongings based on their actual value',
      'es':
          'Cobertura integral con máxima protección para tus pertenencias en función de su valor real',
      'it':
          'Copertura completa con la massima protezione per i tuoi beni in base al loro valore effettivo',
    },
    'uw33xcm9': {
      'fr': 'Prix:',
      'en': 'Price:',
      'es': 'Precio:',
      'it': 'Prezzo:',
    },
    '0xqyb9wk': {
      'fr': 'Devis avec assurance',
      'en': 'Quote with insurance',
      'es': 'Cotización con seguro',
      'it': 'Preventivo con assicurazione',
    },
    '99pols2d': {
      'fr': 'Standard',
      'en': 'Standard',
      'es': 'Estándar',
      'it': 'Standard',
    },
    'bd7vyssm': {
      'fr':
          'Protection de base avec couverture standard pour vos biens essentiels',
      'en':
          'Basic protection with standard coverage for your essential belongings',
      'es':
          'Protección básica con cobertura estándar para sus pertenencias esenciales',
      'it':
          'Protezione di base con copertura standard per i tuoi beni essenziali',
    },
    'mut8vfyk': {
      'fr': 'Prix:',
      'en': 'Price:',
      'es': 'Precio:',
      'it': 'Prezzo:',
    },
    '1mitwq8y': {
      'fr': 'Payer',
      'en': 'Pay',
      'es': 'Pagar',
      'it': 'Paga',
    },
    'exitny41': {
      'fr': 'Confirmer devis',
      'en': 'Confirm quote',
      'es': 'Confirmar cotización',
      'it': 'Conferma preventivo',
    },
  },
  // PageAdresseclient
  {
    'tfjmp6qx': {
      'fr': 'Adresse personnelle',
      'en': 'Personal address',
      'es': 'Dirección personal',
      'it': 'Indirizzo personale',
    },
    'wkaztvyr': {
      'fr':
          'Veuillez nous communiquer vos coordonnées complètes afin que nous puissions mieux vous servir et garantir une livraison précise.',
      'en':
          'Please provide us with your full contact details so that we can better serve you and ensure accurate delivery.',
      'es':
          'Proporciónenos sus datos de contacto completos para que podamos brindarle un mejor servicio y garantizar una entrega precisa.',
      'it':
          'Vi preghiamo di fornirci i vostri dati di contatto completi, così potremo servirvi al meglio e garantire una consegna accurata.',
    },
    'ojgwt4ri': {
      'fr': 'Adresse  L1 *',
      'en': 'Address L1 *',
      'es': 'Dirección L1 *',
      'it': 'Indirizzo L1 *',
    },
    'qn85effq': {
      'fr': 'Adresse  L1 *',
      'en': 'Address L1 *',
      'es': 'Dirección L1 *',
      'it': 'Indirizzo L1 *',
    },
    'wndmaz1m': {
      'fr': 'Adresse L2',
      'en': 'Address L2',
      'es': 'Dirección L2',
      'it': 'Indirizzo L2',
    },
    'vu3qv280': {
      'fr': 'Adresse L2',
      'en': 'Address L2',
      'es': 'Dirección L2',
      'it': 'Indirizzo L2',
    },
    '62zns9cm': {
      'fr': 'Code postal*',
      'en': 'Postal code*',
      'es': 'Código Postal*',
      'it': 'Codice Postale*',
    },
    'jbtyq4sm': {
      'fr': 'Code postal*',
      'en': 'Postal code*',
      'es': 'Código Postal*',
      'it': 'Codice Postale*',
    },
    '7ch4wed1': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    'm14jj3ib': {
      'fr': 'Ville*',
      'en': 'City*',
      'es': 'Ciudad*',
      'it': 'Città*',
    },
    '1n487ra9': {
      'fr': 'Pays*',
      'en': 'Country*',
      'es': 'País*',
      'it': 'Paese*',
    },
    '21xs2xnr': {
      'fr': 'Pays*',
      'en': 'Country*',
      'es': 'País*',
      'it': 'Paese*',
    },
    '0j7ynz7n': {
      'fr': 'Téléphone*',
      'en': 'Phone*',
      'es': 'Teléfono*',
      'it': 'Telefono*',
    },
    'vhszjq26': {
      'fr': 'Téléphone*',
      'en': 'Phone*',
      'es': 'Teléfono*',
      'it': 'Telefono*',
    },
    'uyp63kfc': {
      'fr': 'utiliser la même adresse \npour la livraison.',
      'en': 'use the same address for delivery.',
      'es': 'Utilice la misma dirección para la entrega.',
      'it': 'utilizzare lo stesso indirizzo per la consegna.',
    },
    'oc5bay01': {
      'fr': 'Adresse livraison L1 *',
      'en': 'Delivery address L1 *',
      'es': 'Dirección de entrega L1 *',
      'it': 'Indirizzo di consegna L1 *',
    },
    'u8n74jrr': {
      'fr': 'Adresse livraison L1 *',
      'en': 'Delivery address L1 *',
      'es': 'Dirección de entrega L1 *',
      'it': 'Indirizzo di consegna L1 *',
    },
    'wx6il7ly': {
      'fr': 'Adresse livraison L2',
      'en': 'Delivery address L2',
      'es': 'Dirección de entrega L2',
      'it': 'Indirizzo di consegna L2',
    },
    '55pvbjdb': {
      'fr': 'Adresse livraison L2',
      'en': 'Delivery address L2',
      'es': 'Dirección de entrega L2',
      'it': 'Indirizzo di consegna L2',
    },
    '3nunts1u': {
      'fr': 'Code postal*',
      'en': 'Postal code*',
      'es': 'Código Postal*',
      'it': 'Codice Postale*',
    },
    'zt6x7da0': {
      'fr': 'Code postal livraison*',
      'en': 'Delivery postal code*',
      'es': 'Código postal de entrega*',
      'it': 'Codice postale di consegna*',
    },
    'twn1ic93': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    'v4v2pn4v': {
      'fr': 'Ville livraison*',
      'en': 'Delivery city*',
      'es': 'Ciudad de entrega*',
      'it': 'Città di consegna*',
    },
    '859ln7mt': {
      'fr': 'Pays livraison*',
      'en': 'Delivery country*',
      'es': 'País de entrega*',
      'it': 'Paese di consegna*',
    },
    'z2vtupxx': {
      'fr': 'Pays livraison*',
      'en': 'Delivery country*',
      'es': 'País de entrega*',
      'it': 'Paese di consegna*',
    },
    'el181z51': {
      'fr': 'Téléphone livraison*',
      'en': 'Telephone delivery*',
      'es': 'Entrega telefónica*',
      'it': 'Consegna telefonica*',
    },
    'az1bctwc': {
      'fr': 'Téléphone livraison*',
      'en': 'Telephone delivery*',
      'es': 'Entrega telefónica*',
      'it': 'Consegna telefonica*',
    },
    'f6p8b9j8': {
      'fr': 'utiliser la même adresse \npour la livraison.',
      'en': 'use the same address for delivery.',
      'es': 'Utilice la misma dirección para la entrega.',
      'it': 'utilizzare lo stesso indirizzo per la consegna.',
    },
    '6nav2g93': {
      'fr': 'Valider',
      'en': 'To validate',
      'es': 'Para validar',
      'it': 'Per convalidare',
    },
    '77j5kki1': {
      'fr': 'Adressee',
      'en': 'Address',
      'es': 'DIRECCIÓN',
      'it': 'Indirizzo',
    },
  },
  // Mot-de-passe-oublie
  {
    'q09zvo77': {
      'fr': 'Récuperation du mot de passe',
      'en': 'Password recovery',
      'es': 'Recuperación de contraseña',
      'it': 'Recupero password',
    },
    '0tp7ipb0': {
      'fr': 'Saisissez votre adresse e-mail pour récupérer votre mot de passe',
      'en': 'Enter your email address to recover your password',
      'es':
          'Introduce tu dirección de correo electrónico para recuperar tu contraseña',
      'it': 'Inserisci il tuo indirizzo email per recuperare la password',
    },
    'sdu4u5nj': {
      'fr': 'Email',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    '1nh1gbv5': {
      'fr': 'Entrez votre  email',
      'en': 'Enter your email',
      'es': 'Introduce tu correo electrónico',
      'it': 'Inserisci la tua email',
    },
    'jg09rvz8': {
      'fr': 'Envoyer le lien',
      'en': 'Send the link',
      'es': 'Envía el enlace',
      'it': 'Invia il link',
    },
    '9v2az1dv': {
      'fr': 'Mot de passe oublié',
      'en': 'Forgot your password?',
      'es': '¿Olvidaste tu contraseña?',
      'it': 'Hai dimenticato la password?',
    },
  },
  // DETAILS_DEVIS
  {
    '2tcs8wxj': {
      'fr': 'Demande de devis #DV-2024-0847',
      'en': 'Quote Request #DV-2024-0847',
      'es': 'Solicitud de cotización #DV-2024-0847',
      'it': 'Richiesta di preventivo n. DV-2024-0847',
    },
    '0uf64zu3': {
      'fr': 'Informations personnelles',
      'en': 'Personal information',
      'es': 'Información personal',
      'it': 'Informazioni personali',
    },
    '35zej3bs': {
      'fr': 'Prénom',
      'en': 'First name',
      'es': 'Nombre de pila',
      'it': 'Nome',
    },
    'd4w3si1o': {
      'fr': 'Nom',
      'en': 'Name',
      'es': 'Nombre',
      'it': 'Nome',
    },
    'z5bviqcf': {
      'fr': 'E-mail',
      'en': 'E-mail',
      'es': 'Correo electrónico',
      'it': 'E-mail',
    },
    'q6353rhr': {
      'fr': 'Téléphone',
      'en': 'Phone',
      'es': 'Teléfono',
      'it': 'Telefono',
    },
    'miiq4ryb': {
      'fr': 'En tant que particulier que souhaitez-vous ?',
      'en': 'As an individual, what do you want?',
      'es': 'Como individuo, ¿qué deseas?',
      'it': 'Come individuo, cosa desideri?',
    },
    'nejzhu3n': {
      'fr': 'Transport d\'œuvre d\'art après achat aux enchères',
      'en': 'Transporting artwork after auction purchase',
      'es': 'Transporte de obras de arte después de la compra en subasta',
      'it': 'Trasporto di opere d\'arte dopo l\'acquisto all\'asta',
    },
    'hwl8hemh': {
      'fr': 'Assurance ad valorem',
      'en': 'Ad valorem insurance',
      'es': 'Seguro ad valorem',
      'it': 'Assicurazione ad valorem',
    },
    'soc0zir0': {
      'fr': 'Informations de retrait',
      'en': 'Withdrawal information',
      'es': 'Información de retiro',
      'it': 'Informazioni sul prelievo',
    },
    'x74nkf4r': {
      'fr': 'Adresse de retrait',
      'en': 'Collection address',
      'es': 'Dirección de recogida',
      'it': 'Indirizzo di ritiro',
    },
    'lr3i6vdu': {
      'fr': 'Code postal',
      'en': 'Postal code',
      'es': 'Código Postal',
      'it': 'Codice Postale',
    },
    'nahezgbz': {
      'fr': 'Lieu de retrait',
      'en': 'Pick-up location',
      'es': 'Lugar de recogida',
      'it': 'Luogo di ritiro',
    },
    '3wkkxy3h': {
      'fr': 'Nom de la maison de ventes',
      'en': 'Name of the auction house',
      'es': 'Nombre de la casa de subastas',
      'it': 'Nome della casa d\'aste',
    },
    'k5sui0p8': {
      'fr': 'Téléphone de retrait',
      'en': 'Withdrawal phone',
      'es': 'Teléfono de retiro',
      'it': 'Telefono per il prelievo',
    },
    '91oy6m05': {
      'fr': 'Informations marchandise',
      'en': 'Product information',
      'es': 'Información del producto',
      'it': 'Informazioni sul prodotto',
    },
    'kjgrnad4': {
      'fr': 'Montant',
      'en': 'Amount',
      'es': 'Cantidad',
      'it': 'Quantità',
    },
    'd3o7y2qv': {
      'fr': 'Tranche de tarif',
      'en': 'Price range',
      'es': 'Gama de precios',
      'it': 'Fascia di prezzo',
    },
    '9extqqvb': {
      'fr': 'Date de vente',
      'en': 'Sale date',
      'es': 'Fecha de venta',
      'it': 'Data di vendita',
    },
    'uynfvd0v': {
      'fr': 'N° Bordereau',
      'en': 'Slip No.',
      'es': 'No. de resbalón',
      'it': 'Numero di scontrino',
    },
    'ejv9lz64': {
      'fr': 'Bordereau acquitté',
      'en': 'Paid receipt',
      'es': 'Recibo de pago',
      'it': 'ricevuta di pagamento',
    },
    'obqbr1zb': {
      'fr': 'Description de l\'objet',
      'en': 'Description of the item',
      'es': 'Descripción del artículo',
      'it': 'Descrizione dell\'oggetto',
    },
    'oi2g8exv': {
      'fr': 'Dimensions',
      'en': 'Dimensions',
      'es': 'Dimensiones',
      'it': 'Dimensioni',
    },
    'sjwmyevo': {
      'fr': 'Longueur',
      'en': 'Length',
      'es': 'Longitud',
      'it': 'Lunghezza',
    },
    'q45p6r0t': {
      'fr': 'Largeur',
      'en': 'Width',
      'es': 'Ancho',
      'it': 'Larghezza',
    },
    'upd39nsv': {
      'fr': 'Hauteur',
      'en': 'Height',
      'es': 'Altura',
      'it': 'Altezza',
    },
    'aoy5b0ec': {
      'fr': 'Poids',
      'en': 'Weight',
      'es': 'Peso',
      'it': 'Peso',
    },
    'tpqbwndu': {
      'fr': 'Objet protégé/emballé',
      'en': 'Item protected/packaged',
      'es': 'Artículo protegido/empaquetado',
      'it': 'Articolo protetto/confezionato',
    },
    '58fcahn5': {
      'fr': 'Images de l\'objet',
      'en': 'Images of the object',
      'es': 'Imágenes del objeto',
      'it': 'Immagini dell\'oggetto',
    },
    'bs1advyl': {
      'fr': 'Informations de livraison',
      'en': 'Delivery information',
      'es': 'Información de entrega',
      'it': 'Informazioni sulla consegna',
    },
    '2b5kixqk': {
      'fr': 'Adresse de livraison',
      'en': 'Delivery address',
      'es': 'Dirección de entrega',
      'it': 'Indirizzo di consegna',
    },
    '2y20x7w3': {
      'fr': 'Appartement 4B',
      'en': 'Apartment 4B',
      'es': 'Apartamento 4B',
      'it': 'Appartamento 4B',
    },
    'nojmqn1n': {
      'fr': 'Code postal',
      'en': 'Postal code',
      'es': 'Código Postal',
      'it': 'Codice Postale',
    },
    'r4vg4qzq': {
      'fr': 'Ville',
      'en': 'City',
      'es': 'Ciudad',
      'it': 'Città',
    },
    '4g0oyrzr': {
      'fr': 'Pays',
      'en': 'Country',
      'es': 'País',
      'it': 'Paese',
    },
    's0vww1fc': {
      'fr': 'Téléphone',
      'en': 'Phone',
      'es': 'Teléfono',
      'it': 'Telefono',
    },
    'fvp6mf12': {
      'fr': 'Nom du destinataire',
      'en': 'Recipient\'s name',
      'es': 'Nombre del destinatario',
      'it': 'Nome del destinatario',
    },
    'xeed6hff': {
      'fr': 'Commentaire',
      'en': 'Comment',
      'es': 'Comentario',
      'it': 'Commento',
    },
    'mel9blgw': {
      'fr': 'Conditions générales',
      'en': 'General terms and conditions',
      'es': 'Términos y condiciones generales',
      'it': 'Termini e condizioni generali',
    },
    'mk3iroon': {
      'fr': 'Statut de la demande',
      'en': 'Application status',
      'es': 'Estado de la solicitud',
      'it': 'Stato dell\'applicazione',
    },
    '4w9ok6n9': {
      'fr':
          'Demande de devis en cours de traitement. Vous recevrez une réponse sous 24h ouvrées.',
      'en':
          'Your quote request is being processed. You will receive a response within 24 business hours.',
      'es':
          'Su solicitud de cotización está siendo procesada. Recibirá una respuesta en 24 horas hábiles.',
      'it':
          'La tua richiesta di preventivo è in fase di elaborazione. Riceverai una risposta entro 24 ore lavorative.',
    },
  },
  // ListeAPPBAR
  {
    'nfdne1z8': {
      'fr': 'Accueil',
      'en': 'Welcome',
      'es': 'Bienvenido',
      'it': 'Benvenuto',
    },
    'h29o6hk2': {
      'fr': 'Espace Personnel',
      'en': 'Personal Space',
      'es': 'Espacio personal',
      'it': 'Spazio personale',
    },
    '6tsupowt': {
      'fr': 'Mes devis',
      'en': 'My quotes',
      'es': 'Mis citas',
      'it': 'Le mie citazioni',
    },
    'vv0if3vm': {
      'fr': 'Demander un devis ',
      'en': 'Request a quote',
      'es': 'Solicitar cotización',
      'it': 'Richiedi un preventivo',
    },
    '5w0v18l1': {
      'fr': 'Mes paiements',
      'en': 'My payments',
      'es': 'Mis pagos',
      'it': 'I miei pagamenti',
    },
    '37jg5lmc': {
      'fr': 'Contact',
      'en': 'Contact',
      'es': 'Contacto',
      'it': 'Contatto',
    },
    'e83ve2tk': {
      'fr': 'Paramètres',
      'en': 'Settings',
      'es': 'Ajustes',
      'it': 'Impostazioni',
    },
    'hk3cws7m': {
      'fr': 'FAQ - Questions',
      'en': 'FAQ - Questions',
      'es': 'Preguntas frecuentes',
      'it': 'FAQ - Domande',
    },
  },
  // PAIEMENT
  {
    'n3ol74je': {
      'fr': 'Quote #QT-2024-001',
      'en': 'Quote #QT-2024-001',
      'es': 'Cita #QT-2024-001',
      'it': 'Citazione #QT-2024-001',
    },
    'pseoz70f': {
      'fr': 'Total Amount',
      'en': 'Total Amount',
      'es': 'Importe total',
      'it': 'Importo totale',
    },
    '8h8o1tds': {
      'fr': 'Valid until: March 15, 2024',
      'en': 'Valid until: March 15, 2024',
      'es': 'Válido hasta: 15 de marzo de 2024',
      'it': 'Valido fino al: 15 marzo 2024',
    },
    '46x3yoxv': {
      'fr': 'Payer',
      'en': 'Pay',
      'es': 'Pagar',
      'it': 'Paga',
    },
  },

  // Miscellaneous
  {
    'r1mwdjgu': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'w2y2ka2l': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    '5eyu3lf6': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'ei4qkbcd': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    't9w8y2m7': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'cn7v83ia': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'oy2u58ly': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'jqoqwe0x': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'lvcfmgyw': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'arv94dej': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'nqexm4wn': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'se46dyo3': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'xtgm34sa': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    '57blx629': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'zh30n4d0': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'hk3dqvut': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'vjz8uq0u': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'bm1a38w6': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'tb0ea373': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'ndzkicpt': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    '54dlmg59': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'cniqopww': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'xe09yg52': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'kye9c3sb': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    '1bs17nw9': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'svrdspze': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
    'qmcbxu0w': {
      'fr': '',
      'en': '',
      'es': '',
      'it': '',
    },
  },
].reduce((a, b) => a..addAll(b));
