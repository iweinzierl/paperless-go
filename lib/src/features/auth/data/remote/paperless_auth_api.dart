import 'package:dio/dio.dart';
import 'package:paperless_ngx_app/src/features/auth/data/remote/models/paperless_auth_token_request.dart';
import 'package:paperless_ngx_app/src/features/auth/data/remote/models/paperless_auth_token_response.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_profile.dart';
import 'package:retrofit/retrofit.dart';

part 'paperless_auth_api.g.dart';

@RestApi()
abstract class PaperlessAuthApi {
  factory PaperlessAuthApi(Dio dio, {required String baseUrl}) =
      _PaperlessAuthApi;

  @POST('api/token/')
  Future<PaperlessAuthTokenResponse> createToken(
    @Body() PaperlessAuthTokenRequest request,
  );

  @GET('api/profile/')
  Future<PaperlessUserProfile> getProfile(
    @Header('Authorization') String authorization,
  );
}
