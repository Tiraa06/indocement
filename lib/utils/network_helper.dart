import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

Future<T?> safeRequest<T>(
  BuildContext context,
  Future<T> Function() request, {
  Duration timeout = const Duration(seconds: 10),
  int maxRetry = 2,
}) async {
  int attempt = 0;
  while (attempt < maxRetry) {
    try {
      final result = await request().timeout(timeout);
      return result;
    } on TimeoutException catch (_) {
      attempt++;
      if (attempt >= maxRetry) {
        Navigator.pushReplacementNamed(context, '/error404');
        return null;
      }
    } on SocketException catch (_) {
      attempt++;
      if (attempt >= maxRetry) {
        Navigator.pushReplacementNamed(context, '/error404');
        return null;
      }
    } catch (e) {
      attempt++;
      if (attempt >= maxRetry) {
        Navigator.pushReplacementNamed(context, '/error404');
        return null;
      }
    }
  }
  return null;
}
