# Lastenheft: RL-SE-/Checklist-Selbstpruefung

**Repository:** {{PROJECT_NAME}}
**Dokumenttyp:** Spec-Kit Intake / Lastenheft
**Status:** vorbereitet fuer separaten RL-SE-/CL-Selbstpruefungslauf
**Stand:** {{DATE}}

## 1. Zweck

Dieses Lastenheft beschreibt einen spaeteren Spec-Kit-Prueflauf gegen die
generische Secure-Development-Basis. Ziel ist nicht sofortige Haertung, sondern
eine nachvollziehbare Selbstpruefung, ob {{PROJECT_NAME}} die Anforderungen aus
Richtlinie Sichere Entwicklung, Checklisten, Sammelband, mitgeltenden
Dokumenten und Governance-Presets behandelt, begruendet oder als offen markiert.

Das Lastenheft startet keinen Spec-Kit-Lauf und erzeugt keine
projektspezifischen `docs/security/`-Nachweise. Diese entstehen erst im spaeter
bewusst gestarteten Lauf.

## 2. Ausgangslage

{{PROJECT_NAME}} ist ein Repository in der Level-1-/Level-2-Arbeitsstruktur.
Sichere Entwicklung ist fuer heutige, geopolitisch angespannte
Softwareentwicklung ein Muss. Deshalb wird die Selbstpruefung unabhaengig davon
vorbereitet, ob die Primaersprache als Memory-Safe Language (MSL) erkannt wird.

MSL-Status bleibt ein Pruefpunkt. Er ersetzt aber keine Pruefung von APIs,
I/O, Authentifizierung, Autorisierung, Kryptografie, Logging,
Abhaengigkeiten, Build-/Release-Pfaden oder agentischer Entwicklung.

## 3. Pruefgrundlagen

Der spaetere Spec-Kit-Lauf muss mindestens diese Grundlagen beruecksichtigen:

- `docs/secure-development/Richtlinie_Sichere-Entwicklung.md`
- `docs/secure-development/Checklistensammelband_Sichere-Entwicklung.md`
- `docs/secure-development/checklisten/CL_01_*.md` bis `CL_12_*.md`
- `docs/secure-development/mitgeltende-dokumente/`
- `docs/secure-development/mitgeltende-dokumente/Verzahnung_Richtlinie_Checklisten_Spec-Kit-Presets.md`
- `constitution.md` und `.specify/memory/constitution.md`, soweit vorhanden
- installierte Governance-Presets, soweit sie Projekt-Policy sind
- vorhandene Spec-Kit-Artefakte, `docs/security/`, Tests, CI und Review-Notizen

## 4. Zielbild des spaeteren Prueflaufs

Der spaetere Lauf erzeugt eine Evidenzmatrix. Jeder relevante Pruefpunkt
erhaelt genau einen Wert je Statusachse:

- Anwendbarkeit: `Applicable`, `N/A` oder `Open`.
- Umsetzung: `Fulfilled`, `Partly Fulfilled`, `Not Fulfilled` oder `Not Assessed`.

Jeder Pruefpunkt braucht mindestens Begruendung, Evidenzpfad oder klare
Evidenzluecke, Owner, Follow-up, Restrisiko und Re-Evaluation-Trigger. Bei
`N/A` bleibt die Umsetzung `Not Assessed`; die Begruendung bleibt Pflicht.

## 5. Scope

Im spaeteren Prueflauf werden insbesondere behandelt:

- Standards-Anwendbarkeit, MSL-Status und sprachspezifische Secure-Coding-Regeln
- Eingabevalidierung, Trust Boundaries, Fehlerbehandlung und sichere Ausgabe
- Authentifizierung, Autorisierung, Rollen, Secrets und Konfiguration
- Datei-, Netzwerk-, Datenbank-, UI-, CLI-, API- oder Prozessgrenzen
- Dependency-, Supply-Chain-, SBOM-, AI-SBOM-, VEX- und SLSA-Punkte
- BSI C3A/C5, NIS2, CRA, EU AI Act und DORA nur bei fachlicher Anwendbarkeit
- A11Y/WCAG 2.2 AA, DE-first/EN-second, CEFR B2 und didaktische Kommentare
- Sandbox, agentische Entwicklung, Toolchain und Spec-Kit-Governance

## 6. Abgrenzung

