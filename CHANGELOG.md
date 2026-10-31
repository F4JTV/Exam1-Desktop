# Historique des versions

Chaque version a sa section `## <version>`, reprise telle quelle dans les notes de la release GitHub (voir « Publier une nouvelle version » dans le README).

## 4.1.0

### Nouvelle version pour Android

- **Exam'1 sur les téléphones et tablettes Android** (Android 9 ou plus récent) : les mêmes épreuves, la même base de questions, l'entraînement, les séries, les révisions et les résultats que sur ordinateur. L'APK s'installe directement, sans passer par Google Play.
- **Interface tactile.** Sur un téléphone ou une tablette tenue en hauteur, le menu de gauche devient une barre en haut de l'écran, avec un bouton ☰. À l'écran d'examen, l'en-tête tient sur deux lignes et la grille des questions s'ouvre avec le bouton « Grille ». Les cases, boutons et choix sont plus grands.
- L'application s'ouvre **en plein écran** : les barres d'Android réapparaissent un instant en faisant glisser le doigt depuis le bord de l'écran.
- Le bouton ou le geste **Retour** referme le menu ou la grille, revient à l'écran précédent, puis à l'accueil ; pendant une épreuve, il propose de l'abandonner.
- L'épreuve en cours est enregistrée dès que l'application passe en arrière-plan, pour la reprendre si Android la ferme.

### Nouvelles versions de l'application

- **Une nouvelle version est signalée à l'accueil.** Au démarrage, Exam'1 demande à GitHub le numéro de la dernière version publiée. Si elle est plus récente, un bandeau l'annonce. Son bouton « Télécharger » ouvre le paquet de votre système : installateur ou version portable sous Windows, image disque sous macOS, paquet `.deb` de votre distribution sous Linux, APK sous Android. « Plus tard » masque le bandeau jusqu'à la version suivante.
- L'écran « Mises à jour » présente la version installée et la dernière publiée, avec un bouton « Vérifier les nouvelles versions », en plus de la base de questions. La recherche au démarrage peut être désactivée dans les paramètres. Rien n'est téléchargé ni installé sans votre accord.

### Révisions et statistiques

- **Réussite par thème** dans « Résultats » : la part de bonnes réponses dans chacun des 20 thèmes et le nombre de questions déjà vues. Les thèmes faibles, ceux réussis à moins de 75 % sur au moins 5 réponses, sont en rouge.
- **« Mes thèmes faibles »** dans « Révisions » : une session sur ces thèmes, répartie entre eux. Les questions manquées viennent d'abord, puis celles jamais posées.
- **« Mes erreurs » en révision espacée.** Une question manquée revient le jour même. Bien répondue, elle revient 1 jour plus tard, puis 3 jours, puis 7 jours, et quitte la liste à la quatrième bonne réponse. Une nouvelle erreur la fait repartir du début. La page « Révisions » indique combien d'erreurs sont à revoir aujourd'hui et la date de la prochaine révision. Les erreurs enregistrées par les versions précédentes sont à revoir dès la mise à jour.

### Sauvegarde et transfert

- **Exporter et importer ses données** (Paramètres > Données). Les candidats, résultats, statistiques, erreurs à revoir et questions enregistrées tiennent dans un seul fichier `.exam1`. Il sert à les sauvegarder, ou à les retrouver sur un autre ordinateur ou téléphone.
- Avant l'importation, Exam'1 indique ce que contient le fichier et ce qu'il remplacera. Une copie des données remplacées est gardée dans le dossier de l'application (`user-avant-import.sqlite`).

### Écran d'examen et entraînement

- **Écran d'examen sombre, en option**, dans Paramètres > Affichage ou dans le menu d'accessibilité pendant l'épreuve. Par défaut, l'écran reste blanc comme à l'examen de l'ANFR. Les corrections suivent le même réglage.
- **Entraînement par thèmes : le nombre de questions suit les thèmes cochés.** C'est toujours un multiple du nombre de thèmes, d'une à dix questions par thème : avec 6 thèmes, 6 questions au moins, puis 12, 18… jusqu'à 60 avec le bouton +, et 200 au plus avec les 20 thèmes. Cocher ou décocher un thème met le nombre à jour en gardant le même nombre de questions par thème.
- Sur un téléphone, l'en-tête de chaque question tient sur sa ligne même dans une longue session (« Question 120 / 200 »).

### Affichage

- La fenêtre peut être réduite jusqu'à la taille d'un téléphone : en dessous de 880 pixels de large, le menu de gauche laisse la place à la barre du haut et à son bouton ☰.

### Base de questions

- **La base de questions se présente comme l'examen** : l'image seulement pour les questions qui ont un schéma, une formule ou un dessin, l'énoncé en texte pour les autres. Le réglage « Toujours l'image d'Exam'1 » s'applique aussi à la base.
- L'installation de la base ne garde que les images de ses questions. L'archive publiée par le REF contient aussi celles de questions retirées (131 sur 3 092 dans la version du 30 septembre 2026) : elles étaient copiées inutilement, et comptées dans le message « Installation terminée », qui annonçait plus d'images que de questions.

