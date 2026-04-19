# DNS WebBox — Guide enseignant

Ce document explique comment le DNS est configuré dans la WebBox, pourquoi ces choix ont été faits, et comment exploiter ce service pour construire des activités pédagogiques autour du DNS.

> **Source technique de référence :** `scripts/install/07_configure_dns.sh`
> Mettre ce document à jour si la configuration Technitium évolue dans ce script.

---

## 1. Pourquoi un serveur DNS dédié ?

La WebBox héberge plusieurs projets web dans une seule VM, chacun accessible par un sous-domaine différent (`tp-formulaires.webbox.vm`, `tp-bdd.webbox.vm`, etc.). Pour que ce routage fonctionne, les postes étudiants doivent résoudre ces noms en `192.168.56.50` — l'IP fixe de la VM sur l'interface host-only VirtualBox.

Un DNS wildcard (`*.webbox.vm → 192.168.56.50`) couvre automatiquement tous les projets présents et futurs, sans reconfiguration. C'est Technitium DNS qui joue ce rôle.

**Pourquoi Technitium et pas dnsmasq ou bind9 ?**

- Interface web accessible aux débutants : les étudiants peuvent visualiser et modifier des zones DNS sans ligne de commande.
- Supporte des configurations avancées (vues, DNSSEC, DoH, DoT, logs de requêtes) — utilisable du TP introductif jusqu'aux activités avancées en fin d'année.
- API REST complète : la configuration initiale est automatisée via `07_configure_dns.sh`, mais tout reste visible et modifiable dans l'interface.

---

## 2. Accès à l'interface d'administration

| Paramètre    | Valeur                      |
| ------------ | --------------------------- |
| URL          | `http://192.168.56.50:5380` |
| Utilisateur  | `admin`                     |
| Mot de passe | `netlab123`                 |

L'accès se fait par **IP directe sur le port 5380**, pas via un nom de domaine. Cela signifie que l'interface est accessible depuis n'importe quelle machine connectée à l'interface host-only VirtualBox, **même si le DNS n'est pas encore configuré** sur le poste. C'est intentionnel : ça permet de diagnostiquer et corriger des problèmes DNS sans dépendre du DNS lui-même.

---

## 3. Ce qui est configuré automatiquement

Le script `07_configure_dns.sh` est appelé par `08_start_infra.sh` lors du premier démarrage. Il effectue les opérations suivantes via l'API REST de Technitium :

### 3.1 Zone primaire `webbox.vm`

Une zone DNS primaire nommée `webbox.vm` est créée. C'est le domaine interne de la WebBox.

### 3.2 Enregistrement wildcard

```
*.webbox.vm  →  192.168.56.50  (TTL 300s)
```

Tout sous-domaine de `webbox.vm` pointe vers la VM. Traefik reçoit la requête HTTP et la route vers le bon conteneur en lisant le header `Host`.

### 3.3 Forwarders (résolution Internet)

Quand un client demande un nom externe (ex: `google.fr`), Technitium le transmet à des serveurs upstream dans cet ordre :

| Priorité | Serveurs                               | Usage                                       |
| -------- | -------------------------------------- | ------------------------------------------- |
| 1        | `172.25.254.15`, `172.16.0.1`          | DNS interne du lycée (réseau établissement) |
| 2        | `1.1.1.1`, `9.9.9.9`, `208.67.222.222` | DNS publics (domicile, hors établissement)  |

Ce mécanisme permet aux postes étudiants de continuer à accéder à Internet normalement tout en utilisant Technitium pour la résolution `webbox.vm`.

> **Note :** Les IP du DNS lycée sont dans la variable `DNS_LYCEE` de `07_configure_dns.sh`. À adapter selon l'établissement.

### 3.4 Plugin Query Logs (Sqlite)

Le plugin de journalisation est installé automatiquement. Il enregistre toutes les requêtes DNS dans une base SQLite, consultable depuis l'interface web (`Apps > Query Logs`). Utile pour observer le comportement DNS en temps réel pendant un TP.

---

## 4. Vérification rapide (sous Windows)

Depuis un poste étudiant dont le DNS est configuré sur `192.168.56.50` :

```powershell
# Vérifier la résolution wildcard
Resolve-DnsName traefik.webbox.vm

# Interroger directement Technitium (sans dépendre de la config locale)
Resolve-DnsName tp-demo.webbox.vm -Server 192.168.56.50

# Vérifier que la résolution Internet passe toujours
Resolve-DnsName google.fr
```

Depuis la VM, pour tester la zone :

```bash
dig @localhost *.webbox.vm A
dig @localhost traefik.webbox.vm A
```

---

## 5. Opportunités pédagogiques

Technitium permet de construire des activités à plusieurs niveaux de complexité :

### Niveau débutant — Observer le DNS

- Afficher la zone `webbox.vm` dans l'interface et expliquer la structure d'une zone DNS (enregistrements A, CNAME, MX...).
- Ouvrir `Apps > Query Logs` pendant qu'un étudiant ouvre un site : montrer en direct la résolution DNS.
- Comparer le TTL 300s avec des DNS publics (TTL souvent 3600s) : explication du cache.

### Niveau intermédiaire — Modifier des enregistrements

- Créer un enregistrement A `mon-serveur.webbox.vm → 192.168.56.50` manuellement via l'interface.
- Créer un alias CNAME `www.tp-demo.webbox.vm → tp-demo.webbox.vm`.
- Supprimer le wildcard et faire créer les enregistrements manuellement : l'étudiant comprend que le wildcard était une facilité.

### Niveau avancé — Aller plus loin

- Configurer une deuxième zone pour un TP réseau plus large.
- Activer le DNS over HTTPS (DoH) ou DNS over TLS (DoT) dans les paramètres Technitium.
- Analyser les logs de requêtes pour identifier les domaines les plus consultés.
- Comparer le comportement avec et sans forwarders configurés.

---

## 6. Architecture DNS complète (rappel)

```
Poste étudiant (Windows)
  └─ DNS configuré sur 192.168.56.50 (via dns-config.ps1)
       │
       ▼
Technitium DNS (192.168.56.50:53)
  ├─ *.webbox.vm → 192.168.56.50      (résolution interne, zone locale)
  └─ Tout autre domaine → forwarders  (lycée puis Internet public)
       │
       ▼ (pour *.webbox.vm)
Traefik (192.168.56.50:80)
  ├─ traefik.webbox.vm   → dashboard Traefik
  ├─ pma.webbox.vm       → phpMyAdmin
  ├─ tp-demo.webbox.vm   → conteneur tp-demo-web
  └─ ...
```
