# CountDownSwiftUI

## Architecture de l'Application

CountDownSwiftUI est une application iOS qui permet de visualiser le temps restant avant le coucher ou le réveil à travers un widget et des activités en direct (Live Activities).

### Diagramme de Classes

```
+-------------------+      +---------------------+      +---------------------------+
| ContentView       |      | SleepCountdownWidget|      | SleepCountdownWidgetLive  |
|-------------------|      |---------------------|      |---------------------------|
| @AppStorage       |      | Provider            |      | SleepCountdownWidget      |
| - bedtime         |----->| - TimelineProvider  |      | Attributes                |
| - wakeupTime      |      | - getTimeline()     |      | - ContentState            |
| - isDarkMode      |      +---------------------+      | - bedtime, wakeupTime     |
| - accentColor     |                |                  +---------------------------+
|                   |                |                              ^
| - updateWidget()  |                v                              |
+-------------------+      +---------------------+      +---------------------------+
         |                 | SleepEntry          |      | SleepActivityManager      |
         |                 |---------------------|      |---------------------------|
         |                 | - date              |      | - isActivityActive        |
         v                 | - bedtime           |      | - startActivityFromView() |
+-------------------+      | - wakeupTime        |      | - endActivityFromView()   |
| CountdownPreview  |      | - isDarkMode        |      +---------------------------+
|-------------------|      | - accentColorString |
| - View            |      +---------------------+
| - bedtime         |                |
| - wakeupTime      |                |
| - isDarkMode      |                v
| - accentColor     |      +---------------------+
|                   |      | WidgetEntryView     |
| - UI components   |      |---------------------|
+-------------------+      | - smallWidget       |
                           | - mediumWidget      |
                           | - decorations()     |
                           | - calculations      |
                           +---------------------+
```

## Fonctionnement de l'Application

### Core de l'Application

1. **Stockage des Préférences**
   - Utilisation de `@AppStorage` avec un groupe de partage (`group.com.tempest.CountDownSwiftUI`)
   - Permet le partage des données entre l'application et les widgets
   - Stocke les heures de coucher/réveil, préférences de thème et couleur d'accent

2. **Système de Widgets**
   - Widget statique (WidgetKit) pour afficher le compte à rebours
   - Live Activity pour les notifications dynamiques sur l'écran de verrouillage et l'île dynamique
   - Rafraîchissement périodique pour maintenir le compte à rebours précis

3. **Calcul de Temps**
   - Détermination intelligente du prochain événement (coucher ou réveil)
   - Gestion des transitions jour/nuit
   - Calcul précis du temps restant avec formatage heures:minutes:secondes

### Composants Principaux

#### 1. ContentView
- **Fonction**: Interface principale de l'application
- **Responsabilités**:
  - Configuration des heures de coucher et de réveil
  - Personnalisation de l'apparence du widget (mode sombre, couleur d'accent)
  - Aperçu en temps réel des modifications
  - Lancement du rafraîchissement des widgets

#### 2. CountdownPreview
- **Fonction**: Prévisualisation du widget dans l'application
- **Responsabilités**:
  - Affiche en temps réel l'apparence du widget
  - Utilise les mêmes logiques de calcul et d'affichage que le widget
  - Supporte les modes petit et moyen
  - Met à jour l'affichage chaque seconde

#### 3. SleepCountdownWidget
- **Fonction**: Définition du widget pour WidgetKit
- **Responsabilités**:
  - Configuration du widget (tailles supportées, nom, description)
  - Gestion du fond qui remplit tout l'espace disponible
  - Liaison avec le Provider pour les mises à jour

#### 4. Provider (TimelineProvider)
- **Fonction**: Fournisseur de données pour le widget
- **Responsabilités**:
  - Génère des entrées temporelles pour le widget
  - Définit la fréquence de rafraîchissement
  - Répond aux notifications de mise à jour

#### 5. SleepEntry
- **Fonction**: Structure de données pour chaque entrée du widget
- **Responsabilités**:
  - Stocke la date courante
  - Récupère les préférences depuis UserDefaults partagé
  - Contient toutes les données nécessaires pour le rendu du widget

#### 6. SleepCountdownWidgetEntryView
- **Fonction**: Interface visuelle du widget
- **Responsabilités**:
  - Rendu différencié selon la taille du widget
  - Affichage des éléments décoratifs adaptés au contexte
  - Calculs de temps restant et formatage
  - Gestion des animations et effets visuels

#### 7. SleepActivityManager
- **Fonction**: Gestion des Live Activities
- **Responsabilités**:
  - Démarrage et arrêt des activités en direct
  - Mise à jour de l'état des activités
  - Suivi de l'état actif des activités

#### 8. SleepCountdownWidgetLiveActivity
- **Fonction**: Interface pour les Live Activities
- **Responsabilités**:
  - Définition de l'interface sur l'écran de verrouillage
  - Configuration de l'île dynamique (compact, étendue, minimale)
  - Mise à jour du contenu en temps réel

## Flux de Données

1. L'utilisateur configure ses préférences dans ContentView
2. Les préférences sont enregistrées via @AppStorage dans UserDefaults partagé
3. Une notification est envoyée pour actualiser les widgets
4. Le Provider génère de nouvelles entrées temporelles avec les données à jour
5. WidgetKit met à jour l'affichage du widget
6. Si les Live Activities sont actives, elles sont également mises à jour

