import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../../core/network/api_envelope_dto.dart';
import '../dto/general_evaluation_dtos.dart';
part 'general_evaluation_api.g.dart';

@RestApi()
abstract class GeneralEvaluationApi {
  factory GeneralEvaluationApi(Dio dio, {String? baseUrl}) =
      _GeneralEvaluationApi;
  @GET('app/doors/{doorId}/security/general')
  Future<ApiEnvelopeDto<GeneralEvaluationResponseDto>> general(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );
  @GET('app/doors/{doorId}/security/balance')
  Future<ApiEnvelopeDto<BalanceResponseDto>> balance(
    @Path('doorId') int doorId,
    @Query('requestId') String requestId,
    @DioOptions() Options options,
  );
  @GET('app/doors/{doorId}/security/general/operations')
  Future<ApiEnvelopeDto<OperationStatisticsDto>> operations(
    @Path('doorId') int doorId,
    @Query('range') int range,
    @DioOptions() Options options,
  );
}
