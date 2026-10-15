# Toolkit - Expiry of your TLS certificates

``` bash
cp certs/domains.example.txt certs/domains.txt   # one host per line, optional port (default 443); ignored by git
bash certs/certs.sh                              # the table
bash certs/certs.sh /path/to/other-list.txt
```

```
HOST                             EXPIRES      DAYS   STATUS
jouskaio.me                      2026-12-14   60     ok
mail.example.com                 -            -      unreachable
```

* `ok` above 21 days, `warn` up to 21 days, `crit` up to 7 days or already expired (`CERTS_WARN` and `CERTS_CRIT` change the thresholds).
* The exit code is `0` (all good), `1` (a warning) or `2` (critical, or a host that cannot be reached), so it works in a cron job:
  `0 8 * * * bash /opt/toolkit/certs/certs.sh || echo "certificates to renew" | mail -s "TLS" you@example.com`.

It only needs `openssl`; `nc` (when present) is used to fail fast on a closed port.

## Tests

``` bash
bash certs/tests/certs.test.sh   # self-signed certificates made on the fly, no network
```
