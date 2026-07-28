import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/account_overview_dto.dart';

part 'account_overview_api.g.dart';

@RestApi()
abstract class AccountOverviewApi {
  factory AccountOverviewApi(Dio dio, {String? baseUrl}) = _AccountOverviewApi;

  @GET('app/account/overview')
  Future<ApiEnvelopeDto<AccountOverviewDto>> fetchOverview(
    @DioOptions() Options options,
  );
}
