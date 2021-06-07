################################################################################
# Error translation static script.
#
# Currently used only by the Auth service.
# (Thus, placed under Auth to avoid bulk elsewhere.)
#
# The only other service that appears to report errors like this in the JS SDK is App.
#
# Conveniently, in JS, all auth errors take the form of:
#   `"auth/<code>"`
# Thus, use a similar pattern for other packages, such as:
#   `"database/<code>"`
#
# https://firebase.google.com/docs/reference/js/firebase.FirebaseError
# https://firebase.google.com/docs/reference/rest/auth#section-error-format
################################################################################


static func translate_error(service : String, message : String) -> String:
	if _ErrorCode.has(message):
		return service + "/" + _ErrorCode[message]
	else:
		return service + "/REPORT_ME/" + message


# https://github.com/firebase/firebase-js-sdk/blob/master/packages-exp/auth-exp/src/core/errors.ts
# https://github.com/firebase/firebase-js-sdk/blob/master/packages/auth/src/error_auth.js  (outdated?)
# SECOND_FACTOR_ALREADY_ENROLLED vs SECOND_FACTOR_EXISTS ??? (2020 vs 2017)
# String enum, essentially.
const _ErrorCode = {
  ADMIN_ONLY_OPERATION = 'admin-restricted-operation',
  ARGUMENT_ERROR = 'argument-error',
  APP_NOT_AUTHORIZED = 'app-not-authorized',
  APP_NOT_INSTALLED = 'app-not-installed',
  CAPTCHA_CHECK_FAILED = 'captcha-check-failed',
  CODE_EXPIRED = 'code-expired',
  CORDOVA_NOT_READY = 'cordova-not-ready',
  CORS_UNSUPPORTED = 'cors-unsupported',
  CREDENTIAL_ALREADY_IN_USE = 'credential-already-in-use',
  CREDENTIAL_MISMATCH = 'custom-token-mismatch',
  CREDENTIAL_TOO_OLD_LOGIN_AGAIN = 'requires-recent-login',
  DEPENDENT_SDK_INIT_BEFORE_AUTH = 'dependent-sdk-initialized-before-auth',
  DYNAMIC_LINK_NOT_ACTIVATED = 'dynamic-link-not-activated',
  EMAIL_CHANGE_NEEDS_VERIFICATION = 'email-change-needs-verification',
  EMAIL_EXISTS = 'email-already-in-use',
  EMULATOR_CONFIG_FAILED = 'emulator-config-failed',
  EXPIRED_OOB_CODE = 'expired-action-code',
  EXPIRED_POPUP_REQUEST = 'cancelled-popup-request',
  INTERNAL_ERROR = 'internal-error',
  INVALID_API_KEY = 'invalid-api-key',
  INVALID_APP_CREDENTIAL = 'invalid-app-credential',
  INVALID_APP_ID = 'invalid-app-id',
  INVALID_AUTH = 'invalid-user-token',
  INVALID_AUTH_EVENT = 'invalid-auth-event',
  INVALID_CERT_HASH = 'invalid-cert-hash',
  INVALID_CODE = 'invalid-verification-code',
  INVALID_CONTINUE_URI = 'invalid-continue-uri',
  INVALID_CORDOVA_CONFIGURATION = 'invalid-cordova-configuration',
  INVALID_CUSTOM_TOKEN = 'invalid-custom-token',
  INVALID_DYNAMIC_LINK_DOMAIN = 'invalid-dynamic-link-domain',
  INVALID_EMAIL = 'invalid-email',
  INVALID_EMULATOR_SCHEME = 'invalid-emulator-scheme',
  INVALID_IDP_RESPONSE = 'invalid-credential',
  INVALID_MESSAGE_PAYLOAD = 'invalid-message-payload',
  INVALID_MFA_SESSION = 'invalid-multi-factor-session',
  INVALID_OAUTH_CLIENT_ID = 'invalid-oauth-client-id',
  INVALID_OAUTH_PROVIDER = 'invalid-oauth-provider',
  INVALID_OOB_CODE = 'invalid-action-code',
  INVALID_ORIGIN = 'unauthorized-domain',
  INVALID_PASSWORD = 'wrong-password',
  INVALID_PERSISTENCE = 'invalid-persistence-type',
  INVALID_PHONE_NUMBER = 'invalid-phone-number',
  INVALID_PROVIDER_ID = 'invalid-provider-id',
  INVALID_RECIPIENT_EMAIL = 'invalid-recipient-email',
  INVALID_SENDER = 'invalid-sender',
  INVALID_SESSION_INFO = 'invalid-verification-id',
  INVALID_TENANT_ID = 'invalid-tenant-id',
  MFA_INFO_NOT_FOUND = 'multi-factor-info-not-found',
  MFA_REQUIRED = 'multi-factor-auth-required',
  MISSING_ANDROID_PACKAGE_NAME = 'missing-android-pkg-name',
  MISSING_APP_CREDENTIAL = 'missing-app-credential',
  MISSING_AUTH_DOMAIN = 'auth-domain-config-required',
  MISSING_CODE = 'missing-verification-code',
  MISSING_CONTINUE_URI = 'missing-continue-uri',
  MISSING_IFRAME_START = 'missing-iframe-start',
  MISSING_IOS_BUNDLE_ID = 'missing-ios-bundle-id',
  MISSING_OR_INVALID_NONCE = 'missing-or-invalid-nonce',
  MISSING_MFA_INFO = 'missing-multi-factor-info',
  MISSING_MFA_SESSION = 'missing-multi-factor-session',
  MISSING_PHONE_NUMBER = 'missing-phone-number',
  MISSING_SESSION_INFO = 'missing-verification-id',
  MODULE_DESTROYED = 'app-deleted',
  NEED_CONFIRMATION = 'account-exists-with-different-credential',
  NETWORK_REQUEST_FAILED = 'network-request-failed',
  NULL_USER = 'null-user',
  NO_AUTH_EVENT = 'no-auth-event',
  NO_SUCH_PROVIDER = 'no-such-provider',
  OPERATION_NOT_ALLOWED = 'operation-not-allowed',
  OPERATION_NOT_SUPPORTED = 'operation-not-supported-in-this-environment',
  POPUP_BLOCKED = 'popup-blocked',
  POPUP_CLOSED_BY_USER = 'popup-closed-by-user',
  PROVIDER_ALREADY_LINKED = 'provider-already-linked',
  QUOTA_EXCEEDED = 'quota-exceeded',
  REDIRECT_CANCELLED_BY_USER = 'redirect-cancelled-by-user',
  REDIRECT_OPERATION_PENDING = 'redirect-operation-pending',
  REJECTED_CREDENTIAL = 'rejected-credential',
  SECOND_FACTOR_ALREADY_ENROLLED = 'second-factor-already-in-use',
  SECOND_FACTOR_LIMIT_EXCEEDED = 'maximum-second-factor-count-exceeded',
  TENANT_ID_MISMATCH = 'tenant-id-mismatch',
  TIMEOUT = 'timeout',
  TOKEN_EXPIRED = 'user-token-expired',
  TOO_MANY_ATTEMPTS_TRY_LATER = 'too-many-requests',
  UNAUTHORIZED_DOMAIN = 'unauthorized-continue-uri',
  UNSUPPORTED_FIRST_FACTOR = 'unsupported-first-factor',
  UNSUPPORTED_PERSISTENCE = 'unsupported-persistence-type',
  UNSUPPORTED_TENANT_OPERATION = 'unsupported-tenant-operation',
  UNVERIFIED_EMAIL = 'unverified-email',
  USER_CANCELLED = 'user-cancelled',
  USER_DELETED = 'user-not-found',
  USER_DISABLED = 'user-disabled',
  USER_MISMATCH = 'user-mismatch',
  USER_SIGNED_OUT = 'user-signed-out',
  WEAK_PASSWORD = 'weak-password',
  WEB_STORAGE_UNSUPPORTED = 'web-storage-unsupported',
  ALREADY_INITIALIZED = 'already-initialized'
  ,
  # MJJ: I'm finding that some deprecated mesages are still in use:
  EMAIL_NOT_FOUND = 'user-not-found',  # USER_DELETED
  INVALID_ID_TOKEN = 'invalid-user-token',  # INVALID_AUTH
  RESET_PASSWORD_EXCEED_LIMIT = 'too-many-requests',  # TOO_MANY_ATTEMPTS_TRY_LATER
  #USER_NOT_FOUND = 'user-token-expired',  # TOKEN_EXPIRED ??? that's how most JS maps it
  USER_NOT_FOUND = 'user-not-found',  # USER_DELETED
  # MJJ: I couldn't find mappings for these from securetoken.googleapis.com, so I made them up:
  #MISSING_GRANT_TYPE = 'missing-grant-type',  # not needed if code here is correct
  #INVALID_GRANT_TYPE = 'invalid-grant-type',  # not needed if code here is correct
  MISSING_REFRESH_TOKEN = 'missing-refresh-token',
  INVALID_REFRESH_TOKEN = 'invalid-refresh-token',
}
