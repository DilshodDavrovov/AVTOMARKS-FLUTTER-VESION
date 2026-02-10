/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import 'package:scandit_flutter_datacapture_core/scandit_flutter_datacapture_core.dart';

class DataCaptureContextManager {
  DataCaptureContextManager._privateConstructor();

  static final DataCaptureContextManager _instance = DataCaptureContextManager._privateConstructor();

  factory DataCaptureContextManager() {
    return _instance;
  }

  late DataCaptureContext _dataCaptureContext;
  String _currentLicenseKey = '';

  final Camera _camera = Camera.defaultCamera!;

  Future<void> initialize() async {
    // Initialize with empty license key initially.
    // License key will be set after login via updateLicenseKey().
    _dataCaptureContext = DataCaptureContext.forLicenseKey('');

    // Set the camera as the frame source.
    _dataCaptureContext.setFrameSource(_camera);
  }

  /// Обновляет лицензионный ключ Scandit и пересоздаёт контекст.
  /// Это нужно вызывать после получения токена с сервера.
  Future<void> updateLicenseKey(String newLicenseKey) async {
    if (_currentLicenseKey == newLicenseKey) {
      return; // Уже установлена та же лицензия
    }

    _currentLicenseKey = newLicenseKey;

    // Сохраняем текущий frame source
    final currentFrameSource = _dataCaptureContext.frameSource;

    // Пересоздаём контекст с новой лицензией
    _dataCaptureContext = DataCaptureContext.forLicenseKey(newLicenseKey);

    // Восстанавливаем frame source
    if (currentFrameSource != null) {
      _dataCaptureContext.setFrameSource(currentFrameSource);
    } else {
      _dataCaptureContext.setFrameSource(_camera);
    }
  }

  DataCaptureContext get dataCaptureContext => _dataCaptureContext;

  Camera get camera => _camera;
}
