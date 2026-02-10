/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scandit_flutter_datacapture_barcode/scandit_flutter_datacapture_barcode.dart';
import 'package:scandit_flutter_datacapture_barcode/scandit_flutter_datacapture_barcode_ar.dart';
import 'package:scandit_flutter_datacapture_core/scandit_flutter_datacapture_core.dart';

import '../../bloc/bloc_base.dart';
import '../../managers/data_capture_context_manager.dart';

class ScannedRow {
  ScannedRow({
    required this.data,
    required this.symbology,
    required this.timestamp,
  });

  String data;
  Symbology symbology;
  DateTime timestamp;
}

class BarcodeArBloc extends Bloc implements BarcodeArListener, BarcodeArInfoAnnotationListener {
  final DataCaptureContextManager _dcManager = DataCaptureContextManager();

  late BarcodeAr _barcodeAr;

  BarcodeAr get barcodeAr => _barcodeAr;

  DataCaptureContext get dataCaptureContext => _dcManager.dataCaptureContext;

  late BarcodeArViewSettings _barcodeArViewSettings;

  BarcodeArViewSettings get barcodeArViewSettings => _barcodeArViewSettings;

  late CameraSettings _cameraSettings;

  CameraSettings get cameraSettings => _cameraSettings;

  /// Callback, устанавливаемый экраном, чтобы обновить UI при изменении состояния.
  VoidCallback? onStateChanged;

  // ---------------- Бизнес‑логика, портированная из example.html ----------------

  static const String _baseUrl = 'https://vaksina.pharmlux.uz/card_pay/hs/API';

  String? _authHeader;
  String _oldMarksText = '';
  String _oldMarksUpdateTimestamp = '';

  /// Кол-во QR, которое нужно отсканировать (получаем с сервера).
  int countQr = 100;

  /// Флаг, что мы уже запросили countQr у сервера.
  bool _checkedCountQr = false;

  /// Текущее состояние сканирования (камера включена/выключена).
  bool scanning = false;

  /// Уникальные QR (DataMatrix) коды.
  final Set<String> qrCodes = <String>{};

  /// Линейный штрихкод товара.
  String? itemBarcode;

  /// Локальный анти‑дубликатор.
  final Set<String> _recent = <String>{};

  /// Таблица отсканированных кодов.
  final List<ScannedRow> rows = <ScannedRow>[];

  // ---------------------------------------------------------------------------

  @override
  void init() {
    _barcodeArViewSettings = BarcodeArViewSettings();

    _cameraSettings = BarcodeAr.createRecommendedCameraSettings();
    _dcManager.camera.applySettings(_cameraSettings);

    // Включаем нужные типы штрихкодов.
    final barcodeArSettings = BarcodeArSettings()
      ..enableSymbologies({
        Symbology.ean13Upca,
        Symbology.ean8,
        Symbology.upce,
        Symbology.code39,
        Symbology.code128,
        Symbology.qr,
        Symbology.dataMatrix,
      });

    _barcodeAr = BarcodeAr(barcodeArSettings);
    _barcodeAr.addListener(this);
  }


  /// Переинициализирует BarcodeAr после обновления лицензии.
  Future<void> _reinitializeBarcodeAr() async {
    // Удаляем старый listener
    _barcodeAr.removeListener(this);

    // Пересоздаём BarcodeAr с теми же настройками
    final barcodeArSettings = BarcodeArSettings()
      ..enableSymbologies({
        Symbology.ean13Upca,
        Symbology.ean8,
        Symbology.code39,
        Symbology.code128,
        Symbology.dataMatrix,
      });

    _barcodeAr = BarcodeAr(barcodeArSettings);
    _barcodeAr.addListener(this);

    // Обновляем настройки камеры
    _cameraSettings = BarcodeAr.createRecommendedCameraSettings();
    _dcManager.camera.applySettings(_cameraSettings);
  }

  // ---------------- Аутентификация и работа с сервером ----------------

  Map<String, String> _headers() {
    return <String, String>{
      'Content-Type': 'application/json',
      if (_authHeader != null) 'Authorization': _authHeader!,
    };
  }

  /// Логин, полностью повторяющий поведение example.html (CheckAccess + getScanditToken + GetOldMarks).
  Future<void> login(String username, String password) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();
    if (trimmedUser.isEmpty || trimmedPass.isEmpty) {
      throw Exception('Введите логин и пароль');
    }

