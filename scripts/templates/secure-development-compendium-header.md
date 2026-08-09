# Checklistensammelband Sichere Entwicklung / Secure Development Checklist Compendium

> **GENERATED FILE / GENERIERTE DATEI:** Nicht manuell bearbeiten. Der Sammelband wird aus den zwölf Dateien unter `checklisten/` erzeugt. / Do not edit manually. This compendium is generated from the twelve files under `checklisten/`.

**Baseline-Version / Baseline version:** {{BASELINE_VERSION}}
**Dokumentversion / Document version:** {{COMPENDIUM_VERSION}}
**Stand / Date:** {{RELEASE_DATE}}
**Quelle / Source:** `baseline-manifest.json` und / and `checklisten/`

## Zweck / Purpose

**DE:** Dieser Sammelband führt die zwölf kanonischen Checklisten für sichere Entwicklung in unveränderter Reihenfolge zusammen. Er ist eine vollständige Audit- und Review-Sicht. Für gezielte Prüfungen werden die Einzelchecklisten verwendet.

**EN:** This compendium combines the twelve canonical secure-development checklists in unchanged order. It is the complete audit and review view. Use the individual checklists for focused reviews.

## Einheitliches Statusmodell / Unified Status Model

Jeder Prüfpunkt verwendet zwei getrennte Statusachsen. / Every review item uses two separate status axes.

| Achse / Axis | Zulässige Werte / Allowed values |
|---|---|
| Anwendbarkeit / Applicability | `Applicable`, `N/A`, `Open` |
| Umsetzung / Implementation | `Fulfilled`, `Partly Fulfilled`, `Not Fulfilled`, `Not Assessed` |

`N/A` braucht immer eine kurze Begründung. `Open`, `Partly Fulfilled`, `Not Fulfilled` und `Not Assessed` brauchen eine Folgeaufgabe, verantwortliche Rolle und einen Zieltermin. / `N/A` always needs a short rationale. `Open`, `Partly Fulfilled`, `Not Fulfilled`, and `Not Assessed` need a follow-up action, responsible role, and target date.

## Nachweisinstanzen / Evidence Instances

**DE:** Diese Datei ist eine Vorlage, kein ausgefüllter Projektnachweis. Ausgefüllte Nachweise werden unter `docs/security/secure-development/<datum>-<scope>/` abgelegt und nennen Projekt, Scope, Prüfdatum, Baseline-Version, verantwortliche Person, Reviewer, Evidenzpfade, Restrisiken und Neubewertungs-Trigger.

**EN:** This file is a template, not completed project evidence. Completed evidence is stored under `docs/security/secure-development/<date>-<scope>/` and names project, scope, review date, baseline version, responsible person, reviewer, evidence paths, residual risks, and re-evaluation triggers.

## Kapitelüberblick / Chapter Overview

- [CL-01 Standards-Anwendbarkeit](checklisten/CL_01_Standards-Anwendbarkeit.md)
- [CL-02 Sichere Softwarearchitektur](checklisten/CL_02_Sichere-Softwarearchitektur.md)
- [CL-03 Krypto-Mindestvorgaben](checklisten/CL_03_Krypto-Mindestvorgaben.md)
- [CL-04 Bedrohungsmodellierung](checklisten/CL_04_Bedrohungsmodellierung.md)
- [CL-05 Lieferkette und Build-Integrität](checklisten/CL_05_Lieferkette-Build-Integritaet.md)
- [CL-06 Schwachstellenoffenlegung](checklisten/CL_06_Schwachstellenoffenlegung.md)
- [CL-07 CRA-Anwendbarkeit](checklisten/CL_07_CRA-Anwendbarkeit.md)
- [CL-08 Sicherheits-Code-Review](checklisten/CL_08_Sicherheits-Code-Review.md)
- [CL-09 KI-Codeerzeugung](checklisten/CL_09_KI-Codeerzeugung.md)
- [CL-10 Sichere Entwicklungsumgebung](checklisten/CL_10_Sichere-Entwicklungsumgebung.md)
- [CL-11 Datenschutz-Folgenabschätzung](checklisten/CL_11_Datenschutz-Folgenabschaetzung.md)
- [CL-12 Agentische KI-Sandbox](checklisten/CL_12_Agentische-KI-Sandbox.md)
