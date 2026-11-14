#!/usr/bin/env python3
"""Puts a just-uploaded build up for Mac App Store review, so the newest
release is always the one Apple is looking at.

  1. Waits for the build to finish processing in App Store Connect.
  2. If an older version is waiting for or in review, cancels that submission.
  3. Uses the macOS version being prepared (or creates the next one if the
     current version is live), sets its version number, "What's New" text and
     automatic release, and attaches the build.
  4. Submits it for review.

Needs an App Store Connect API key with the App Manager or Admin role:
APPSTORE_API_KEY_ID, APPSTORE_API_ISSUER_ID and APPSTORE_API_PRIVATE_KEY
(the .p8 contents). Run from CI (.github/workflows/release.yml):

  python3 tools/app_store_submit.py --app 6834836627 --version 0.1.30 --build 52 --notes-file notes.txt
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt  # PyJWT, with the cryptography package for ES256

API = "https://api.appstoreconnect.apple.com/v1"
IN_REVIEW = {"WAITING_FOR_REVIEW", "IN_REVIEW"}
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"}
OPEN_SUBMISSION = {"READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW", "UNRESOLVED_ISSUES"}


class AppStoreConnect:
    def __init__(self, key_id, issuer_id, private_key):
        self.key_id = key_id
        self.issuer_id = issuer_id
        self.private_key = private_key
        self._token = None
        self._token_time = 0
        self.dry_run = False

    def _auth(self):
        # Tokens may live 20 minutes; make a fresh one well before that.
        if self._token is None or time.time() - self._token_time > 600:
            now = int(time.time())
            self._token = jwt.encode(
                {"iss": self.issuer_id, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
                self.private_key, algorithm="ES256", headers={"kid": self.key_id, "typ": "JWT"})
            self._token_time = now
        return self._token

    def call(self, method, path, body=None, query=None):
        if self.dry_run and method != "GET":
            log(f"(dry run) would {method} {path}")
            return {"data": {"id": "dry-run"}}
        url = API + path
        if query:
            url += "?" + urllib.parse.urlencode(query)
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(url, data=data, method=method, headers={
            "Authorization": "Bearer " + self._auth(), "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                text = response.read().decode()
                return json.loads(text) if text else {}
        except urllib.error.HTTPError as error:
            detail = error.read().decode()
            raise RuntimeError(f"{method} {path} failed with {error.code}: {detail}") from None


def log(text):
    print(text, flush=True)


def wait_for_build(asc, app, build_number, minutes=40):
    """The build's id once App Store Connect has processed it."""
    deadline = time.time() + minutes * 60
    while time.time() < deadline:
        builds = asc.call("GET", "/builds", query={
            "filter[app]": app, "filter[version]": build_number,
            "filter[preReleaseVersion.platform]": "MAC_OS", "fields[builds]": "processingState,version"})
        for build in builds.get("data", []):
            state = build["attributes"]["processingState"]
            if state == "VALID":
                log(f"Build {build_number} is processed.")
                return build["id"]
            if state in ("FAILED", "INVALID"):
                raise RuntimeError(f"Build {build_number} failed processing: {state}")
        log(f"Waiting for build {build_number} to finish processing...")
        time.sleep(30)
    raise RuntimeError(f"Build {build_number} didn't finish processing in {minutes} minutes.")


def state_of(version):
    attributes = version["attributes"]
    return attributes.get("appStoreState") or attributes.get("appVersionState") or ""


def mac_versions(asc, app):
    """The app's macOS versions, newest first."""
    versions = asc.call("GET", f"/apps/{app}/appStoreVersions", query={
        "filter[platform]": "MAC_OS", "limit": 20,
        "fields[appStoreVersions]": "versionString,appStoreState,appVersionState,releaseType,createdDate"})
    return sorted(versions.get("data", []), key=lambda v: v["attributes"].get("createdDate", ""), reverse=True)


def cancel_open_submissions(asc, app):
    """Cancels any submission waiting for or in review, so the new build can take its place."""
    submissions = asc.call("GET", "/reviewSubmissions", query={
        "filter[app]": app, "filter[platform]": "MAC_OS", "filter[state]": ",".join(sorted(OPEN_SUBMISSION))})
    canceled = False
    for submission in submissions.get("data", []):
        state = submission["attributes"]["state"]
        if state == "READY_FOR_REVIEW":
            continue
        log(f"Canceling the submission that's {state.lower().replace('_', ' ')}.")
        asc.call("PATCH", f"/reviewSubmissions/{submission['id']}", {
            "data": {"type": "reviewSubmissions", "id": submission["id"], "attributes": {"canceled": True}}})
        canceled = True
    return canceled


