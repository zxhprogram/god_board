import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

const String baseUrl = 'http://localhost:8080';
var dio = Dio(.new(baseUrl: baseUrl));
var logger = Logger(level: .all);

