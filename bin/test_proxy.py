#!/usr/bin/env python3
import os
import re
import requests
import sys
import time

def load_ports():
    with open('.ports') as f:
        content = f.read()
        proxy_port = re.search(r'PROXY_PORT=(\d+)', content).group(1)
    return proxy_port

def get_proxy_domain():
    domain = os.getenv('PROXY_DOMAIN')
    if not domain:
        print("Error: PROXY_DOMAIN environment variable not set")
        sys.exit(1)
    return domain

def get_proxy_password():
    password = os.getenv('PROXY_PASSWORD')
    if not password:
        print("Error: PROXY_PASSWORD environment variable not set")
        sys.exit(1)
    return password

def test_proxy(region):
    valid_regions = ['au', 'usa', 'eu']
    if region not in valid_regions:
        print(f"Error: Region must be one of: {', '.join(valid_regions)}")
        sys.exit(1)

    proxy_domain = get_proxy_domain()
    proxy_host = f"{region}-proxy.{proxy_domain}"
    proxy_port = load_ports()
    proxy_pass = get_proxy_password()

    proxy_url = f"http://morph:{proxy_pass}@{proxy_host}:{proxy_port}"
    proxies = {
        "http": proxy_url,
        "https": proxy_url
    }

    print(f"Testing proxy: {proxy_host}:{proxy_port}")

    results = []

    # First test auth failures
    auth_tests = [
        ("No Auth", None, None),
        ("Wrong Password", "morph", "wrongpass"),
        ("Wrong Username", "wronguser", proxy_pass),
    ]

    for test_name, username, password in auth_tests:
        try:
            auth_url = f"http://{username}:{password}@{proxy_host}:{proxy_port}" if username else f"http://{proxy_host}:{proxy_port}"
            r = requests.get("http://httpbin.org/get", proxies={"http": auth_url, "https": auth_url}, timeout=5)
            got_407 = r.status_code == 407
            got_error_page = 'id=ERR_CACHE_ACCESS_DENIED' in r.text

            if got_407 and got_error_page:
                results.append(f"Auth {test_name}: PASS - Got 407 and proper error page")
            else:
                if got_407:
                    results.append(f"Auth {test_name}: FAIL - Got 407 but missing error page")
                elif got_error_page:
                    results.append(f"Auth {test_name}: FAIL - Got error page but status was {r.status_code}")
                else:
                    results.append(f"Auth {test_name}: FAIL - Got status {r.status_code} and no error page")
        except Exception as e:
            results.append(f"Auth {test_name}: FAIL - Unexpected error: {str(e)}")

    tests = [
        ("HTTP Basic", "http://httpbin.org/get"),
        ("HTTPS", "https://httpbin.org/get"),
        ("IP Masking", "https://ipapi.co/json/"),
        ("Headers", "https://httpbin.org/headers"),
        ("Large Response", "http://httpbin.org/bytes/50000")
    ]

    for test_name, url in tests:
        try:
            start = time.time()
            r = requests.get(url, proxies=proxies, timeout=10)
            duration = time.time() - start

            if test_name == "IP Masking":
                results.append(f"{test_name}: PASS - Masked IP: {r.json().get('ip')}")
            elif test_name == "Headers":
                proxy_headers = [h for h in r.json()['headers'] if 'proxy' in h.lower()]
                results.append(f"{test_name}: {'FAIL' if proxy_headers else 'PASS'} - No proxy headers leaked")
            else:
                results.append(f"{test_name}: PASS ({duration:.2f}s)")

        except Exception as e:
            results.append(f"{test_name}: FAIL - {str(e)}")

    return results

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: test_proxy.py <region>")
        print("Regions: au, usa, eu")
        sys.exit(1)

    results = test_proxy(sys.argv[1])
    failed = 0
    for result in results:
        print(result)
        if 'PASS' not in result:
            failed += 1

    if failed:
        print(f"\n{failed} tests FAILED")
    else:
        print("\nAll tests PASSED")