def wait_until_editable(asc, app, version_id, minutes=10):
    deadline = time.time() + minutes * 60
    while time.time() < deadline:
        if asc.dry_run:
            return
        for version in mac_versions(asc, app):
            if version["id"] == version_id and state_of(version) in EDITABLE:
                return
        time.sleep(15)
    raise RuntimeError("The canceled version didn't become editable in time.")


def version_to_use(asc, app, version_string):
    """The macOS version to put the new build on: one in review (its submission
    is canceled), one being prepared, or a new one on top of the live version."""
    versions = mac_versions(asc, app)
    for version in versions:
        log(f"Version {version['attributes']['versionString']}: {state_of(version)}")
    for version in versions:
        if state_of(version) in IN_REVIEW:
            cancel_open_submissions(asc, app)
            wait_until_editable(asc, app, version["id"])
            return version["id"], False
    for version in versions:
        if state_of(version) in EDITABLE:
            return version["id"], False
    for version in versions:
        if state_of(version) == "PENDING_DEVELOPER_RELEASE":
            # An approved version waiting for a manual release: let it go live,
            # and the next release becomes a new version on top of it.
            log(f"Releasing approved version {version['attributes']['versionString']}.")
            asc.call("POST", "/appStoreVersionReleaseRequests", {"data": {
                "type": "appStoreVersionReleaseRequests",
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version["id"]}}}}})
            return None, False
    log(f"Creating version {version_string}.")
    created = asc.call("POST", "/appStoreVersions", {"data": {
        "type": "appStoreVersions",
        "attributes": {"platform": "MAC_OS", "versionString": version_string, "releaseType": "AFTER_APPROVAL"},
        "relationships": {"app": {"data": {"type": "apps", "id": app}}}}})
    return created["data"]["id"], True


def set_whats_new(asc, version_id, notes):
    localizations = asc.call("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    for localization in localizations.get("data", []):
        try:
            asc.call("PATCH", f"/appStoreVersionLocalizations/{localization['id']}", {"data": {
                "type": "appStoreVersionLocalizations", "id": localization["id"],
                "attributes": {"whatsNew": notes[:4000]}}})
        except RuntimeError as error:
            # The very first version of an app has no "What's New".
            log(f"Skipping What's New: {error}")


def submit(asc, app, version_id):
    submissions = asc.call("GET", "/reviewSubmissions", query={
        "filter[app]": app, "filter[platform]": "MAC_OS", "filter[state]": "READY_FOR_REVIEW"})
    if submissions.get("data"):
        submission_id = submissions["data"][0]["id"]
    else:
        submission_id = asc.call("POST", "/reviewSubmissions", {"data": {
            "type": "reviewSubmissions", "attributes": {"platform": "MAC_OS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app}}}}})["data"]["id"]
    items = {} if asc.dry_run else asc.call("GET", f"/reviewSubmissions/{submission_id}/items")
    if not items.get("data"):
        asc.call("POST", "/reviewSubmissionItems", {"data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})
    asc.call("PATCH", f"/reviewSubmissions/{submission_id}", {"data": {
        "type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}})


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--app", required=True, help="the app's Apple ID in App Store Connect")
    parser.add_argument("--version", required=True, help="version number, like 0.1.30")
    parser.add_argument("--build", required=True, help="build number, like 52")
    parser.add_argument("--notes-file", help="text for What's New")
    parser.add_argument("--dry-run", action="store_true", help="only read and print what would change")
    args = parser.parse_args()

    asc = AppStoreConnect(os.environ["APPSTORE_API_KEY_ID"], os.environ["APPSTORE_API_ISSUER_ID"],
                          os.environ["APPSTORE_API_PRIVATE_KEY"])
    asc.dry_run = args.dry_run
    build_id = wait_for_build(asc, args.app, args.build)
    version_id, created = version_to_use(asc, args.app, args.version)
    if version_id is None:
        log("An approved version is going live; this build will be submitted with the next release.")
        return
    asc.call("PATCH", f"/appStoreVersions/{version_id}", {"data": {
        "type": "appStoreVersions", "id": version_id,
        "attributes": {"versionString": args.version, "releaseType": "AFTER_APPROVAL"}}})
    asc.call("PATCH", f"/appStoreVersions/{version_id}/relationships/build", {
        "data": {"type": "builds", "id": build_id}})
    if args.notes_file:
        with open(args.notes_file) as notes:
            set_whats_new(asc, version_id, notes.read().strip())
    submit(asc, args.app, version_id)
    log(f"Submitted {args.version} ({args.build}) for review{' as a new version' if created else ''}.")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print(f"::error::{error}", file=sys.stderr)
        sys.exit(1)
