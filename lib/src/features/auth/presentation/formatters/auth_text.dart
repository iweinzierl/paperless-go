import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';

String localizeAuthFailure(
  AppLocalizations l10n,
  Object error, {
  required String genericFallback,
}) {
  if (error is! AuthFailure) {
    return genericFallback;
  }

  if (error.serverMessage != null && error.serverMessage!.isNotEmpty) {
    return error.serverMessage!;
  }

  switch (error.code) {
    case AuthFailureCode.invalidServerUrl:
      return l10n.authInvalidServerUrl;
    case AuthFailureCode.unexpectedResponse:
      return l10n.authUnexpectedResponse;
    case AuthFailureCode.wrongPageInsteadOfApi:
      return l10n.authWrongPageInsteadOfApi;
    case AuthFailureCode.authenticationFailed:
      return l10n.authAuthenticationFailed;
    case AuthFailureCode.serverRejectedLogin:
      return l10n.authServerRejectedLogin;
    case AuthFailureCode.unableToReachServer:
      return l10n.authUnableToReachServer;
    case AuthFailureCode.generic:
    case AuthFailureCode.serverMessage:
      return genericFallback;
  }
}