## Personnalisation et Thèmes

- **Modes de couleur**: Mode clair ou sombre selon les préférences
- **Couleurs d'accent**: Bleu, rouge, vert, violet
- **Adaptabilité visuelle**:
  - Mode coucher: Interface minimaliste et épurée
  - Mode réveil: Thème avec soleil
  - Mode alerte: Animation clignotante pour avertir d'un temps de sommeil insuffisant
- **Personnalisation de l'interface**:
  - Textes personnalisables pour chaque mode (coucher, réveil, alerte)
  - Icônes personnalisables avec sélection parmi une bibliothèque d'icônes SF Symbols
  - Arrière-plan personnalisé avec images de la photothèque
  - Contrôles d'échelle et d'opacité pour l'image d'arrière-plan
  - Conservation des préférences entre les sessions

## Fonctionnalités Techniques Avancées

### 1. Interface Adaptative
- Adaptation à différentes tailles de widget (petit, moyen)
- Disposition optimisée pour chaque format
- Éléments visuels adaptés au contexte (réveil, coucher, alerte)

### 2. Gestion du Temps
- Calcul intelligent du prochain événement
- Prise en compte des transitions jour/nuit
- Arrondissement des secondes pour une meilleure lisibilité

### 3. Animations et Retour Visuel
- Animation de clignotement pour les alertes
- Transition visuelle lors des sauvegardes
- Opacité variable pour attirer l'attention

### 4. Performances
- Utilisation de vues légères pour les widgets
- Gestion efficace des rafraîchissements
- Structure modulaire pour une maintenance facilitée

## Remplissage Complet de l'Espace du Widget

Pour garantir que le widget occupe la totalité de l'espace disponible sans marges ni bordures blanches, l'application utilise une approche technique spécifique :

### 1. Solution Technique
- **Extension personnalisée `widgetBackground`** : Une extension qui applique correctement la couleur d'arrière-plan au widget
- **Compatibilité iOS** : Gestion différente selon la version iOS (17+ vs versions antérieures)
- **Suppression des conteneurs imbriqués** : Simplification de la hiérarchie des vues pour éviter les marges

### 2. Approche Multi-couches
- **Fond coloré** : Appliqué directement au niveau du widget et non à un conteneur interne
- **Contenu** : Placé directement dans un ZStack sans conteneurs intermédiaires
- **Décorations** : Positionnées avec précision à l'aide de GeometryReader

### 3. Techniques d'Extension des Bords
- **Utilisation de `ignoresSafeArea()`** : Extension au-delà des zones sécurisées
- **Modification du conteneur principal** : Application directe de la couleur d'arrière-plan
- **Approche native avec `containerBackground(for: .widget)`** pour iOS 17+

Cette implémentation garantit que le widget apparaît comme un élément visuel complet sur l'écran d'accueil, sans les bordures blanches typiques des widgets qui n'utilisent pas ces techniques.

## Guide d'Utilisation

1. **Configuration Initiale**
   - Définir l'heure de coucher et de réveil
   - Choisir le thème visuel préféré
   - Enregistrer les paramètres

2. **Ajout du Widget**
   - Accéder à l'écran des widgets iOS
   - Ajouter le widget "Sleep Countdown"
   - Choisir la taille préférée (petit ou moyen)

3. **Utilisation des Live Activities**
   - Activer depuis l'application principale
   - Visible sur l'écran de verrouillage et dans l'île dynamique
   - Se termine automatiquement après le réveil

## Considérations Techniques

- Développé avec SwiftUI et WidgetKit
- Compatible avec iOS 16.0 et versions ultérieures
- Optimisé pour les appareils avec île dynamique
- Utilise les groupes d'apps pour le partage de données
- Conçu selon les recommandations d'interface d'Apple (Human Interface Guidelines)

## Interface Responsive des Widgets

Pour assurer que le contenu du widget s'affiche correctement quelle que soit sa taille, l'application implémente plusieurs techniques de design responsive :

### 1. Adaptation Automatique du Texte
- **Redimensionnement dynamique** : La taille de police s'ajuste en fonction de la largeur du widget
- **Facteur d'échelle minimum** : Utilisation de `minimumScaleFactor` pour réduire progressivement la taille du texte
- **Limitation des lignes** : Contrainte du texte à une seule ligne avec `lineLimit(1)`

### 2. Techniques d'Implémentation
- **GeometryReader** : Utilisé pour obtenir les dimensions exactes de l'espace disponible
- **Calculs proportionnels** : La taille du texte est calculée comme une fraction de la largeur (ex: `width/6`)
- **Espacement optimisé** : Les marges et espacements sont ajustés en fonction de la taille du widget

### 3. Compatibilité Multi-formats
- **Optimisation spécifique** : Chaque taille de widget (petit, moyen) a sa propre mise en page
- **Priorités de contenu** : Les informations les plus importantes restent visibles même dans les plus petits formats
- **Live Activities** : Implémentation responsive également pour l'affichage sur l'écran de verrouillage

Cette approche responsive garantit que le compte à rebours reste parfaitement lisible, quelle que soit la taille du widget choisie par l'utilisateur, même sur les plus petits écrans ou dans l'île dynamique. 