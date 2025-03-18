#!/usr/bin/env python3
import os
import requests
import sys
import time

def get_linode_domain():
    domain = os.getenv('LINODE_DOMAIN')
    if not domain:
        print("Error: LINODE_DOMAIN environment variable not set")
        sys.exit(1)
    return domain

def validate_github_oauth_url(r):
    """Validate GitHub OAuth start URL parameters"""
    if r.status_code != 302:
        return False
    location = r.headers.get('Location', '')
    test_results = [
            location.startswith('https://github.com/login/oauth/authorize'),
            'approval_prompt=force' in location,
            'client_id=' in location,
            'redirect_uri=' in location,
            'response_type=code' in location,
            'scope=user%3Aemail' in location,
            'state=' in location
        ]
    if not all(test_results):
        print(f"Results should all be True: {test_results}")
    return all(test_results)

def test_web():
    linode_domain = get_linode_domain()
    host = f"plannies-mate.{linode_domain}"
    test_results = []

    # Basic web endpoints
    web_tests = [
        ("HTTP Redirect", f"http://{host}/",
         lambda r: r.status_code in [301, 308] and
                  r.headers['Location'].startswith('https://')),
        ("HTTPS Working", f"https://{host}/",
         lambda r: r.status_code == 200 and "Plannies Mate" in r.text),
        ("Robots.txt", f"https://{host}/robots.txt",
         lambda r: r.status_code == 200 and "Disallow: /" in r.text),
        ("OAuth Start URL", f"https://{host}/oauth2/start", lambda r: validate_github_oauth_url(r))
    ]

    for test_name, url, validator in web_tests:
        try:
            print(f"  Testing {test_name}: {url}")
            r = requests.get(url, verify=True, timeout=5, allow_redirects=False)
            success = validator(r)
            if not success:
                print(f"  Status: {r.status_code}")
                print(f"  Headers: {r.headers}")
                print(f"  Body text: {r.text}")
            test_results.append(f"Web {test_name}: {'PASS' if success else 'FAIL'}")
        except Exception as e:
            test_results.append(f"Web {test_name}: FAIL - Error {str(e)}")

    # OAuth2 specific endpoints
    oauth_tests = [
        ("Ping Check", "/ping", 200, None),
        ("Ready Check", "/ready", 200, None),
        ("Sign In Page", "/oauth2/sign_in", 200, "Sign in with GitHub"),
        ("Sign Out", "/oauth2/sign_out", 302, None),  # Should redirect to home page
        ("Metrics", "/metrics", 403, "Sign in with GitHub"),
        ("Start OAuth", "/oauth2/start", 302, None),
        ("Auth Check", "/oauth2/auth", 401, "Unauthorized"),
        ("User Info", "/oauth2/userinfo", 401, "Unauthorized"),
        ("Static CSS", "/oauth2/static/css/bulma.min.css", 200, None)
    ]

    for test_name, path, expected_code, expected_content in oauth_tests:
        try:
            url = f"https://{host}{path}"
            print(f"  Testing OAuth endpoint: {url}")
            r = requests.get(url, verify=True, timeout=5, allow_redirects=False)
            status_ok = r.status_code == expected_code
            content_ok = True if not expected_content else expected_content in r.text

            if status_ok and content_ok:
                result = "PASS"
            else:
                result = (f"FAIL - Got status {r.status_code}, "
                         f"expected {expected_code}")

            test_results.append(f"OAuth {test_name}: {result}")
        except Exception as e:
            test_results.append(f"OAuth {test_name}: FAIL - Error {str(e)}")

    # Protected content paths
    protected_paths = [
        '/authorities/',
        '/repos/',
        '/crikey-whats-that/'
    ]

    for path in protected_paths:
        try:
            url = f"https://{host}{path}"
            print(f"  Testing protected path: {url}")
            r = requests.get(url, verify=True, timeout=5, allow_redirects=False)
            is_oauth = (r.status_code == 403 and
                       'Sign in with GitHub' in r.text)

            if is_oauth:
                result = "PASS - Shows OAuth sign-in page"
            else:
                result = (f"FAIL - Expected 403 with sign-in page, got "
                         f"status {r.status_code}")

            test_results.append(f"Protected {path}: {result}")
        except Exception as e:
            test_results.append(f"Protected {path}: FAIL - Error {str(e)}")

    return test_results

if __name__ == "__main__":
    if len(sys.argv) != 1:
        print("Usage: test_web.py")
        sys.exit(1)

    results = test_web()
    failed = 0
    for result in results:
        print(result)
        if 'PASS' not in result:
            failed += 1

    if failed:
        print(f"\n{failed} web tests FAILED")
        sys.exit(1)
    else:
        print("\nAll web tests PASSED")
        sys.exit(0)
