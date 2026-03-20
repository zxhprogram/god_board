import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String baseUrl = 'http://localhost:8080';
var dio = Dio(.new(baseUrl: baseUrl));
var logger = Logger(
  level: .all,
  printer: PrettyPrinter(
    colors: false,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
  output: MultiOutput([
    ConsoleOutput(),
    FileOutput(file: .new('client.log'), overrideExisting: false),
  ]),
);
final pullingLogPodMap = Signal<Map<String,WebSocketChannel?>>({});
