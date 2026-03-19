import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class HttpValidator extends Validator<String> {
  final String? message;

  const HttpValidator({this.message});

  @override
  FutureOr<ValidationResult?> validate(
    BuildContext context,
    String? value,
    FormValidationMode state,
  ) async {
    if (value == null) {
      return InvalidResult('不能为空', state: state);
    }
    try {
      var r = await Dio().head(value);
      if (r.statusCode != 200) {
        return InvalidResult('链接状态异常', state: state);
      }
    } catch (e) {
      return InvalidResult('链接状态异常', state: state);
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return false;
  }
}
