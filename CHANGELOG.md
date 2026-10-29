# Historique des versions

Chaque version a sa section `## <version>`, reprise telle quelle dans les notes de la release GitHub (voir « Publier une nouvelle version » dans le README).

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
