import 'package:flutter/widgets.dart';

import 'package:app/data/models/partner.dart';
import 'package:app/l10n/app_localizations.dart';

/// Maps the canonical (English) taxonomy values stored on Firestore to
/// the locale-specific labels shown in the UI.
///
/// The taxonomy values themselves (`'Hetero'`, `'MMF'`, `'Soft Swap'`,
/// etc.) stay English in the database so backend logic, filters, and
/// indexes don't break when the user switches languages. Only the
/// DISPLAY layer translates. Client feedback 2026-05-25: "los
/// intereses no cambian de idioma — deben traducirse completamente
/// entre español e inglés."
///
/// Falls back to the raw value if no translation is wired for a given
/// option — never throws, so new taxonomy values added later still
/// render until someone fills in the localization.
class DynamicsLabels {
  DynamicsLabels._();

  /// Translates a single taxonomy value into the user's current locale.
  /// Pass the value as stored on Firestore (English).
  static String localize(String value, AppLocalizations l10n) {
    switch (value) {
      // Identity
      case PartnerIdentities.hetero:
        return l10n.dynValHetero;
      case PartnerIdentities.biCurious:
        return l10n.dynValBiCurious;
      case PartnerIdentities.bi:
        return l10n.dynValBi;
      // Role
      case PartnerRoles.dom:
        return l10n.dynValDom;
      case PartnerRoles.sub:
        return l10n.dynValSub;
      case PartnerRoles.switchRole:
        return l10n.dynValSwitch;
      // Interaction
      case CoupleInteractionTypes.parallelPlay:
        return l10n.dynValParallelPlay;
      case CoupleInteractionTypes.softSwap:
        return l10n.dynValSoftSwap;
      case CoupleInteractionTypes.fullSwap:
        return l10n.dynValFullSwap;
      // Experience
      case CoupleExperiences.sameRoom:
        return l10n.dynValSameRoom;
      case CoupleExperiences.separateRoom:
        return l10n.dynValSeparateRoom;
      case CoupleExperiences.voyeur:
        return l10n.dynValVoyeur;
      case CoupleExperiences.exhibition:
        return l10n.dynValExhibition;
      // Dynamic interests
      case CoupleDynamicInterests.mmf:
        return l10n.dynValMmf;
      case CoupleDynamicInterests.ffm:
        return l10n.dynValFfm;
      case CoupleDynamicInterests.groupPlay:
        return l10n.dynValGroupPlay;
      case CoupleDynamicInterests.bdsm:
        return l10n.dynValBdsm;
      case CoupleDynamicInterests.roleplay:
        return l10n.dynValRoleplay;
      default:
        return value;
    }
  }

  /// Convenience: looks up the [BuildContext]'s localizations.
  static String of(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return value;
    return localize(value, l10n);
  }
}
