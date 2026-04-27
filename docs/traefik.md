# Traefik WebBox — Guide enseignant

Ce document explique comment Traefik route les requêtes HTTP dans la WebBox, pourquoi le routage fonctionne aussi avec les adresses IP, et comment configurer un site par adresse IP.

> **Fichiers de référence :**
> - Configuration statique : `traefik/traefik.yml`
> - Services Docker : `docker-compose.infra.yml`

---

## 1. Principe du routage Traefik

Traefik est un **reverse proxy** : il reçoit toutes les requêtes HTTP sur le port 80 et les redistribue vers le bon conteneur. La décision de routage repose sur le header HTTP `Host`, qui contient le nom de domaine (ou l'adresse IP) tapé dans la barre du navigateur.

```
Navigateur → http://tp-demo.webbox.vm
  Header envoyé : Host: tp-demo.webbox.vm
  Traefik : rule Host(`tp-demo.webbox.vm`) → conteneur tp-demo-web
```

**Ce que cela implique :** si un conteneur déclare la règle `Host("tp-demo.webbox.vm")`, il ne répond qu'aux requêtes portant exactement ce header. Les autres requêtes passent aux autres routeurs, ou obtiennent une erreur 404 si aucun ne correspond.

---

## 2. Comment un conteneur s'enregistre dans Traefik

Chaque service Docker se déclare auprès de Traefik via des **labels** dans son `docker-compose.yml`. Exemple minimal :

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.mon-projet.rule=Host(`mon-projet.webbox.vm`)"
  - "traefik.http.services.mon-projet.loadbalancer.server.port=80"
```

Sans `traefik.enable=true`, le conteneur est ignoré (comportement configuré dans `traefik.yml` : `exposedByDefault: false`).

---

## 3. Routage par adresse IP

Quand un étudiant tape `http://192.168.56.50` dans son navigateur, le header envoyé est :

```
Host: 192.168.56.50
```

Traefik traite ce header exactement comme un nom de domaine. Il suffit d'un routeur dont la règle est `Host("192.168.56.50")` pour intercepter ces requêtes :

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.portail.rule=Host(`192.168.56.50`)"
```

**C'est exactement ce que fait le service `portail`** dans `docker-compose.infra.yml` : il répond à `http://192.168.56.50` et affiche une page listant les services disponibles.

### Routage différent selon l'interface réseau

La VM dispose de deux interfaces :

| Interface     | IP              | Usage                         |
| ------------- | --------------- | ----------------------------- |
| Host-Only     | `192.168.56.50` | Postes étudiants              |
| NAT           | `10.0.2.15` (ou autre, dynamique) | Accès Internet de la VM |

Pour servir un contenu différent selon l'IP tapée, il suffit de créer deux routeurs avec des règles `Host` différentes :

```yaml
# Site pour l'interface Host-Only (étudiants)
- "traefik.http.routers.portail-hostonly.rule=Host(`192.168.56.50`)"
- "traefik.http.routers.portail-hostonly.service=portail-svc"

# Site pour l'interface NAT (accès interne VM)
- "traefik.http.routers.portail-nat.rule=Host(`10.0.2.15`)"
- "traefik.http.routers.portail-nat.service=autre-svc"
```

> **Remarque :** l'IP NAT est assignée par DHCP par VirtualBox et peut changer. Le routage par IP n'est donc stable que sur l'interface host-only dont l'IP est fixe (`192.168.56.50`).

---

## 4. Priorité des routeurs

Si deux routeurs peuvent correspondre à une même requête, Traefik applique une **priorité automatique** basée sur la longueur de la règle : une règle plus précise (plus longue) gagne.

Pour forcer une priorité explicite :

```yaml
- "traefik.http.routers.mon-routeur.priority=10"
```

Les valeurs plus élevées ont la priorité. Utiliser cette option pour un routeur "catch-all" qui ne doit s'activer que si rien d'autre ne correspond.

### Exemple : catch-all pour toute requête non résolue

```yaml
- "traefik.http.routers.fallback.rule=PathPrefix(`/`)"
- "traefik.http.routers.fallback.priority=1"
```

Avec une priorité de 1, ce routeur ne s'active que si aucune autre règle plus précise ne correspond.

---

## 5. Vérification

Pour vérifier quel routeur gère quelle requête, ouvrir le dashboard Traefik :

```
http://traefik.webbox.vm
```

L'onglet **HTTP → Routers** liste tous les routeurs actifs avec leur règle, leur service cible et leur priorité. C'est l'outil de diagnostic de référence.

Depuis un terminal sur la VM :

```bash
# Tester le routage par IP
curl -H "Host: 192.168.56.50" http://localhost/

# Tester un projet
curl -H "Host: tp-demo.webbox.vm" http://localhost/
```

---

## 6. Opportunités pédagogiques

Le routage Traefik est un excellent support pour introduire les concepts HTTP :

- **Header `Host`** : montrer avec `curl -v` que le header détermine quelle réponse est renvoyée, même IP, même port.
- **Reverse proxy** : comparer l'accès direct au conteneur (port exposé) vs via Traefik (port 80 + hostname) pour illustrer l'abstraction.
- **Dashboard en direct** : démarrer un nouveau projet et montrer en temps réel l'apparition du routeur dans le dashboard.
- **Erreur 404 Traefik** : supprimer `traefik.enable=true` d'un conteneur et montrer que Traefik ne le voit plus — puis le remettre.
