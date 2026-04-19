# 🛠️ Aide-mémoire PowerShell : DNS & Réseau

Cette fiche regroupe les commandes essentielles pour diagnostiquer et configurer la résolution de noms sur Windows 11, particulièrement utile lors de l'utilisation de _VM_ (_Virtual Machine_) ou de conteneurs _Docker_.

## 1. Diagnostic : « Pourquoi ça ne résout pas ? »

### Résolution de nom moderne
Contrairement à `nslookup`, cette commande utilise le client natif de l'*OS* (_Operating System_).

```powershell
# Résolution simple
Resolve-DnsName -Name traefik.webbox.vm

# Forcer un serveur spécifique pour test
Resolve-DnsName -Name google.fr -Server 192.168.56.50

# Voir les détails (IPv4, IPv6, TTL)
Resolve-DnsName -Name lemonde.fr | Select-Object *
```

### Vérifier la configuration des interfaces
Pour voir quel serveur _DNS_ est réellement interrogé par chaque carte réseau.
```powershell
# Liste tous les serveurs DNS configurés
Get-DnsClientServerAddress

# Voir la priorité (métrique) des interfaces
Get-NetIPInterface | Sort-Object InterfaceMetric
```

### Inspecter le cache local
Si vous avez modifié une _IP_ mais que l'ancienne persiste, elle est sans doute ici.
```powershell
# Afficher le cache actuel
Get-DnsClientCache

# Chercher une entrée spécifique
Get-DnsClientCache -Name "traefik*"
```

---

## 2. Configuration : « Reprendre la main »

### Affecter un serveur DNS
```powershell
# Définir l'IP de la VM comme DNS principal
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses "192.168.56.50"

# Remettre en automatique (DHCP - Dynamic Host Configuration Protocol)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ResetServerAddresses
```

### Modifier la priorité (*Metric*)
Plus la valeur est **basse**, plus l'interface est **prioritaire**.
```powershell
# Donner la priorité maximale à l'interface Host-Only
Set-NetIPInterface -InterfaceAlias "Ethernet 2" -AddressFamily IPv4 -InterfaceMetric 5
```

---

## 3. Maintenance : « Le grand nettoyage »

À utiliser sans modération dès qu'un changement de configuration est effectué.
```powershell
# Vider le cache DNS
Clear-DnsClientCache

# Alternative classique (Invite de commande)
ipconfig /flushdns
```

---

## 💡 Exemple concret d'utilisation

**Scénario :** Votre _VM_ Technitium est sur l'interface « Ethernet 2 », mais votre navigateur ignore vos domaines en `.vm`.

1. **On vérifie qui répond :**
   `Resolve-DnsName traefik.webbox.vm -Verbose`
   *(Si l'adresse IP du serveur ne correspond pas à votre VM, il y a un conflit).*

2. **On vérifie la priorité des cartes :**
   `Get-NetIPInterface -AddressFamily IPv4 | Sort-Object InterfaceMetric`
   *(Si votre Wi-Fi est à 10 et votre interface VM à 25, le Wi-Fi gagne).*

3. **On corrige et on nettoie :**
   ```powershell
   # On force le DNS et la priorité
   Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses "192.168.56.50"
   Set-NetIPInterface -InterfaceAlias "Ethernet 2" -InterfaceMetric 5
   
   # On vide la mémoire pour appliquer
   Clear-DnsClientCache
   ```

---

> [!TIP]
> **Rappel :** Toutes les commandes de configuration (`Set-`) nécessitent de lancer le terminal en tant qu'**Administrateur**.