- Keine automatische Haertung des Repositorys.
- Kein Sammellauf ueber mehrere Repositories.
- Keine Feature-Branch-Erzeugung durch dieses Lastenheft.
- Keine erfundene formale Freigabe, kein QISMS-/Audit-Claim ohne Evidenz.
- Keine Repo-Sichtbarkeit, Branch-Protection, Secrets, Provider oder Modelle konfigurieren.
- Keine echte Kundendaten, produktiven Tokens oder privaten Pfade dokumentieren.

## 7. Mindestanforderungen an den spaeteren Spec-Kit-Lauf

1. Aktuellen Repository-Stand lesen und bereits erledigte Punkte nicht neu umsetzen.
2. Die Verzahnungsdatei zuerst nutzen, um Richtlinie, CLs, Presets und Evidenzpfade zuzuordnen.
3. Alle relevanten Pruefpunkte auf beiden Statusachsen klassifizieren.
4. Fuer `Fulfilled` und `Partly Fulfilled` konkrete Evidenzpfade benennen.
5. Fuer `N/A` eine kurze technische oder fachliche Begruendung erfassen.
6. Fuer `Open`, `Partly Fulfilled`, `Not Fulfilled` und `Not Assessed` Owner, Follow-up, Prioritaet, Restrisiko und Re-Evaluation-Trigger festhalten.
7. Positive Aussagen zur Einhaltung nur mit konkreter Evidenz treffen.
8. Human-only-Punkte sichtbar abgrenzen und nicht als erledigt behaupten.
9. Ergebnis als auditfaehige, fuer Auszubildende verstaendliche Markdown-Dokumentation ablegen.

## 8. Erwartete Ergebnisartefakte

| Artefakt | Erwartung |
|---|---|
| Spec-Kit `spec.md` | Ziel, Scope, Nicht-Ziele, Pruefgrundlagen und Statuslogik dokumentiert |
| Spec-Kit `plan.md` | Pruefstrategie, Evidenzpfade, Standards und Presets nachvollziehbar |
| Spec-Kit `tasks.md` | Konkrete Pruef-, Dokumentations- und Follow-up-Aufgaben ableitbar |
| Evidenzmatrix | Beide Statusachsen mit Begruendung, Evidenz, Owner und Restrisiko |
| `docs/security/` | Projektspezifische Nachweise oder begruendete N/A-/Open-Eintraege |
| Abschlussnotiz | Ergebnis, offene Risiken, Restrisiken und Re-Evaluation-Trigger |

## 9. Akzeptanzkriterien

- Alle relevanten Punkte aus Richtlinie, Sammelband, CL_01 bis CL_12 und mitgeltenden Dokumenten sind sichtbar behandelt.
- Kein relevanter Governance-Preset-Pruefpunkt wurde stillschweigend ausgelassen.
- Jeder nicht anwendbare Punkt ist als `N/A` begruendet.
- Jede Umsetzungs- oder Evidenzluecke hat Owner, Folgeaktion und Re-Evaluation-Trigger.
- Jede positive Aussage verweist auf konkrete Evidenz.
- Das Projekt bleibt nach der Pruefung baubar, testbar und fuer Lernende nachvollziehbar.

## 10. Optimaler Specify-Prompt / Optimal Specify Prompt

```text
/speckit-specify
Nutze Lastenheft_RL-SE-Checklist-Selbstpruefung.md als verbindlichen Intake fuer einen separaten RL-SE-/Checklist-Selbstpruefungslauf in {{PROJECT_NAME}}.
Starte keinen Sammellauf ueber mehrere Repositories, erzeuge keine automatische Haertung und befuelle keine docs/security/-Nachweise ohne konkrete Spec-Kit-Aufgabe.
Erstelle eine fokussierte Feature-Spezifikation, die docs/secure-development/, Richtlinie_Sichere-Entwicklung.md, Checklistensammelband_Sichere-Entwicklung.md, CL_01 bis CL_12, mitgeltende Dokumente, Verzahnung_Richtlinie_Checklisten_Spec-Kit-Presets.md, constitution.md, .specify/memory/constitution.md und installierte Governance-Presets als Pruefgrundlagen beruecksichtigt.
Dokumentiere je Pruefpunkt die Anwendbarkeit als Applicable, N/A oder Open und getrennt die Umsetzung als Fulfilled, Partly Fulfilled, Not Fulfilled oder Not Assessed. Erfasse Begruendung, Evidenzpfad, Owner, Follow-up, Re-Evaluation-Trigger und Restrisiko.
Behandle sichere Entwicklung als Must-have. MSL-Status ist ein Pruefpunkt, aber keine Voraussetzung fuer diesen Selbstpruefungslauf.
```
