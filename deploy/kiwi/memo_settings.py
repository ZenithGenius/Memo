# Réglages de Kiwi TCMS pour Memo, chargés après ceux de Kiwi.
import os

DEBUG = False
_DOMAIN = os.environ["KIWI_DOMAIN"]
ALLOWED_HOSTS = [_DOMAIN]
CSRF_TRUSTED_ORIGINS = [f"https://{_DOMAIN}"]

# Pas de statistiques anonymes envoyées à l'éditeur.
ANONYMOUS_ANALYTICS = False

# Captures d'écran jointes aux résultats : 10 Mo au plus.
FILE_UPLOAD_MAX_SIZE = 10 * 1024 * 1024
DATA_UPLOAD_MAX_MEMORY_SIZE = int(FILE_UPLOAD_MAX_SIZE * 1.5)

# E-mails (Brevo, comme le reste de Memo) ; inactifs tant que l'hôte est vide.
if os.environ.get("KIWI_SMTP_HOST"):
    SERVER_EMAIL = DEFAULT_FROM_EMAIL = os.environ["KIWI_EMAIL_FROM"]
    EMAIL_SUBJECT_PREFIX = "[Memo tests] "
    EMAIL_HOST = os.environ["KIWI_SMTP_HOST"]
    EMAIL_PORT = int(os.environ.get("KIWI_SMTP_PORT") or 587)
    EMAIL_HOST_USER = os.environ.get("KIWI_SMTP_USER", "")
    EMAIL_HOST_PASSWORD = os.environ.get("KIWI_SMTP_PASS", "")
    EMAIL_USE_TLS = True
