# What fails and what fixes "SSL: CERTIFICATE_VERIFY_FAILED", one step per line of output.
# Usage: python probe.py [url] [ca-bundle]   (the bundle is optional: a PEM with the extra root to trust)
import os, ssl, sys, subprocess, urllib.request
url = sys.argv[1] if len(sys.argv) > 1 else 'https://pypi.org/simple/'
bundle = sys.argv[2] if len(sys.argv) > 2 else None
print(f'python {sys.version.split()[0]} | openssl {ssl.OPENSSL_VERSION} | {url}')
strict = getattr(ssl, 'VERIFY_X509_STRICT', 0)
print('default context has VERIFY_X509_STRICT:', bool(ssl.create_default_context().verify_flags & strict))

def run(label, fn):
    try:
        fn(); print(f'{label}: OK')
    except Exception as e:
        msg = str(getattr(e, 'reason', e))
        print(f'{label}: FAILED {type(e).__name__}: {msg[:220]}')

run('urllib, default', lambda: urllib.request.urlopen(url, timeout=20).read(1))
try:
    import requests
    run('requests, default (certifi)', lambda: requests.get(url, timeout=20))
except ImportError:
    print('requests: not installed')
if bundle:
    run('urllib, cafile=bundle', lambda: urllib.request.urlopen(url, timeout=20, context=ssl.create_default_context(cafile=bundle)).read(1))
    def no_strict():
        c = ssl.create_default_context(cafile=bundle); c.verify_flags &= ~strict
        urllib.request.urlopen(url, timeout=20, context=c).read(1)
    run('urllib, cafile=bundle, strict flag off', no_strict)
    if 'requests' in sys.modules:
        run('requests, verify=bundle', lambda: requests.get(url, timeout=20, verify=bundle))
try:
    import truststore
    truststore.inject_into_ssl()
    run('urllib, after truststore.inject_into_ssl()', lambda: urllib.request.urlopen(url, timeout=20).read(1))
    if 'requests' in sys.modules:
        run('requests, after truststore.inject_into_ssl()', lambda: requests.get(url, timeout=20))
except ImportError:
    print('truststore: not installed')
