# ES Translation Audit — hardcoded English strings

> Client feedback on 2026-04-23 flagged "idiomas mezclados" — mixed
> languages in the app. This doc enumerates every hardcoded English
> `Text(...)` widget found across the user-facing Flutter code, groups
> them by priority, and captures the proposed Spanish translations so
> we can ship them in one ARB batch.
>
> Admin app (lib/admin/) is excluded — it's internal-only and can stay
> English until the client decides otherwise.
>
> Generated: 2026-04-25.

---

## Priority buckets

- **P0** — Visible to the end user on the main flow (Profile, Feed,
  Chat, Filters, Inbox, Trips). Must be translated before the next
  APK for the client.
- **P1** — Secondary surfaces (Settings, Security, Report,
  Verification intro text). Translate in the next ARB batch.
- **P2** — Error snackbars and edge cases. Translate before store
  submission, not urgent for the validation APK.

---

## P0 — User-facing main flows

| File : line | English | Proposed Spanish |
|---|---|---|
| [couples_option.dart:186](../lib/presentation/pages/couples/couples_option.dart#L186) | `Blocked ${his} & ${her}` | `Bloqueaste a ${his} y ${her}` |
| [couples_option.dart:191](../lib/presentation/pages/couples/couples_option.dart#L191) | `Could not block: $e` | `No se pudo bloquear: $e` |
| [couples_option.dart:205](../lib/presentation/pages/couples/couples_option.dart#L205) | `Thanks — the report will be reviewed by our team.` | `Gracias — nuestro equipo revisará el reporte.` |
| [couples_option.dart:240](../lib/presentation/pages/couples/couples_option.dart#L240) | `Request sent to $displayName` | `Solicitud enviada a $displayName` |
| [couples_option.dart:338](../lib/presentation/pages/couples/couples_option.dart#L338) | `Retry` | `Reintentar` |
| [filters_screen.dart:139,162](../lib/presentation/pages/filters/filters_screen.dart#L139) | `Reset` | `Restablecer` |
| [filters_screen.dart:149](../lib/presentation/pages/filters/filters_screen.dart#L149) | `Filters` | `Filtros` |
| [filters_screen.dart:186](../lib/presentation/pages/filters/filters_screen.dart#L186) | `Min 5 km` | `Mín 5 km` |
| [filters_screen.dart:212-214](../lib/presentation/pages/filters/filters_screen.dart#L212) | `Min ${n}` / `Max ${n}` | `Mín ${n}` / `Máx ${n}` |
| [filters_screen.dart:592](../lib/presentation/pages/filters/filters_screen.dart#L592) | `Select Resort or Cruise` | `Selecciona un resort o crucero` |
| [filters_screen.dart:596](../lib/presentation/pages/filters/filters_screen.dart#L596) | `Any destination` | `Cualquier destino` |
| [inbox/message_request_preview_screen.dart:94](../lib/presentation/pages/inbox/message_request_preview_screen.dart#L94) | `Message request` | `Solicitud de mensaje` |
| [inbox/message_request_preview_screen.dart:178](../lib/presentation/pages/inbox/message_request_preview_screen.dart#L178) | `Dismiss` | `Descartar` |
| [inbox/message_requests_section.dart:93](../lib/presentation/pages/inbox/message_requests_section.dart#L93) | `Sender profile unavailable` | `Perfil del remitente no disponible` |
| [chat_screen.dart:300](../lib/presentation/pages/chat/chat_screen.dart#L300) | `Report couple` | `Reportar pareja` |
| [chat_screen.dart:328](../lib/presentation/pages/chat/chat_screen.dart#L328) | `Could not load couple profile` | `No se pudo cargar el perfil de la pareja` |
| [community_option.dart:808-813](../lib/presentation/pages/community/community_option.dart#L808) | `Gallery` / `Camera` | `Galería` / `Cámara` |
| [profile_setup_screen.dart:414](../lib/presentation/pages/profile_setup/profile_setup_screen.dart#L414) | `Main` | `Principal` |

**Count: ~20 strings.**

---

## P1 — Secondary surfaces

| File : line | English | Proposed Spanish |
|---|---|---|
| [security_screen.dart:23](../lib/presentation/pages/security/security_screen.dart#L23) | `Not signed in` | `Sesión no iniciada` |
| [security_screen.dart:29](../lib/presentation/pages/security/security_screen.dart#L29) | `Security` | `Seguridad` |
| [security_screen.dart:39](../lib/presentation/pages/security/security_screen.dart#L39) | `Could not load: ${err}` | `No se pudo cargar: ${err}` |
| [security_screen.dart:101](../lib/presentation/pages/security/security_screen.dart#L101) | `Unblock failed: $e` | `Desbloqueo fallido: $e` |
| [security_screen.dart:147](../lib/presentation/pages/security/security_screen.dart#L147) | `Unblock` | `Desbloquear` |
| [settings/account_settings_screen.dart:19](../lib/presentation/pages/settings/account_settings_screen.dart#L19) | `Account settings` | `Ajustes de cuenta` |
| [settings/account_settings_screen.dart:29](../lib/presentation/pages/settings/account_settings_screen.dart#L29) | `Change password` | `Cambiar contraseña` |
| [settings/account_settings_screen.dart:30](../lib/presentation/pages/settings/account_settings_screen.dart#L30) | `Coming soon` | `Próximamente` |
| [report_screen.dart:73](../lib/presentation/pages/report/report_screen.dart#L73) | `Report submitted` | `Reporte enviado` |
| [report_screen.dart:88](../lib/presentation/pages/report/report_screen.dart#L88) | `Report couple` | `Reportar pareja` |
| [report_screen.dart:157](../lib/presentation/pages/report/report_screen.dart#L157) | `Block this couple too` | `Bloquear también a esta pareja` |
| [manage_trips_screen.dart](../lib/presentation/pages/trips/manage_trips_screen.dart) | `Manage trips`, `Add trip`, `Explore More Trips`, `No trips yet.\nTap "Add trip"...` | `Gestionar viajes`, `Añadir viaje`, `Explorar más viajes`, `Todavía no hay viajes. Toca "Añadir viaje" para obtener tu primera coincidencia.` |
| [subscription/paywall_screen.dart](../lib/presentation/pages/subscription/paywall_screen.dart) | (all internal — already Spanish) | N/A |
| [subscription/my_subscription_screen.dart](../lib/presentation/pages/subscription/my_subscription_screen.dart) | (all internal — already Spanish) | N/A |

**Count: ~12 strings.**

---

## P2 — Error snackbars and edge cases

A rough list (see the grep output in the PR description). These are
user-visible but typically appear only on failure paths:

- `Sign out` buttons in admin-adjacent places
- `Retry` / `Cancel` dialog actions
- Snackbar content for rare failure modes (upload failed, network
  timeout, etc.)

Roll these into the same ARB batch as P1 — the translation cost is
trivial once we're editing the file.

**Count: ~15 strings.**

---

## How to land the fix in one batch

1. **Add the new keys to the ARB files:**
   - `lib/l10n/app_en.arb`
   - `lib/l10n/app_es.arb`

2. **Regenerate delegates:** `flutter gen-l10n`

3. **Replace each `Text('English literal')` with
   `Text(AppLocalizations.of(context)!.newKey)`.**

4. **Keep chat suggestions in sync** — they were the Week 5 i18n
   pass; same pattern works.

5. **Guard rails:** add a lint rule to `analysis_options.yaml` that
   flags hardcoded `Text('...')` over a capital letter outside of
   test files. Optional but prevents regressions.

---

## Out of scope

Two categories of string are deliberately NOT audited:

- **`lib/admin/`** — internal moderation panel. Bilingual treatment
  is overkill for an internal tool; Alejandra and moderators can
  operate it in English.
- **Placeholder / dev copy** — e.g. `TODO` strings or debug hints.
  Those disappear before submission anyway.

---

**End of i18n audit.**
