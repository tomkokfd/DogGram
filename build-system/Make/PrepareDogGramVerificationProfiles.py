import base64
import datetime
import os
import plistlib
import shutil
import subprocess
import tempfile
import uuid

from GenerateProfiles import (
    cleanup_temp_keychain,
    get_certificate_base64_from_p12,
    get_signing_identity_from_p12,
    setup_temp_keychain,
)


TEAM_ID = 'C67CF9S4VU'  # Identity bundled with Telegram's public fake-signing fixtures.
BUNDLE_ID = 'org.doggram.ios'
SOURCE_DIRECTORY = 'build-system/fake-codesigning/profiles'
CERTIFICATE_PATH = 'build-system/fake-codesigning/certs/SelfSigned.p12'

PROFILE_SUFFIXES = {
    'Telegram.mobileprovision': '',
    'Share.mobileprovision': '.Share',
    'NotificationContent.mobileprovision': '.NotificationContent',
    'NotificationService.mobileprovision': '.NotificationService',
    'Intents.mobileprovision': '.SiriIntents',
    'Widget.mobileprovision': '.Widget',
    'BroadcastUpload.mobileprovision': '.BroadcastUpload',
    'WatchApp.mobileprovision': '.watchkitapp',
    'WatchExtension.mobileprovision': '.watchkitapp.watchkitextension',
}


def main():
    output_directory = 'build-system/doggram-verification-signing/profiles'
    if os.path.exists(output_directory):
        shutil.rmtree(output_directory)
    os.makedirs(output_directory, exist_ok=True)

    signing_identity = get_signing_identity_from_p12(CERTIFICATE_PATH)
    if not signing_identity:
        raise RuntimeError('Could not read the fake signing identity from SelfSigned.p12')
    certificate = base64.b64decode(get_certificate_base64_from_p12(CERTIFICATE_PATH))
    keychain = setup_temp_keychain(CERTIFICATE_PATH)

    try:
        for file_name, suffix in PROFILE_SUFFIXES.items():
            source_path = os.path.join(SOURCE_DIRECTORY, file_name)
            if not os.path.isfile(source_path):
                continue

            decoded = subprocess.check_output(['security', 'cms', '-D', '-i', source_path])
            profile = plistlib.loads(decoded)
            application_identifier = '{}.{}{}'.format(TEAM_ID, BUNDLE_ID, suffix)
            profile['AppIDName'] = 'Dog Gram Verification'
            profile['ApplicationIdentifierPrefix'] = [TEAM_ID]
            profile['CreationDate'] = datetime.datetime.utcnow()
            profile['DeveloperCertificates'] = [certificate]
            profile['Entitlements'] = {
                'application-identifier': application_identifier,
                'com.apple.developer.team-identifier': TEAM_ID,
                'com.apple.security.application-groups': ['group.{}'.format(BUNDLE_ID)],
                'keychain-access-groups': ['{}.*'.format(TEAM_ID)],
                'get-task-allow': False,
            }
            if not suffix:
                # The build generator derives its APS environment from the main profile.
                profile['Entitlements']['aps-environment'] = 'development'
            profile['ExpirationDate'] = datetime.datetime.utcnow() + datetime.timedelta(days=365)
            profile['IsXcodeManaged'] = False
            profile['Name'] = 'Dog Gram Verification {}'.format(suffix or 'App')
            profile['TeamIdentifier'] = [TEAM_ID]
            profile['TeamName'] = 'Dog Gram Verification (fake signing)'
            profile['UUID'] = str(uuid.uuid4()).upper()
            profile.pop('DER-Encoded-Profile', None)

            with tempfile.NamedTemporaryFile(delete=False) as temporary_file:
                plist_path = temporary_file.name
            try:
                with open(plist_path, 'wb') as output_file:
                    plistlib.dump(profile, output_file, fmt=plistlib.FMT_XML, sort_keys=False)
                destination_path = os.path.join(output_directory, file_name)
                subprocess.check_call([
                    'security', 'cms', '-S', '-k', keychain, '-N', signing_identity,
                    '-i', plist_path, '-o', destination_path,
                ])
            finally:
                os.unlink(plist_path)
    finally:
        cleanup_temp_keychain(keychain)


if __name__ == '__main__':
    main()
