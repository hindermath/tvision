<!-- gsdb-spec-kit-intensivpruefung:start -->
# Lastenheft GSDB-Spec-Kit-Intensivpruefung fuer {{PROJECT_NAME}}

**Stand / Date:** {{DATE}}

## Zweck / Purpose

**DE:** Dieses Lastenheft bereitet einen spaeteren, manuell gestarteten
Spec-Kit-Lauf vor. Ziel ist eine intensive Pruefung von {{PROJECT_NAME}} gegen
die Generische Secure-Development Basis (GSDB), die Projekt-Constitution, die
installierten Governance-Presets und die projektspezifischen Nachweise.

**EN:** This requirements document prepares a later manually started Spec Kit
run. The goal is an intensive review of {{PROJECT_NAME}} against the Generic
Secure Development Baseline (GSDB), the project constitution, installed
governance presets, and project-specific evidence.

## Ausgangslage / Context

- Die GSDB liegt im Projekt unter `docs/secure-development/`.
- Projektspezifische Nachweise liegen bevorzugt unter `docs/security/`.
- Der GSDB-Preflight dient nur der Vorbereitung und ersetzt keinen
  Spec-Kit-Lauf.
- Human-only-Punkte duerfen nicht als erledigt behauptet werden.

## Scope

- GSDB-Richtlinie, alle 12 Einzelchecklisten, Sammelband und mitgeltende
  Dokumente pruefen.
- MSL-Status und sprachspezifische Secure-Coding-Regeln pruefen.
- Preset-Installation und Preset-zu-CL-Mapping pruefen.
- Projektspezifische Evidenz unter `docs/security/` oder gleichwertigen
  Nachweisorten pruefen.
- Alle Ergebnisse mit der Anwendbarkeit `Applicable`, `N/A` oder `Open` und dem getrennten Umsetzungsstatus `Fulfilled`, `Partly Fulfilled`, `Not Fulfilled` oder `Not Assessed` dokumentieren.

## Nicht-Ziele / Non-Goals

- Kein automatisches Starten eines Spec-Kit-Laufs.
- Keine formale Freigabe, keine Secret-Rotation, keine Providerfreigabe und
  keine Branch-Protection-Aenderung durch einen Agenten.
- Keine pauschale Behauptung, dass das Projekt sicher ist.

## Erwartete Artefakte / Expected Artefacts

- Aktualisierte Spec-Kit-Artefakte fuer den GSDB-Prueflauf.
- GSDB-Evidenzmatrix mit Status, Begruendung, Evidenzpfad, Owner,
  Follow-up, Re-Evaluation-Trigger und Restrisiko.
- Dokumentierte `N/A`-Entscheidungen mit kurzer Begruendung.
- Liste offener Punkte fuer spaetere Haertung.

## Akzeptanzkriterien / Acceptance Criteria

- Jeder relevante GSDB-Pruefpunkt ist sichtbar behandelt.
- Keine Checkliste wird stillschweigend ausgelassen.
- Offene Punkte enthalten Owner, Follow-up und Re-Evaluation-Trigger.
- Human-only-Punkte sind als Human-only, `Open` oder `N/A` dokumentiert.
- Das Ergebnis verweist auf konkrete Evidenzpfade.

## Kopierbarer Spec-Kit Specify Prompt

```text
/speckit-specify Fuehre eine intensive GSDB-Pruefung fuer dieses Repository durch. Nutze docs/secure-development/, constitution.md, .specify/memory/constitution.md, docs/security/, Lastenheft_GSDB-Spec-Kit-Intensivpruefung.md und die installierten Governance-Presets als Pruefgrundlagen. Starte keine formale Freigabe und behaupte keine Human-only-Punkte als erledigt. Dokumentiere je Pruefpunkt die Anwendbarkeit als Applicable, N/A oder Open und getrennt die Umsetzung als Fulfilled, Partly Fulfilled, Not Fulfilled oder Not Assessed. Erfasse Begruendung, Evidenzpfad, Owner, Follow-up, Re-Evaluation-Trigger und Restrisiko. Bei N/A bleibt die Umsetzung Not Assessed. Wenn Evidenz fehlt, dokumentiere die Luecke mit konkreter Nacharbeit.
```
<!-- gsdb-spec-kit-intensivpruefung:end -->
