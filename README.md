# jogocertchecker
Docker image for checking expiry of SSL certificates and sending alert emails

Specify environment variables as below:
* `SSL_DOMAINS` the comma-separated list of domains you want to check
* `CERT_CHECKER_MAIL_ADDRESS` The email address that should be notified when an SSL certificate nears expiry
* `MIN_SSL_CERT_EXPIRY` the minimum number of days that should be left before a certificate expires
* `CERT_CHECKER_PERIOD_HOURS` how many hours between each check (default: 24)

You also need all the environment variables from the [base image](https://github.com/jogojapan/jogosmtp).
