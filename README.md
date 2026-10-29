# Exam'1 (édition Qt 6 / QML)

Examens blancs du certificat d'opérateur du service amateur (radioamateur, ANFR), développés en C++17, Qt 6 et QML pour Windows, Linux et macOS.

L'application utilise la base de questions Exam'1, tenue à jour par Jean-Luc F6GPX. La base est mise à jour chaque trimestre, et l'application peut installer elle-même les nouvelles versions.

L'écran d'examen reproduit l'interface que l'ANFR utilise désormais pour l'examen (Evalbox). Toutes les questions sont présentées dans une seule liste verticale. Les propositions sont des cases à cocher, les questions peuvent être épinglées, une grille numérotée montre les questions répondues et épinglées, et le candidat valide l'ensemble une seule fois avec **Finaliser l'examen**.

![Écran d'accueil d'Exam'1 sous Windows](capture-accueil.png)

## Fonctionnalités

- **Examens blancs dans les conditions de l'ANFR**
  - Épreuve de réglementation : 20 questions en 15 minutes. Épreuve de technique : 20 questions en 30 minutes. Chaque épreuve tire 2 questions dans chacune de ses 10 familles.
  - Examen complet : 40 questions dans une seule liste, comme la démonstration de l'ANFR. Les questions 1 à 20 portent sur la réglementation et les questions 21 à 40 sur la technique ; chaque épreuve reçoit sa propre note.
  - Temps aménagé (×3) pour les candidats ayant un taux d'incapacité d'au moins 70 %.
  - Barème actuel : 1 point par bonne réponse, et 0 point pour une réponse fausse, une absence de réponse ou plusieurs cases cochées. Une épreuve est réussie à partir de 10/20. L'ancien barème d'avant 2021 (+3 / −1) reste disponible.
  - Sauvegarde automatique toutes les quelques secondes (« dernière sauvegarde »). Une session interrompue par un plantage ou une coupure de courant peut être reprise depuis l'accueil.
- **Entraînement par thèmes** : choix libre des familles, du nombre de questions et de la durée, avec correction immédiate en option (commentaire et lien vers le cours de F6KGL).
- **Numéro des questions** : à l'entraînement, le numéro de chaque question dans la base (par exemple n° 20003) s'affiche à côté de « Question 11 / 20 », pour la noter et la retrouver dans la consultation de la base. Un réglage permet de l'afficher toujours, seulement à l'entraînement (par défaut) ou jamais.
- **Séries** : les séries fixes C, P, R et T publiées avec la base. Tout le monde reçoit les mêmes questions, ce qui convient aux séances en radio-club.
- **Révisions** : questions ratées lors de la dernière réponse, questions enregistrées et questions jamais vues.
- **Consultation de la base** : recherche par mot, valeur ou numéro, filtre par thème, par questions enregistrées ou par erreurs.
- **Résultats** : historique par candidat, évolution des notes, correction complète de chaque épreuve passée. La correction se présente comme l'écran d'examen : propositions dans l'ordre affiché, cases cochées, bonne réponse, commentaire et lien vers le cours. Elle reste consultable à tout moment depuis « Résultats ».
- **Plusieurs candidats** sur le même ordinateur, chacun avec ses propres résultats et statistiques.
- **Accessibilité** : police à lisibilité renforcée (Atkinson Hyperlegible) en dehors de l'écran d'examen, taille du texte réglable, thème sombre et réponses au clavier (A à D, P, Espace).
- **Mode portable** : un fichier vide `portable.txt` placé à côté de `exam1.exe` garde toutes les données dans un dossier `userdata` voisin, pratique sur une clé USB.

## Base de questions et mises à jour

La base est celle de la version web d'Exam'1 (exam1.r-e-f.org) et de l'application Android. Le REF la publie sous forme de trois fichiers :

| Fichier | Contenu |
|---|---|
| `questions.json` | questions, propositions, réponse, thème, commentaire, lien vers le cours, date de `version` |
| `series.json` | séries fixes (C, P, R, T) |
| `questions.zip` | une image par question (`<numéro>.png`) |

L'adresse par défaut est `https://exam1.r-e-f.org/assets/` ; elle peut être modifiée dans l'application.

- **Mise à jour en ligne** : l'application compare la `version` publiée à celle qui est installée, au démarrage (en option) ou à la demande. Elle télécharge ensuite les trois fichiers (environ 35 Mo) et construit une nouvelle base dans un dossier séparé. Elle ne bascule sur la nouvelle base qu'une fois la construction réussie : les données de l'utilisateur (candidats, notes, questions enregistrées) ne sont jamais touchées.
- **Import hors ligne** : choisir un dossier, ou une archive ZIP, contenant les trois fichiers.
- **Base fournie avec l'installeur** : si `packaging/data/` contient les trois fichiers au moment de la création du paquet, ils sont livrés avec l'installeur et installés au premier lancement. Les scripts `packaging/fetch_bank.sh` (Linux) et `packaging/fetch_bank.ps1` (Windows) téléchargent la base actuelle.

Dans `questions.json`, `reponse` numérote les propositions à partir de 0. L'import accepte aussi les fichiers numérotés à partir de 1 : il le déduit des valeurs présentes (présence d'un 0, ou absence de la dernière position).

