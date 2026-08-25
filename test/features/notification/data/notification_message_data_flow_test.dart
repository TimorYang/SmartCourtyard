import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/features/notification/data/data_sources/notification_message_api.dart';
import 'package:flinx/features/notification/data/data_sources/notification_message_remote_data_source.dart';
import 'package:flinx/features/notification/data/dto/notification_message_dto.dart';
import 'package:flinx/features/notification/data/repositories/notification_message_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses numeric notification timestamps from the real wire shape', () {
    final page = NotificationMessagePageDto.fromJson(const {
      'current': '1',
      'size': '50',
      'total': '1',
      'records': [
        {
          'id': '2',
          'templateCode': 'DEVICE_ABNORMAL',
          'type': 'DEVICE',
          'iconCode': 'device-alert',
          'title': 'Device Abnormality Alert',
          'label': 'Device Message',
          'summary': 'An abnormality has been detected.',
          'read': true,
          'createTime': 1786100633000,
        },
      ],
    });
    final detail = NotificationMessageDetailDto.fromJson(const {
      'id': '2',
      'templateCode': 'DEVICE_ABNORMAL',
      'type': 'DEVICE',
      'title': 'Device Abnormality Alert',
      'label': 'Device Message',
      'content': 'An abnormality has been detected.',
      'read': true,
      'createTime': 1786100633000,
    });

    expect(page.records.single.createTime, '1786100633000');
    expect(detail.createTime, '1786100633000');
  });

  test('formats a millisecond timestamp when mapping notification data', () {
    const dto = NotificationMessageCardDto(
      id: '2',
      templateCode: 'DEVICE_ABNORMAL',
      type: 'DEVICE',
      iconCode: 'device-alert',
      title: 'Device Abnormality Alert',
      label: 'Device Message',
      summary: 'An abnormality has been detected.',
      read: true,
      createTime: '1786100633000',
    );

    expect(dto.toDomain().timestamp, _expectedTimestamp(1786100633000));
  });

  test('accepts business codes 0 and 200 and rejects other codes', () async {
    final successfulApi = _FakeNotificationMessageApi();
    final successfulSource = NotificationMessageRemoteDataSourceImpl(
      api: successfulApi,
    );
    final zeroCodeSource = NotificationMessageRemoteDataSourceImpl(
      api: _FakeNotificationMessageApi(code: 0),
    );
    final invalidSource = NotificationMessageRemoteDataSourceImpl(
      api: _FakeNotificationMessageApi(code: 100005),
    );

    final page = await successfulSource.fetchMessages(
      page: 1,
      pageSize: 20,
      requestId: 'request-1',
    );
    expect(page.records, isNotEmpty);
    expect(successfulApi.requestedCurrent, 1);
    expect(successfulApi.requestedSize, 20);
    await expectLater(
      zeroCodeSource.fetchMessages(
        page: 1,
        pageSize: 20,
        requestId: 'request-2',
      ),
      completes,
    );
    await expectLater(
      invalidSource.fetchMessages(
        page: 1,
        pageSize: 20,
        requestId: 'request-3',
      ),
      throwsA(isA<NotificationMessageRemoteException>()),
    );
  });

  test('accepts the real empty-object mark-all-read response', () async {
    final source = NotificationMessageRemoteDataSourceImpl(
      api: _FakeNotificationMessageApi(),
    );

    await expectLater(
      source.markAllRead(requestId: 'mark-all-read-1'),
      completes,
    );
  });
}

String _expectedTimestamp(int milliseconds) {
  final value = DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
      '${twoDigits(value.second)}';
}

class _FakeNotificationMessageApi implements NotificationMessageApi {
  _FakeNotificationMessageApi({this.code = 200});

  final int code;
  int? requestedCurrent;
  int? requestedSize;

  NotificationMessagePageDto get _page => const NotificationMessagePageDto(
    current: '1',
    size: '20',
    total: '1',
    records: [
      NotificationMessageCardDto(
        id: '2',
        templateCode: 'DEVICE_ABNORMAL',
        type: 'DEVICE',
        iconCode: 'device-alert',
        title: 'Device Abnormality Alert',
        label: 'Device Message',
        summary: 'An abnormality has been detected.',
        read: true,
        createTime: '1786100633000',
      ),
    ],
  );

  @override
  Future<ApiEnvelopeDto<NotificationMessagePageDto>> fetchMessages(
    int current,
    int size,
    Options options,
  ) async {
    requestedCurrent = current;
    requestedSize = size;
    return ApiEnvelopeDto(code: code, success: true, data: _page);
  }

  @override
  Future<ApiEnvelopeDto<NotificationMessageDetailDto>> fetchMessageDetail(
    String messageId,
    Options options,
  ) async => ApiEnvelopeDto(
    code: code,
    success: true,
    data: const NotificationMessageDetailDto(
      id: '2',
      templateCode: 'DEVICE_ABNORMAL',
      type: 'DEVICE',
      title: 'Device Abnormality Alert',
      label: 'Device Message',
      content: 'An abnormality has been detected.',
      mobileLink: null,
      read: true,
      createTime: '1786100633000',
    ),
  );

  @override
  Future<ApiEnvelopeDto<dynamic>> markAllRead(Options options) async =>
      ApiEnvelopeDto(code: code, success: true, data: <String, dynamic>{});

  @override
  Future<ApiEnvelopeDto<NotificationUnreadStateDto>> fetchUnreadState(
    Options options,
  ) async => ApiEnvelopeDto(
    code: code,
    success: true,
    data: const NotificationUnreadStateDto(hasUnread: true),
  );
}
