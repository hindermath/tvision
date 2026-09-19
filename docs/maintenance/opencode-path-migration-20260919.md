# OpenCode-Pfadmigration / OpenCode path migration

## Deutsch

Am 2026-09-19 wurden 41 versionierte Befehlsdateien von
`.opencode/commands/` nach `.opencode/command/` migriert.
Die bisher verwendeten Inhalte blieben SHA-256-identisch. In cc65 wurden
sechs ältere Zielkopien durch die bisher verwendeten Fassungen ersetzt;
die ursprünglichen Dateien bleiben in Git und in einer lokalen Sicherung.
Die Integrationsmanifest-Pfade wurden angepasst, ihre ursprünglichen
Upstream-Baseline-Hashes bewusst erhalten. Vorhandene Ignore-Freigaben wurden
auf den neuen Pfad umgestellt. Keine Preset-Version und kein Profil geändert.

Documentation Impact: UpdateRequired. Zielgruppe: Maintainer.
Owner: Repository-Maintainer. Kanonisch sind die versionierten Befehle,
`.specify/integrations/opencode.manifest.json` und `.gitignore`.
Leserpfad: Statistik-Fortschreibungsprotokoll → dieser Nachweis.
Dokumentklasse: Wartungsnachweis; Source-only, kein Home-Sync erforderlich.
Deutsch zuerst/Englisch danach, textorientiert. NIST SSDF und CWE Top 25
gelten für die Integrität der Werkzeugverteilung. Kein Produktcode,
keine Laufzeit-/Toolchain- oder Nicht-MSL-Ausnahme geändert.

Nachweis auf macOS: drei Agenten-Paritätstests bestanden; `git diff --check`
bestanden. Alle migrierten Dateien sind nicht ignoriert. Keine Spec-Kit-Läufe
gestartet, keine Commits oder Pushes durch diese Migration ausgeführt.
Bei einem späteren Spec-Kit-Update beide Pfade erneut prüfen: die installierte
Upstream-Integration kann den alten Pfad erneut erzeugen. Dies ist kein
Nachweis einer Änderung am Upstream-Generator.

## English

On 2026-09-19, 41 tracked command files were migrated from
`.opencode/commands/` to `.opencode/command/`, preserving the previously
used contents byte-for-byte with SHA-256 verification. In cc65, six older
destination copies were replaced; Git history and a local backup preserve them.
Integration manifest paths changed while upstream baseline hashes remained
intact. Existing ignore exceptions now allow the singular path.
No preset version, profile, product code, runtime or toolchain changed.

Documentation Impact: UpdateRequired. Audience and owner: repository maintainers.
Canonical sources are the tracked commands, integration manifest and ignore
rules. The statistics update log links to this source-only maintenance record;
no Home sync is required. NIST SSDF and CWE Top 25 inform distribution integrity.
Three agent-surface parity tests and whitespace checks passed on macOS.
Migrated files are not ignored. No Spec Kit execution, commit or push occurred.
Recheck both paths after future Spec Kit updates: the installed upstream
integration may recreate the plural path; its generator was not changed here.
