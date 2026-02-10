/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scandit_flutter_datacapture_barcode/scandit_flutter_datacapture_barcode.dart';
import 'package:scandit_flutter_datacapture_barcode/scandit_flutter_datacapture_barcode_ar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/capture_bloc.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  CaptureScreenState createState() => CaptureScreenState();
}

class CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver
    implements BarcodeArHighlightProvider, BarcodeArAnnotationProvider {
  final BarcodeArBloc bloc = BarcodeArBloc();

  BarcodeArView? barcodeArView;

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _loggedIn = false;
  bool _loginInProgress = false;
  String? _loginError;
  bool _rememberMe = false;

  CaptureScreenState() : super();

  @override
  void initState() {
    super.initState();
    bloc.init();
    bloc.onStateChanged = () {
      if (mounted) {
        setState(() {});
      }
    };
    WidgetsBinding.instance.addObserver(this);

    _loadSavedCredentials();

    barcodeArView = BarcodeArView.forModeWithViewSettingsAndCameraSettings(
      bloc.dataCaptureContext,
      bloc.barcodeAr,
      bloc.barcodeArViewSettings,
      bloc.cameraSettings,
    )
      ..highlightProvider = this
      ..annotationProvider = this;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _loggedIn ? _buildScannerScreen(context) : _buildLoginScreen(context),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      default:
        bloc.stopCapturing();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    bloc.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Future<BarcodeArHighlight?> highlightForBarcode(Barcode barcode) {
    return bloc.highlightForBarcode(barcode);
  }

  @override
  Future<BarcodeArAnnotation?> annotationForBarcode(Barcode barcode) async {
    return bloc.annotationForBarcode(barcode);
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRemember = prefs.getBool('saved_remember') ?? false;
    final savedLogin = prefs.getString('saved_login') ?? '';
    final savedPass = prefs.getString('saved_pass') ?? '';

    if (!mounted) return;

    setState(() {
      _rememberMe = savedRemember;
      if (savedRemember) {
        _userController.text = savedLogin;
        _passController.text = savedPass;
      }
    });
  }

  Widget _buildLoginScreen(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0B0C), Color(0xFF121215)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: const Color(0xFF1B1C1F),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'VENONS:AVTOMARKS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4A6EFF),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Вход',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Введите логин и пароль для начала сборки.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB6B7BB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Логин',
                    style: TextStyle(fontSize: 13, color: Color(0xFFD7D8DC)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      hintText: 'user',
                      filled: true,
                      fillColor: const Color(0xFF0F1013),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A2B30)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Пароль',
                    style: TextStyle(fontSize: 13, color: Color(0xFFD7D8DC)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: const Color(0xFF0F1013),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A2B30)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Запомнить меня',
                        style: TextStyle(fontSize: 13, color: Color(0xFFD7D8DC)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loginError != null) ...[
                    Text(
                      _loginError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton(
                    onPressed: _loginInProgress ? null : _onLoginPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loginInProgress
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Войти',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerScreen(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: barcodeArView ?? Container(color: Colors.black),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _buildToolbar(context),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: _buildFloatingActions(context),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x66101114),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2B30)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () async {
              await bloc.stopCapturing();
              if (!mounted) return;
              setState(() {
                _loggedIn = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Выход'),
          ),
          const SizedBox(width: 8),
          _buildPill('QR: ${bloc.qrCodes.length}/${bloc.countQr}'),
          const SizedBox(width: 8),
          _buildPill('ШК: ${bloc.itemBarcode != null ? 1 : 0}/1'),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF0F1013),
                border: Border.all(color: const Color(0xFF2A2B30)),
              ),
              child: Text(
                bloc.flowHintText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFFD7D8DC)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: bloc.rows.isEmpty ? null : () => _showListModal(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0x66101114),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2A2B30)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Список кодов'),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: bloc.rows.isEmpty ? null : bloc.clearAll,
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0x66101114),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF2A2B30)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Очистить'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: bloc.canSave ? () => _onSavePressed(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF0F1013),
        border: Border.all(color: const Color(0xFF2A2B30)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFFD7D8DC)),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    setState(() {
      _loginInProgress = true;
      _loginError = null;
    });

    try {
      await bloc.login(_userController.text, _passController.text);
      
      // Пересоздаём BarcodeArView с обновлённым контекстом и BarcodeAr
      _recreateBarcodeArView();
      
      // сохранить/очистить сохранённые учётные данные
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_login', _userController.text.trim());
        await prefs.setString('saved_pass', _passController.text);
        await prefs.setBool('saved_remember', true);
      } else {
        await prefs.remove('saved_login');
        await prefs.remove('saved_pass');
        await prefs.setBool('saved_remember', false);
      }

      // запрашиваем доступ к камере и сразу запускаем сканирование
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _loginError = 'Нужно разрешить доступ к камере';
        });
        return;
      }

      await bloc.startCapturing();

      setState(() {
        _loggedIn = true;
      });
    } catch (e) {
      setState(() {
        _loginError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loginInProgress = false;
        });
      }
    }
  }

  void _recreateBarcodeArView() {
    barcodeArView = BarcodeArView.forModeWithViewSettingsAndCameraSettings(
      bloc.dataCaptureContext,
      bloc.barcodeAr,
      bloc.barcodeArViewSettings,
      bloc.cameraSettings,
    )
      ..highlightProvider = this
      ..annotationProvider = this;
  }

  Future<void> _onSavePressed(BuildContext context) async {
    try {
      await bloc.saveToServer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сохранено')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  void _showListModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1013),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (context, controller) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Отсканированные коды',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: const Color(0xFF1B1C1F),
                                  border: Border.all(color: Color(0xFF2A2B30)),
                                ),
                                child: Text(
                                  '${bloc.rows.length} шт.',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFD7D8DC)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF2A2B30)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Закрыть'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF2A2B30)),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        itemCount: bloc.rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF2A2B30)),
                        itemBuilder: (context, index) {
                          final row = bloc.rows[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            title: Text(
                              row.data,
                              style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                bloc.removeRowByData(row.data);
                                setModalState(() {});
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFFB91C1C),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text(
                                'Удалить',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
