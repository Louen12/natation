# Règles Git pour notre projet

Pour travailler efficacement à 20 sur ce projet, merci de respecter les règles suivantes.

---

## 1. Organisation des branches

- La branche `main` est **protégée** : personne ne pousse directement dessus.
- Chaque fonctionnalité ou correction doit être faite sur une **branche dédiée** :  

feature/nom-du-groupe-nom-de-la-personne
- Ajouter un **gitmoji** correspondant à votre commit (voir [Gitmoji](https://gitmoji.dev/)) :


---

## 2. Commits

- Les messages de commit doivent être clairs et concis.
- Exemple de message :  

✨ feat: ajout du formulaire de connexion
🐛 fix: correction du bug sur le calcul du total
📝 docs: mise à jour du README



- **Ne pas utiliser** des messages vagues comme : `update`, `modif`, `test`.

---

## 3. Pull Requests (PR)

- Toujours créer une PR pour fusionner dans la **branche du groupe**.
- Minimum **1 relecture** par un membre de l’équipe avant merge.
- La PR doit décrire clairement :
  - Ce qui a été fait
  - Les fichiers impactés
  - Si des tests sont nécessaires

---

## 4. Bonnes pratiques

- Ne pas pousser de fichiers inutiles (ajouter un `.gitignore` adapté).
- Faire des **petits commits fréquents** plutôt qu’un gros commit unique.
- Toujours **tirer les dernières modifications (`git pull`)** avant de commencer à coder.


## 5.Gestion des conflits
- Résoudre les conflits localement avant de pousser la branche.
- Toujours relire et tester après un merge pour vérifier que rien n’a cassé.


## 6.collaboration
-  Ne pas écraser le travail des autres (éviter git push --force sur une branche partagée).