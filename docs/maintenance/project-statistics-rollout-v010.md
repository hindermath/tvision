# Statistik und Assurance / Statistics and assurance rollout

## Auftrag und Grenzen / Scope and boundaries

Stand: 2026-09-19. Owner und fachlicher Reviewer: @hindermath.
Quelle: [genehmigter Rollout, Position 6](https://github.com/hindermath/home-baseline/issues/302).
Basis: `9491a688749b016ed1e65091c14a3ca39b2e8779`, sauber und origin/master 0/0.
Zwölf bestehende Presets bleiben unveraendert. Hinzu kommen Assurance v0.1.3
(Prioritaet 15) und Statistik v0.1.0 (90); globale Defaults bleiben erhalten.
Die operative lokale Zuordnung folgt erst nach Abnahme und Lieferung.

No product code, upstream synchronization, release, new Spec Kit feature or
community submission. Installation grants no pilot, project, risk, C5,
conformity or certification acceptance. Human acceptance and delivery permission
remain pending; no admin bypass is authorized for this rollout.

## Quellenbindung / Source binding

- [Installationsreceipt](project-statistics-installation-v010.json): Statistik-Payload,
  Matrixhash, Basiscommit und unveraenderte zwoelf Registry-Eintraege.
- [Statistik v0.1.0](https://github.com/hindermath/spec-kit-preset-project-statistics-governance/releases/tag/v0.1.0),
  Commit `7e824ca8de11212aefdc5b05d7d05637f5343dab`, ZIP SHA-256
  `d8ad7d5eef920f50b629121b64ba8123c22ec4f6dadd14da5cd826d1c50f420a`.
- [Assurance v0.1.3](https://github.com/hindermath/spec-kit-preset-secure-development-assurance-governance/releases/tag/v0.1.3),
  Commit `0d03aa9ebe8f74a26e331815bca5609fb48d7a14`, ZIP SHA-256
  `9023b442b4d82e25bee5a7fe9b73efb7f591a4f265f54061ae6e4a56b9b5c75f`.
  Alle installierten Dateien stimmen mit dem entpackten Tag-ZIP ueberein.

Both immutable tag archives are bound above. Existing integration files were
unchanged during installation. Cache files stay ignored. Assurance remains a
pre-release; installation is not an assurance field-test decision.

Die LF-Bindung der Matrix und Assurance-Payload verhindert die bei cc65
beobachtete Windows-Checkout-Konvertierung. Der Skriptreferenz-Renderer wird
gezielt an die kanonische Level-0-Fassung ohne Markdown-Trailing-Spaces angepasst.

LF attributes preserve byte-bound inputs on Windows. The script-reference
renderer adopts the canonical whitespace-safe paragraph rendering.

## Statistikvertrag / Statistics contract

[Bedienung](../project-statistics/README.md), [Snapshot](../project-statistics/snapshot.json)
und [Bericht](../project-statistics/report.md). UTC, 52 Wochen, Stichtag 2026-09-19;
Referenzmodelle und Phasen im neuen Kontext aus. Die Legacy-Statistik bleibt
kanonisch mit Europe/Berlin und 80/80 Zeilen pro Arbeitstag. Der neue Kontext
ist aus beiden Messungen ausgeschlossen. Bestand bindet die Quellrevision;
der Stichtag begrenzt Aktivitaet, nicht den historischen Dateibestand.

Preserve all legacy authored history. Reproducibility and freshness are separate;
different timezone/methodology contracts may yield different activity counts.
No measured time-saving, quality, safety, learner or AI productivity claims.

## Pruef- und Abnahmevertrag / Verification and acceptance

- Exakte Matrix unter Bash/PowerShell, list/info/resolve und specify check.
- [Pruefskript](../man/prove-project-statistics-context.1.md): Paketbindung,
  Statistik-Fixtures, Lifecycle, idempotentes Update in isolierter Kopie,
  LF/CRLF/BOM und unveraenderte Quellhashes. Kein vollstaendiger System-I/O-Trace.
- Assurance-Fixtures und erzeugte Oberflaechen separat pruefen; keine vier
  fachlichen Gates oder neue Evidence-Matrix automatisch als abgenommen markieren.
- Native macOS-Nachweise am exakten Head im PR; Linux/Windows als CI-Artefakte.
- CMake Release mit `TV_BUILD_TESTS=ON`, Build der Bibliothek, Beispiele und
  GoogleTest-Run-Target in einem externen Buildverzeichnis; vorhandene Artefakte bleiben erhalten.
- Exakte Befehle, Exitcodes, Plattformen, Quellrevision und Hashes im PR bzw.
  maschinenlesbaren Nachweisen. Noch nicht ausgefuehrte Tests nicht als bestanden melden.

Technical evidence precedes human acceptance. The owner reviews the published
diff; only then may the exact green head be merged and master synchronized 0/0.
The parent issue remains open for this rollout and the central closeout.

## Sicherheits- und Dokumentationsauswirkung / Security and documentation impact

NIST SSDF/CWE Top 25 gelten fuer diese Governance-/CI-Aenderung. tvision bleibt
C++14: Nicht-MSL ist wegen Borland-API-, DOS-/Unix-/Windows-Zielplattformen und historischer
Kompatibilitaet begruendet (beide Constitutions geprueft); keine Runtime-Aenderung.
ASVS und AI-SBOM fuer diesen Scope N/A: keine Web-/API- oder KI-Runtime-Komponente.
SLSA-Provenance wird durch Commit-/Paketbindung unterstuetzt, kein zertifiziertes
SLSA-Level behauptet. CI nutzt gepinnte Actions, read-only Rechte und keine Secrets.
Kein C5-Test fuer dieses Ausbildungsprojekt; keine regulatorische Freigabe.

Documentation Impact: `UpdateRequired`. Kanonische Quellen: Matrix,
Konfigurationen und dieses Rolloutdokument; Owner @hindermath. Zielgruppen:
Maintainer und Auszubildende; Leserpfad README -> Kontext -> Bericht/Snapshot.
Dokumentklassen: Bedienung, Governance, Evidence; DE zuerst/EN danach in derselben
Datei. Gemeinsame Guidance in fuenf Dateien und beiden Constitutions synchron.
Distribution: nur dieses Repository; kein Home-Sync. Neue Pruefautomation im
[Skriptregister](../scripts/reference.md) aus `scripts/config/script-catalog.json`. Re-Evaluation bei
Preset-, Konfigurations-, Methoden- oder Toolchain-Aenderung und vor Merge.

This is repository-local documentation and CI work with explicit package,
configuration and reader-path ownership. Non-MSL justification and 80/80
references remain unchanged. Human review is not replaced by automated checks.
