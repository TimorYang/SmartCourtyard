import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/operation_report_request_dto.dart';
import '../dto/operation_record_response_dto.dart';

part 'operation_record_api.g.dart';

@RestApi()
abstract class OperationRecordApi {
  factory OperationRecordApi(Dio dio, {String? baseUrl}) = _OperationRecordApi;

  @POST('app/doors/{doorId}/operation-records')
  Future<ApiEnvelopeDto<bool>> reportOperation(
    @Path('doorId') int doorId,
    @Body() OperationReportRequestDto body,
    @DioOptions() Options options,
  );

  @GET('app/doors/{doorId}/operation-records')
  Future<ApiEnvelopeDto<OperationRecordPageResponseDto>> fetchOperationRecords(
    @Path('doorId') int doorId,
    @Query('current') int current,
    @Query('size') int size,
    @DioOptions() Options options,
  );
}
