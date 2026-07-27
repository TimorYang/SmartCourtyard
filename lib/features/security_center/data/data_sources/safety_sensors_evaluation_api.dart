import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/safety_sensors_evaluation_dto.dart';

part 'safety_sensors_evaluation_api.g.dart';

@RestApi()
abstract class SafetySensorsEvaluationApi {
  factory SafetySensorsEvaluationApi(Dio dio, {String? baseUrl}) =
      _SafetySensorsEvaluationApi;

  @GET('app/doors/{doorId}/security/sensors')
  Future<ApiEnvelopeDto<SafetySensorsEvaluationDto>> fetchEvaluation(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );
}
