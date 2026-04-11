Éviter de taper le mot de passe avec sudo :
```
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/90-nopasswd-$USER
```

```
cd ~/webbox
docker compose -f docker-compose.infra.yml pull traefik
docker compose -f docker-compose.infra.yml up -d --force-recreate traefik
docker logs traefik --tail 20
```



Windows DNS :

PS C:\Users\jpdem> Resolve-DnsName traefik.webbox.vm
Resolve-DnsName : traefik.webbox.vm : Le nom DNS n’existe pas
Au caractère Ligne:1 : 1
+ Resolve-DnsName traefik.webbox.vm
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ResourceUnavailable: (traefik.webbox.vm:String) [Resolve-DnsName], Win32Exception
    + FullyQualifiedErrorId : DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName

