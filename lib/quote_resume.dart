import '/backend/quote_draft.dart';
import '/index.dart';

/// Where a visitor carrying a landing-page draft should be dropped once they
/// are signed in.
///
/// `ChoixDevisWidget` exists to ask one question — *do you have the auction
/// house's slip as a PDF?* — and a staged draft has already answered it, by
/// carrying the slip or by carrying the addresses typed instead. Putting the
/// fork in front of someone who has just filled in the landing page asks them
/// to choose a route they have already taken, and the wrong choice sends them
/// to a form that shows none of their answers.
///
/// With no draft — someone arriving from the nav rather than from a form —
/// the fork is exactly right, and that is what this returns.
String quoteDraftResumeRoute(QuoteDraft? draft) => switch (draft?.resume) {
      QuoteDraftResume.bordereau =>
        FormulaireDeDevisParBordereauWidget.routeName,
      QuoteDraftResume.manual =>
        FormulaireDemandeDeDevisRetraitAuxEncheresWidget.routeName,
      null => ChoixDevisWidget.routeName,
    };