### Affichage des questions à l'écran d'examen

À l'examen de l'ANFR, seules les questions comportant un schéma, une formule ou un dessin affichent une image ; les autres sont présentées en texte. Dans la base Exam'1, chaque question possède une image : l'énoncé dessiné sur une fiche jaune. Pour les questions illustrées, le champ `question` ne contient qu'une courte description.

Jean-Luc F6GPX repère ces questions dans le fichier Excel de la base : leur énoncé commence par « - » (saisi « '- » dans Excel). La conversion en `questions.json` par le REF supprime ce repère. La liste tirée de son fichier est donc livrée avec l'application (`resources/bank/marks.json`), et `src/statement.cpp` l'applique dans cet ordre :

1. Une question sans image s'affiche en texte.
2. Si `questions.json` fournit l'information, elle décide : champ booléen `imageNecessaire` de chaque question, ou repère « - » conservé en tête d'énoncé.
3. Sinon, la liste de F6GPX décide : image pour les questions repérées, texte pour les autres.
4. Une question ajoutée après cette liste est analysée : elle s'affiche en texte seulement si son image ne contient que du texte et si son énoncé est complet. Au moindre doute, l'image est conservée.

La conversion du REF ampute aussi quelques énoncés d'un à six caractères (« Un mélangeu », « Ension aux bornes de la pile »). Pour ces questions, l'application reprend l'énoncé complet du fichier de F6GPX.

Avec la liste tirée de `Questions_v3aw.xls`, 1 927 questions sur 2 961 s'affichent en texte et 1 034 avec leur image ; 278 énoncés amputés sont rétablis. La liste est aussi appliquée aux bases déjà installées, sans les reconstruire. Un réglage permet d'afficher l'image pour toutes les questions.

Quand F6GPX publie une nouvelle version de son fichier, il suffit de régénérer la liste, puis de recompiler l'application :

```bash
pip install xlrd openpyxl
python3 tools/f6gpx_marks.py Questions_vXXX.xls --questions packaging/data/questions.json
```

Chaque base est enregistrée sous forme d'une base SQLite (`bank.sqlite`) et d'un dossier `images/`, dans le dossier de données de l'application :

- Windows : `%APPDATA%\Exam1\Exam1`
- Linux : `~/.local/share/Exam1/Exam1`
- macOS : `~/Library/Application Support/Exam1/Exam1`

## Systèmes pris en charge

| Système | Paquet | Qt utilisé | État |
|---|---|---|---|
| Windows 10 et 11 (64 bits) | installeur `.exe` | 6.8 (GitHub Actions) | testé avec succès |
| macOS 12 ou plus récent (Apple Silicon et Intel) | image disque `.dmg` | 6.8 (GitHub Actions) | testé avec succès |
| Ubuntu 24.04 | `.deb` | 6.4 (distribution) | testé avec succès |
| Ubuntu 26.04 | `.deb` | 6.10 (distribution) | compilé, pas encore testé |
| Debian 12 | `.deb` | 6.4 (distribution) | compilé, pas encore testé |
| Debian 13 | `.deb` | 6.8 (distribution) | compilé, pas encore testé |

Sous Linux, seul le paquet `.deb` pour Ubuntu 24.04 a été testé. Les paquets pour Ubuntu 26.04, Debian 12 et Debian 13 sont produits automatiquement, mais n'ont pas encore été essayés sur ces systèmes. Les versions Windows et macOS ont été testées avec succès.

## Compilation

### Linux (Ubuntu 24.04 / 26.04, Debian 12 / 13, Qt 6 de la distribution)

Le paquet se compile sur la distribution à laquelle il est destiné, avec les paquets Qt 6 de celle-ci :

```bash
packaging/linux/build_linux.sh --install-deps   # la première fois : installe les dépendances de compilation
packaging/linux/build_linux.sh                  # compile build/exam1
packaging/linux/make_deb.sh --fetch-bank        # crée build/exam1_<version>_<distribution>_amd64.deb avec la base actuelle
sudo apt install ./build/exam1_<version>_ubuntu24.04_amd64.deb
```

Le nom du paquet indique la distribution (`ubuntu24.04`, `ubuntu26.04`, `debian12`, `debian13`) : un paquet compilé pour l'une ne convient pas aux autres. Sans `--fetch-bank`, le paquet ne contient pas la base, et l'application la télécharge au premier lancement.

### Windows (Visual Studio 2022, Qt 6.4 ou plus récent, Inno Setup 6)

Depuis l'**x64 Native Tools Command Prompt for VS 2022** :

```bat
packaging\windows\build_windows.bat C:\Qt\6.8.0\msvc2022_64 --fetch-bank
```

Le script :

1. compile avec CMake (Ninja, ou NMake si Ninja est absent) ;
2. déploie Qt avec `windeployqt` et copie le runtime Visual C++ à côté de l'exécutable ;
3. ajoute la base depuis `packaging\data` ;
4. compile `packaging\windows\exam1.iss` avec Inno Setup.

Il produit :

- `dist\Exam1\`, un dossier prêt à l'emploi ;
- `build-win\Exam1-<version>-setup.exe`, l'installeur.

Si aucun chemin de Qt n'est indiqué, le script utilise `%QTDIR%` ou le plus récent `C:\Qt\6.*\msvc20*_64`.

### macOS (Qt 6.8 ou plus récent, Xcode)

Sur un Mac :

```bash
packaging/macos/build_macos.sh ~/Qt/6.8.3/macos --fetch-bank
```

Le script compile une application universelle (Apple Silicon et Intel, macOS 12 ou plus récent). Il ajoute la base dans `Exam1.app/Contents/Resources/data` et déploie Qt avec `macdeployqt`. Il produit `build-mac/Exam1.app` et `build-mac/Exam1-<version>.dmg`.

Sans certificat Apple, l'application reçoit une signature « ad hoc ». macOS demande alors une confirmation au premier lancement : *Réglages Système → Confidentialité et sécurité → Ouvrir quand même*. Avec un compte Apple Developer, les variables `MACOS_SIGN_IDENTITY`, `APPLE_ID`, `APPLE_TEAM_ID` et `APPLE_APP_PASSWORD` permettent de signer l'application et de la faire notariser (voir l'en-tête du script).

L'icône `packaging/macos/exam1.icns` est générée par `tools/make_macos_icon.py`.

### Compilation automatique (GitHub Actions)

Le workflow `.github/workflows/release.yml` compile tous les paquets sur les machines de GitHub : l'installeur Windows, l'image disque macOS et un paquet `.deb` pour chacune des distributions Ubuntu 24.04, Ubuntu 26.04, Debian 12 et Debian 13. Chaque paquet Linux est compilé dans un conteneur de sa distribution, avec les paquets Qt 6 de celle-ci.

- **Tag `v<version>`** : tous les paquets sont joints à un brouillon de release « Exam'1 <version> », avec ses notes de version (voir ci-dessous). Si la compilation échoue pour une distribution Linux, le brouillon est quand même créé avec les autres paquets : vérifiez l'exécution avant de publier.
- **Run workflow** (onglet *Actions*) : les paquets sont compilés sans release et peuvent être téléchargés depuis la page de l'exécution, par exemple pour faire essayer la version macOS sur un Mac.

La base de questions est téléchargée une seule fois sur le serveur du REF, puis intégrée à tous les paquets. Si ce téléchargement échoue, relancez le workflow manuellement en décochant *Bundle the current question bank* : l'application téléchargera alors la base au premier lancement. Les secrets à définir pour signer la version macOS sont décrits en tête du workflow.

### Publier une nouvelle version

Le numéro de version n'est écrit qu'à un seul endroit : la ligne `VERSION` de `project()` dans `CMakeLists.txt`. L'application (fenêtre « À propos »), les noms et les métadonnées des paquets Windows, macOS et Linux, le tag attendu et les notes de la release en découlent.

1. Dans `CMakeLists.txt`, passez la ligne `VERSION` au nouveau numéro, par exemple `4.0.3`.
2. Dans `CHANGELOG.md`, ajoutez en haut une section `## 4.0.3` qui décrit les nouveautés.
3. Publiez les modifications, puis le tag correspondant :

   ```bash
   git commit -am "Version 4.0.3"
   git tag v4.0.3
   git push origin main v4.0.3
   ```

Le workflow vérifie d'abord que le tag correspond à la version de `CMakeLists.txt` et que `CHANGELOG.md` contient sa section. Sinon, il s'arrête avant toute compilation. Il compile ensuite tous les paquets et crée le brouillon de release.

Les notes de la release sont produites par `tools/release_notes.py`, à partir de :
- la section de la version dans `CHANGELOG.md` ;
- `packaging/release/notes.md.in` : téléchargements, installation, emplacement des données et remerciements, communs à toutes les versions ;
- la version de la base de questions intégrée aux paquets.

Pour les relire avant de publier :

```bash
python3 tools/release_notes.py --bank packaging/data -o notes.md
```

## Notes de développement

Ces variables d'environnement facilitent les tests :

- `EXAM1_USER_DIR` : remplace le dossier de données.
- `EXAM1_DATA_DIR` : remplace le dossier de la base fournie.
- `EXAM1_CAPTURE_DIR` : parcourt les écrans définis dans `Main.qml` (`tourStep`) et enregistre une capture de chacun. Fonctionne avec `QT_QPA_PLATFORM=offscreen`.
- `EXAM1_WINDOW_SIZE` (par exemple `1000x660`, la taille minimale) : avec `EXAM1_CAPTURE_DIR`, fait les captures à cette taille de fenêtre, pour vérifier la disposition des écrans.

Le QML est compilé uniquement en bytecode (`--only-bytecode`), car le compilateur QML vers C++ de Qt 6.4 compile mal certaines résolutions de propriétés.

## Organisation du projet

```
src/                partie C++
  bankimporter.*    construit une base (SQLite + images) à partir de questions.json / series.json / questions.zip
  bankstore.*       base installée, gardée en mémoire
  statement.*       choix texte seul / image pour l'écran d'examen (repères de F6GPX)
  updater.*         vérification et téléchargement en ligne, import hors ligne, base fournie
  examsession.*     moteur d'examen : tirage, cases à cocher, épingles, chronomètre, notation, sauvegarde
  userstore.*       candidats, résultats, questions enregistrées, statistiques (user.sqlite)
  browsermodel.*    liste consultable de toute la base
  themes.*          les 20 familles de questions
qml/                interface utilisateur
  pages/ExamPage.qml        écran d'examen sur le modèle de l'interface ANFR / Evalbox
  components/EvalQuestion.qml, EvalCheck.qml
packaging/          scripts fetch_bank, compilation et paquets Linux, Windows et macOS ; modèle des notes de release (release/)
CHANGELOG.md        nouveautés de chaque version, reprises dans les notes de release
.github/workflows/  compilation automatique de tous les paquets et brouillon de release (release.yml)
tools/              liste des questions avec image (f6gpx_marks.py), notes de release (release_notes.py), icône macOS
third_party/miniz   lecture des archives ZIP (MIT)
resources/          polices (OFL), icônes et liste des questions avec image (bank/marks.json)
capture-accueil.png capture d'écran affichée dans ce README
```

## Remerciements

- Base de questions : Jean-Luc F6GPX, à partir des comptes rendus que les candidats envoient à la liste de diffusion *examen-radioamateur*.
- Exam'1 d'origine pour Windows : René Bussy F5AXG et Arnaud Dussart, avec André F8DEM.
- Version web d'Exam'1 et hébergement de la base : Valentin F4HVV, sur les serveurs du REF. Version Android : Maxime F4IQN.
- Cours vers lequel renvoient les corrections : radio-club de la Haute Île F6KGL / F5KFF.

Cette édition est une nouvelle réalisation. Elle ne contient aucun code du programme WinDev d'origine, et elle utilise la base de questions avec l'accord de ses auteurs.

## Licences

- Code de l'application : GNU GPL v3 ou ultérieure (voir `LICENSE`).
- Atkinson Hyperlegible : SIL Open Font License.
- miniz : MIT.
- Qt : LGPL v3.
- Les questions et les images appartiennent à leurs auteurs.
