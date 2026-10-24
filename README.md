# Exam'1 (Qt 6 / QML edition)

Mock exams for the French amateur radio operator certificate (*certificat d'opérateur du service amateur*, ANFR), built with C++17, Qt 6 and QML for Windows and Linux.

The application uses the Exam'1 question bank maintained by Jean-Luc F6GPX. The bank is updated every quarter, and the application can install updates by itself.

The exam screen reproduces the interface the ANFR now uses for the exam (Evalbox). Every question sits in one vertical list. The propositions are check boxes, questions can be pinned, the answered and pinned questions show in a numbered grid, and the candidate validates everything once with **Finaliser l'examen**.

The user interface is in French.

## Features

- **Mock exams in ANFR conditions**
  - Regulation test: 20 questions in 15 minutes. Technique test: 20 questions in 30 minutes. Each test draws 2 questions from each of its 10 families.
  - Full exam: 40 questions in one list, as in the ANFR demonstration. Questions 1–20 are regulation, 21–40 are technique, and each test gets its own mark.
  - Extended time (×3), for candidates with a disability rate of at least 70 %.
  - Current marking scheme: 1 point per correct answer, and 0 for a wrong answer, no answer or several ticked boxes. A test is passed from 10/20. The pre-2021 scheme (+3 / −1) is also available.
  - Autosave every few seconds ("dernière sauvegarde"). A session interrupted by a crash or a power cut can be resumed from the home screen.
- **Training by theme**: free choice of families, question count and duration, with optional immediate correction (comment and link to the F6KGL course).
- **Series**: the fixed C, P, R and T series published with the bank. Everyone gets the same questions, which suits radio-club sessions.
- **Review**: last-wrong questions, saved questions and never-seen questions.
- **Question bank browser**: search by word, value or number, filter by theme, saved questions or mistakes.
- **Results**: history per candidate, marks over time, full correction of every past test.
- **Several candidates** on the same computer, each with their own results and statistics.
- **Accessibility**: hyperlegible font (Atkinson Hyperlegible) outside the exam screen, text size, dark theme and keyboard answering (A–D, P, Space).
- **Portable mode**: put an empty `portable.txt` next to `exam1.exe` and all data stays in a `userdata` folder beside it, which is handy on a USB key.

## Question bank and updates

The bank is the one used by the Exam'1 web version (exam1.r-e-f.org) and Android app. The REF publishes it as three files:

| File | Content |
|---|---|
| `questions.json` | questions, propositions, answer, theme, comment, course link, `version` date |
| `series.json` | fixed series (C, P, R, T) |
| `questions.zip` | one image per question (`<number>.png`) |

The default address is `https://exam1.r-e-f.org/assets/`, and it can be changed in the application.

- **Online update**: the application compares the published `version` with the installed one at startup (optional) or on demand. It then downloads the three files (about 35 MB) and builds a new bank in a separate folder. It switches to the new bank only once the build has succeeded, so user data (candidates, marks, saved questions) is never touched.
- **Offline import**: choose a folder, or a ZIP archive, that contains the three files.
- **Bundled bank**: when `packaging/data/` holds the three files at packaging time, they are shipped with the installer and installed on first launch. Run `packaging/fetch_bank.sh` (Linux) or `packaging/fetch_bank.ps1` (Windows) to fetch the current bank.

In `questions.json`, `reponse` counts the propositions from 0. The importer also accepts files counted from 1: it decides from the values it finds (0 present, or the last position absent).

### How questions are shown on the exam screen

On the ANFR exam, only questions with a diagram, a formula or a drawing show a picture, and the others are plain text. In the Exam'1 bank every question has a picture: the statement drawn on a yellow card. For the drawn questions, the `question` field holds only a short description.

When the bank is installed, `src/statement.cpp` decides for each question whether to show it as text only. Both of these must hold:

- **The picture holds only text.** It has no straight dark run longer than about 50 px (wires, axes, fraction bars, frames) and no significant coloured area.
- **The text is a complete statement.** It is a single line that ends like a question. It does not refer to a figure ("schéma", "ce montage", "courbe"…) and does not use the lower-case unit shorthand ("14v", "100 hz") typical of picture descriptions.

Any doubt keeps the picture. On the September 2026 bank, 1,695 questions out of 2,961 are shown as text. A setting can show the picture for every question instead.

Each bank is stored as SQLite (`bank.sqlite`) plus an `images/` folder, under the application data directory:

- Windows: `%APPDATA%\Exam1\Exam1`
- Linux: `~/.local/share/Exam1/Exam1`

## Building

### Linux (Ubuntu 24.04, Qt 6.4 from the distribution)

```bash
packaging/linux/build_linux.sh --install-deps   # first time: installs build dependencies
packaging/linux/build_linux.sh                  # builds build/exam1
packaging/linux/make_deb.sh --fetch-bank        # builds build/exam1_<version>_amd64.deb with the current bank
sudo apt install ./build/exam1_4.0.1_amd64.deb
```

Without `--fetch-bank`, the package does not include the bank and the application downloads it on first launch.

### Windows (Visual Studio 2022, Qt 6.4 or later, Inno Setup 6)

From the **x64 Native Tools Command Prompt for VS 2022**:

```bat
packaging\windows\build_windows.bat C:\Qt\6.8.0\msvc2022_64 --fetch-bank
```

The script:

1. builds with CMake (Ninja, or NMake if Ninja is missing);
2. deploys Qt with `windeployqt` and copies the Visual C++ runtime next to the executable;
3. adds the bank from `packaging\data`;
4. compiles `packaging\windows\exam1.iss` with Inno Setup.

It produces:

- `dist\Exam1\`, a ready-to-run folder;
- `build-win\Exam1-<version>-setup.exe`, the installer.

If no Qt path is given, the script uses `%QTDIR%` or the most recent `C:\Qt\6.*\msvc20*_64`.

## Development notes

These environment variables help with testing:

- `EXAM1_USER_DIR`: overrides the data directory.
- `EXAM1_DATA_DIR`: overrides the bundled-bank folder.
- `EXAM1_CAPTURE_DIR`: walks through the screens defined in `Main.qml` (`tourStep`) and saves a screenshot of each. It works with `QT_QPA_PLATFORM=offscreen`.

QML is compiled to byte code only (`--only-bytecode`), because the QML-to-C++ compiler of Qt 6.4 miscompiles some lookups.

## Project layout

```
src/                C++ back end
  bankimporter.*    builds a bank (SQLite + images) from questions.json / series.json / questions.zip
  bankstore.*       installed bank, kept in memory
  updater.*         online check and download, offline import, bundled bank
  examsession.*     exam engine: drawing, check boxes, pins, timer, marking, autosave
  userstore.*       candidates, results, saved questions, statistics (user.sqlite)
  browsermodel.*    searchable list of the whole bank
  themes.*          the 20 question families
qml/                user interface
  pages/ExamPage.qml        exam screen modelled on the ANFR / Evalbox interface
  components/EvalQuestion.qml, EvalCheck.qml
packaging/          fetch_bank scripts, Linux and Windows build and packaging
third_party/miniz   ZIP reading (MIT)
resources/          fonts (OFL) and icons
```

## Credits

- Question bank: Jean-Luc F6GPX, from the reports that candidates send to the *examen-radioamateur* mailing list.
- Original Exam'1 for Windows: René Bussy F5AXG and Arnaud Dussart, with André F8DEM.
- Exam'1 web version and bank hosting: Valentin F4HVV, on the REF servers. Android version: Maxime F4IQN.
- Course linked from the corrections: radio club de la Haute Île F6KGL / F5KFF.

This edition is a new implementation. It contains no code from the original WinDev program, and it uses the question bank with the agreement of its authors.

## Licence

- Application source: GNU GPL v3 or later (see `LICENSE`).
- Atkinson Hyperlegible: SIL Open Font License.
- miniz: MIT.
- Qt: LGPL v3.
- The questions and images belong to their authors.
