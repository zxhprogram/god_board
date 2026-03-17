import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

const String baseUrl = 'http://localhost:8080';
var dio = Dio(.new(baseUrl: baseUrl));
var logger = Logger(level: .all);
final pullingLogPodMap = Signal<Map<String, bool>>({});