    final basic = 'Basic ${base64Encode(utf8.encode('$trimmedUser:$trimmedPass'))}';
    _authHeader = basic;

    // CheckAccess
    final checkRes = await http.get(
      Uri.parse('$_baseUrl/CheckAccess'),
      headers: <String, String>{
        'Authorization': basic,
        'Content-Type': 'application/json',
      },
    );

    if (checkRes.statusCode != 200) {
      throw Exception('Ошибка авторизации: ${checkRes.statusCode}');
    }

    // getScanditToken - получаем лицензионный ключ и устанавливаем его
    final tokenRes = await http.get(
      Uri.parse('$_baseUrl/getScanditToken'),
      headers: <String, String>{
        'Authorization': basic,
        'Content-Type': 'application/json',
      },
    );

    if (tokenRes.statusCode != 200) {
      throw Exception('Ошибка получения Scandit токена: ${tokenRes.statusCode}');
    }

    // Парсим ответ и обновляем лицензию
    final tokenJson = jsonDecode(tokenRes.body) as Map<String, dynamic>;
    final String scanditToken = tokenJson['data'] as String;

    // Обновляем лицензию в DataCaptureContextManager
    await _dcManager.updateLicenseKey(scanditToken);

    // Переинициализируем BarcodeAr с новым контекстом
    await _reinitializeBarcodeAr();