### Paquets

- **AppImage pour les autres distributions Linux** (Fedora, openSUSE, Arch, Manjaro, Linux Mint…), `Exam1-4.1.0-x86_64.AppImage` : l'application et ses bibliothèques Qt dans un seul fichier, à rendre exécutable puis à lancer, sans installation. Elle fonctionne avec une bibliothèque C (glibc) 2.36 ou plus récente. Le script `packaging/linux/build_appimage.sh` la produit, et GitHub Actions la joint à la release.
- Exam'1 lancé depuis l'AppImage propose l'AppImage de la nouvelle version ; sur une distribution sans paquet `.deb`, c'est aussi l'AppImage qui est proposée.
- Paquet Android `Exam1-4.1.0.apk`, compilé par `packaging/android/build_android.sh`.

## 4.0.2

### Écran d'examen et entraînement

- **Images comme à l'examen ANFR, d'après les repères de Jean-Luc F6GPX.** Une question s'affiche avec son image seulement si F6GPX l'a repérée comme nécessitant un schéma, une formule ou un dessin : 1 034 questions avec image, 1 927 en texte. Cette liste remplace l'analyse automatique des images, qui gardait l'image pour 234 questions qui n'en avaient pas besoin et la retirait pour 2 questions qui en avaient besoin.
- **278 énoncés rétablis.** La conversion de la base publiée en ligne amputait certains énoncés d'un à six caractères (« Un mélangeu », « Ension aux bornes de la pile ») ; l'application affiche l'énoncé complet.
- Les énoncés en texte sur plusieurs lignes (« 1) … 2) … ») gardent leurs retours à la ligne.
- **Numéro des questions.** À l'entraînement, le numéro de la question dans la base (par exemple n° 20003) s'affiche à côté de « Question 11 / 20 », pour la noter et la retrouver dans « Base de questions ». Un réglage permet de l'afficher toujours, seulement à l'entraînement (par défaut) ou jamais.

### Affichage

- **Les écrans se réorganisent selon la taille de la fenêtre et la taille du texte**, pour que rien ne se chevauche ni ne soit coupé. Sur une fenêtre étroite, les épreuves de l'accueil passent sous le texte de présentation, les blocs « S'entraîner autrement » et « Votre progression » s'empilent, les colonnes de l'entraînement par thèmes se replient, et les filtres, boutons et lignes de résultats passent à la ligne.
- Avec un texte agrandi, le menu de gauche s'élargit et défile si la fenêtre n'est pas assez haute.

### Résultats

- **La correction des épreuves passées se présente comme l'écran d'examen**, dans « Résultats » comme après un examen : image ou texte, cases cochées, bonne réponse, commentaire et lien vers le cours de F6KGL, avec les filtres Toutes / Fausses / Sans réponse / Épinglées.
- L'ordre des réponses et toutes les cases cochées sont désormais enregistrés, pour revoir chaque épreuve exactement comme elle a été passée. Les épreuves enregistrées par les versions précédentes s'affichent dans l'ordre de la base.
- Quand plusieurs cases sont cochées, la correction l'indique : « Plusieurs cases cochées : réponse comptée fausse ».

### Paquets

- **Version portable pour Windows**, `Exam1_v4.0.2_Windows_portable.zip` : un dossier à décompresser où l'on veut, par exemple sur une clé USB, et à lancer sans installation. Les candidats et résultats restent dans ce dossier.
- Nouveaux paquets Linux pour **Ubuntu 26.04**, **Debian 12** et **Debian 13**, en plus d'Ubuntu 24.04. Chaque paquet est compilé pour sa distribution, avec la version de Qt de celle-ci. Ces trois nouveaux paquets n'ont pas encore été testés.
- Les noms des paquets Linux indiquent leur distribution, par exemple `exam1_4.0.2_debian12_amd64.deb`.

## 4.0.1

Première version de l'édition Qt 6 / QML, entièrement réécrite en C++ pour Windows, macOS et Linux.

- Écran d'examen identique à celui de l'ANFR (Evalbox) : toutes les questions dans une seule liste, cases à cocher, questions épinglées, grille de navigation et bouton unique « Finaliser l'examen ».
- Épreuves de réglementation (20 questions en 15 minutes), de technique (20 questions en 30 minutes) et examen complet (40 questions en 45 minutes), temps aménagé ×3 en option, barème actuel de l'ANFR.
- Base de questions de Jean-Luc F6GPX livrée avec l'application et mise à jour depuis le serveur du REF, ou par import hors ligne.
- Sauvegarde automatique et reprise d'une épreuve interrompue.
- Entraînement par thèmes avec correction immédiate, séries fixes C, P, R et T, révisions, consultation de la base, historique des résultats, plusieurs candidats.
- Police Atkinson Hyperlegible, taille du texte réglable, thème sombre, réponses au clavier.
