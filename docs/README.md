# AFFINITY — Project Documentation

> Gabriel's working knowledge base for the Affinity project
> Read these documents before starting any development session

---

## 📚 Documents in This Folder

### Start here
- **[PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)**
  High-level project identity, client info, contract status, tech stack, timeline, risks.
  *Read first if you're returning to the project after a break.*

### Reference
- **[CHAT_HISTORY.md](./CHAT_HISTORY.md)**
  Complete record of all client conversations from initial bid through contract signing. Every negotiation phase documented chronologically.

- **[DECISIONS_LOG.md](./DECISIONS_LOG.md)**
  Every final decision made during the 8-point negotiation. Reference this whenever you need to recall what was agreed on a specific feature.

- **[TECHNICAL_SPEC.md](./TECHNICAL_SPEC.md)**
  Detailed technical specifications for all 8 features + supporting infrastructure (data migration, Riverpod introduction, pagination, push notifications, security rules, Google Places integration).

- **[CODE_ANALYSIS.md](./CODE_ANALYSIS.md)**
  Analysis of the source code received from the DEV team. Current state, gaps vs agreed features, critical issues, DEV's strengths to preserve.

### External Documents
- **`D:\BID\CONDICIONES GENERALES DEL PROYECTO "Affinity".pdf`**
  The formal contract base document signed with the client.

---

## 🎯 Quick Status

- **Client:** Alejandra (Workana, non-technical, email `affinitysocialclub@gmail.com`)
- **App:** Affinity (lifestyle dating app for couples, Flutter + Firebase)
- **Contract:** ✅ Active, USD 3,066.78, 5 weeks
- **Collaboration:** Gabriel works locally, integrates later (DEV does Phase 2 in parallel)
- **Payment:** 100% on final delivery (Workana escrow)
- **Current phase:** Week 1 — Data migration + Google Places + Forgot Password + Account Deletion

---

## 🗂️ Project Structure Context

```
D:\BID\                                        ← Proposals + contract docs
  └── CONDICIONES GENERALES DEL PROYECTO "Affinity".pdf

D:\app\                                        ← Working codebase
  ├── lib/                                     ← Dart source code
  ├── android/, ios/                           ← Native platforms
  ├── firebase_options.dart                    ← Existing Firebase config
  ├── pubspec.yaml                             ← Dependencies (minimal — needs additions)
  └── docs/                                    ← This folder
       ├── README.md                           ← You are here
       ├── PROJECT_OVERVIEW.md
       ├── CHAT_HISTORY.md
       ├── DECISIONS_LOG.md
       ├── TECHNICAL_SPEC.md
       └── CODE_ANALYSIS.md
```

---

## 🚀 Next Actions (Week 1)

1. Create Google Cloud Platform account with `affinitysocialclub@gmail.com`
2. Enable Places API + create restricted API key
3. Set up separate Firebase dev project (isolated from production)
4. Write data migration script: `profiles` → `couples` schema
5. Replace hardcoded city dropdown with Google Places Autocomplete
6. Connect Forgot Password flow to Firebase Auth
7. Customize Firebase Auth email template (no app branding)
8. Build Account Deletion flow with 30-day grace period + Cloud Function
9. Deploy Firestore Security Rules

See `PROJECT_OVERVIEW.md` Section 7 for full timeline.

---

## 💬 Communication Notes

- **Primary channel:** Workana chat
- **Language:** Spanish with client (written/technical Spanish is strong; speak Spanish in calls)
- **Client values:** quality > speed, honesty > promises, long-term partnership
- **Client's philosophy:** open communication, flexibility on small adjustments, coherent UX

---

## ⚠️ Do NOT Forget

1. **Apple rejection is not acceptable** to client — preparation must be thorough
2. **Reporter confidentiality is total** — never reveal identity directly or indirectly (one exception: client accepted auto-block after suspension despite this)
3. **Couple is single entity** — always operate at couple level, never partner level
4. **Screenshot protection has NO user notification** (client decision)
5. **Video retention is exactly 7 days** after approval, then hash + frames only
6. **2 retry attempts only** for video verification, then block
7. **Store listing must NEVER mention** swinger/lifestyle/swap terms publicly
8. **50% threshold** applies only to free `interests` — Dynamics and Experience are strict matches
9. **No state management library currently** — introduce Riverpod progressively, don't refactor existing screens
10. **Integration after DEV finishes is Gabriel's responsibility** — DEV won't help

---

**Last updated:** 2026-04-18 (contract signed day)