    await _getOldMarks();
  }

  Future<void> _getOldMarks() async {
    final uri = Uri.parse('$_baseUrl/GetOldMarks?timestamp=$_oldMarksUpdateTimestamp');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Ошибка сервера GetOldMarks: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data']?.toString() ?? '';
    final timestamp = json['timestamp']?.toString() ?? '';

    _oldMarksText += data;
    _oldMarksUpdateTimestamp = timestamp;
  }

  Future<void> _setCountQr(String gtin) async {
    if (_checkedCountQr) return;
    _checkedCountQr = true;

    final uri = Uri.parse('$_baseUrl/GetCount?gtin=$gtin');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Ошибка сервера GetCount: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final success = json['success'] == true;
    if (!success) {
      final message = json['message']?.toString() ?? 'Неизвестная ошибка';
      throw Exception('Ошибка GetCount: $message');
    }

    final dynamic value = json['data'];
    if (value is int) {
      countQr = value;
    } else if (value is String) {
      countQr = int.tryParse(value) ?? countQr;
    }

    _notify();
  }

  Future<void> saveToServer() async {
    if (qrCodes.length != countQr || itemBarcode == null) {
      throw Exception('Недостаточно данных для сохранения');
    }

    final payload = <String, dynamic>{
      'boxId': 'BOX-${DateTime.now().toIso8601String()}',
      'qrCodes': qrCodes.toList(),
      'itemBarcode': itemBarcode,
      'countQr': qrCodes.length,
      'countBarcode': itemBarcode != null ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final uri = Uri.parse('$_baseUrl/CreateAgregate');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('Ошибка сервера CreateAgregate: ${res.statusCode} ${res.body}');
    }

    await _getOldMarks();
    _checkedCountQr = false;
    _resetList();
  }

  // ---------------- Управление сканированием ----------------

  Future<void> startCapturing() async {
    scanning = true;
    await _dcManager.camera.switchToDesiredState(FrameSourceState.on);
    _notify();
  }

  Future<void> stopCapturing() async {
    scanning = false;
    await _dcManager.camera.switchToDesiredState(FrameSourceState.off);
    _notify();
  }

  Future<void> toggleScanning() async {
    if (scanning) {
      await stopCapturing();
    } else {
      await startCapturing();
    }
  }

  // ---------------- Обработка сессии MatrixScan AR ----------------

  @override
  Future<void> didUpdateSession(
    BarcodeAr barcodeAr,
    BarcodeArSession session,
    Future<FrameData> Function() getFrameData,
  ) async {
    if (session.addedTrackedBarcodes.isEmpty) {
      return;
    }

    for (final tracked in session.addedTrackedBarcodes) {
      final barcode = tracked.barcode;
      final data = barcode.data ?? '';
      final sym = barcode.symbology;

      if (data.isEmpty) continue;

      if (_isInvalid(data, sym)) {
        continue;
      }

      if (data.length > 16) {
        final gtin = data.substring(3, 16);
        unawaited(_setCountQr(gtin));
      }

      if (!_flowAccepts(sym)) {
        continue;
      }

      if (_isDuplicateNow(data)) {
        continue;
      }

      _addRow(data, sym, DateTime.now());
      _onAccepted(data, sym);
    }

    _notify();
  }

  bool _isInvalid(String data, Symbology sym) {
    final int prefixLen = math.min(31, data.length);
    final String prefix = data.substring(0, prefixLen);

    if (_oldMarksText.contains(prefix)) {
      return true;
    }

    if (sym == Symbology.dataMatrix) {
      return data.length < 80;
    } else {
      return data.length != 20;
    }
  }

  bool _flowAccepts(Symbology symbology) {
    if (qrCodes.length < countQr) {
      return symbology == Symbology.dataMatrix;
    }
    if (itemBarcode == null) {
      return symbology != Symbology.dataMatrix;
    }
    return false;
  }

  void _onAccepted(String data, Symbology symbology) {
    if (qrCodes.length < countQr && symbology == Symbology.dataMatrix) {
      qrCodes.add(data);
    } else if (qrCodes.length >= countQr && itemBarcode == null && symbology != Symbology.dataMatrix) {
      itemBarcode = data;
    }
  }

  bool _isDuplicateNow(String data) {
    if (_recent.contains(data)) {
      return true;
    }
    _recent.add(data);
    return false;
  }

  void _addRow(String data, Symbology sym, DateTime ts) {
    rows.insert(0, ScannedRow(data: data, symbology: sym, timestamp: ts));
  }

  void removeRowByData(String data) {
    final index = rows.indexWhere((r) => r.data == data);
    if (index < 0) return;

    final removed = rows.removeAt(index);

    _recent.remove(removed.data);

    if (removed.symbology == Symbology.dataMatrix) {
      qrCodes.remove(removed.data);
    } else if (itemBarcode == removed.data) {
      itemBarcode = null;
    }

    _notify();
  }

  void clearAll() {
    _resetList();
    _notify();
  }

  void _resetList() {
    rows.clear();
    _recent.clear();
    qrCodes.clear();
    itemBarcode = null;
    _checkedCountQr = false;
    countQr = 100;
  }

  // ---------------- AR аннотации / хайлайты ----------------

  Future<BarcodeArAnnotation?> annotationForBarcode(Barcode barcode) async {
    final annotation = BarcodeArInfoAnnotation(barcode)
      ..backgroundColor = const Color(0x66000000)
      ..width = BarcodeArInfoAnnotationWidthPreset.small;

    return annotation;
  }

  Future<BarcodeArHighlight?> highlightForBarcode(Barcode barcode) async {
    final data = barcode.data ?? '';
    final sym = barcode.symbology;

    final bool invalid = data.isEmpty ? false : _isInvalid(data, sym);

    final brush = invalid
        ? Brush(Colors.red.withOpacity(0.45), Colors.red.withOpacity(0.45), 3.0)
        : Brush(Colors.white, Colors.white, 1.0);

    final highlight = BarcodeArCircleHighlight(barcode, BarcodeArCircleHighlightPreset.dot)..brush = brush;
    return highlight;
  }

  @override
  void didTapInfoAnnotation(BarcodeArInfoAnnotation annotation) {}

  @override
  void didTapInfoAnnotationFooter(BarcodeArInfoAnnotation annotation) {}

  @override
  void didTapInfoAnnotationHeader(BarcodeArInfoAnnotation annotation) {}

  @override
  void didTapInfoAnnotationLeftIcon(BarcodeArInfoAnnotation annotation, int componentIndex) {}

  @override
  void didTapInfoAnnotationRightIcon(BarcodeArInfoAnnotation annotation, int componentIndex) {}

  String get flowHintText {
    if (qrCodes.length < countQr) {
      return 'Сначала отсканируйте $countQr QR';
    } else if (itemBarcode == null) {
      return 'Теперь отсканируйте 1 штрихкод';
    } else {
      return 'Готово к сохранению';
    }
  }

  bool get canSave => qrCodes.length == countQr && itemBarcode != null;

  void _notify() {
    onStateChanged?.call();
  }

  @override
  void dispose() {
    _barcodeAr.removeListener(this);
    super.dispose();
  }
}

