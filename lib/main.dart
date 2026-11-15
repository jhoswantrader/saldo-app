import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'recargas_page.dart';
import 'animated_background.dart';
import 'biometric_service.dart';
import 'auth_service.dart';
import 'login.dart';

// ============================================================
// CREDENCIALES DE SUPER900
// ============================================================


// ============================================================
// GOOGLE / GMAIL
// ============================================================

const List<String> gmailScopes = <String>[
  'https://www.googleapis.com/auth/gmail.readonly',
];

// ============================================================
// MODELO DE MOVIMIENTO
// ============================================================

class Movimiento {
  final String fecha;
  final String codigo;
  final String tipo;
  final String valorBs;
  final String valorUsd;
  final String restanteUsd;

  Movimiento({
    required this.fecha,
    required this.codigo,
    required this.tipo,
    required this.valorBs,
    required this.valorUsd,
    required this.restanteUsd,
  });

  bool get esAbono => tipo.toUpperCase() == 'ABONO';
}

// ============================================================
// APP
// ============================================================




void main() {
  runApp(const SaldoApp());
}

class SaldoApp extends StatelessWidget {
  const SaldoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Saldo',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const SaldoPage(),
    );
  }
}

// ============================================================
// PÁGINA PRINCIPAL
// ============================================================

class SaldoPage extends StatefulWidget {
  const SaldoPage({super.key});

  @override
  State<SaldoPage> createState() => _SaldoPageState();
}

class _SaldoPageState extends State<SaldoPage>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // WEBVIEW
  // ==========================================================

WebViewController? controller;

  // ==========================================================
  // GOOGLE
  // ==========================================================

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final Future<void> _googleInitialization;

  // ==========================================================
  // TIMERS / ESTADO
  // ==========================================================

  Timer? _loginTimer;

  bool mostrandoLoader = true;

String _entidadSuper900 = 'V';
String _usuarioSuper900 = '';
String _claveSuper900 = '';

bool _credencialesCargadas = false;

  bool _loginEjecutado = false;
  bool _loginEsperandoResultado = false;
  bool _nuevoInicioSesion = false;
  bool _otpProcesando = false;
  bool _autenticacionCompletada = false;
  bool _webViewIniciado = false;
  int _loginKey = 0;
  bool _credencialesGuardadas = false;

  String estado = 'Conectando...';

  // ==========================================================
  // DATOS DEL DASHBOARD
  // ==========================================================

  String saldoBs = '0,00';
  String saldoUsd = '0.00';
  String tasaBcv = '0.00';

  List<Movimiento> movimientos = [];
  Completer<List<Recarga>>? _recargasCompleter;

  // ==========================================================
  // TARJETA 3D
  // ==========================================================

  bool tarjetaVolteada = false;
  String cedula = 'Cargando...';

  Uint8List? codigoBarras;
  bool _cargandoTarjetaVirtual = false;
  bool _tarjetaVirtualCargada = false;
  bool _perfilCargado = false;

  // ==========================================================
  // INICIALIZAR
  // ==========================================================

 @override
void initState() {
  super.initState();

  _googleInitialization = _inicializarGoogle();

  _inicializarAplicacion();
}


Future<void> _inicializarAplicacion() async {
  debugPrint('=====================================');
  debugPrint('AUTH: INICIANDO APLICACIÓN');
  debugPrint('=====================================');

  await _cargarCredencialesGuardadas();

  if (!mounted) return;

  if (!_credencialesCargadas) {
    debugPrint(
      'AUTH: PRIMER INICIO - MOSTRANDO LOGIN',
    );

    setState(() {
      mostrandoLoader = false;
      estado = 'Esperando inicio de sesión...';
    });

    return;
  }

  debugPrint(
    'AUTH: CREDENCIALES EXISTENTES - INICIANDO WEBVIEW',
  );

  _iniciarWebView();
}


void _iniciarWebView() {
  debugPrint('AUTH: CREANDO WEBVIEW...');

  try {
    // Si ya existe un controller, lo reutilizamos.
    if (controller == null) {
      controller = WebViewController();

      debugPrint(
        'AUTH: CONTROLLER CREADO',
      );

      controller!
        ..setJavaScriptMode(
          JavaScriptMode.unrestricted,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
  debugPrint(
    'PÁGINA INICIADA: $url',
  );

  if (!mounted) return;

  // Las páginas auxiliares se cargan completamente
  // en segundo plano sin mostrar el loader.
  if (url.contains('/panel/tarjeta_virtual') ||
      url.contains('/panel/perfil')) {
    return;
  }

  setState(() {
    mostrandoLoader = true;
    estado = 'Cargando...';
  });
},

            onPageFinished: (url) {
              debugPrint(
                'PÁGINA TERMINADA: $url',
              );

              if (!mounted) return;

              setState(() {
                estado = 'Comprobando acceso...';
              });

              _procesarPagina();
            },

            onWebResourceError: (error) {
              debugPrint(
                'ERROR WEBVIEW: '
                '${error.errorCode} - '
                '${error.description}',
              );
            },
          ),
        );

      debugPrint(
        'AUTH: WEBVIEW CREADO',
      );
    } else {
      debugPrint(
        'AUTH: REUTILIZANDO WEBVIEW EXISTENTE',
      );
    }

    _webViewIniciado = true;

    if (mounted) {
      setState(() {
        _credencialesCargadas = true;
      });
    }

    debugPrint(
      'AUTH: ESTADO CAMBIADO - MOSTRANDO WEBVIEW',
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (!mounted) return;

        if (controller == null) {
          debugPrint(
            'AUTH: ERROR - CONTROLLER NULO',
          );
          return;
        }

        try {
          debugPrint(
            'AUTH: EJECUTANDO LOAD REQUEST...',
          );

          await controller!.loadRequest(
            Uri.parse(
              'https://super900.com/areacliente',
            ),
          );

          debugPrint(
            'AUTH: LOAD REQUEST EJECUTADO',
          );
        } catch (e) {
          debugPrint(
            'AUTH: ERROR EN LOAD REQUEST: $e',
          );
        }
      },
    );
  } catch (e, stackTrace) {
    debugPrint(
      'AUTH: ERROR CREANDO WEBVIEW: $e',
    );

    debugPrint(
      'AUTH: STACKTRACE: $stackTrace',
    );

    if (mounted) {
      setState(() {
        _webViewIniciado = false;
        _credencialesCargadas = false;
        mostrandoLoader = false;
        estado = 'No fue posible iniciar sesión.';
      });
    }
  }
}
  // ==========================================================
  // INICIALIZAR GOOGLE
  // ==========================================================

  Future<void> _inicializarGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '106388818689-3kf2lthd5dsg60kshego6t8qfrsjnvft.apps.googleusercontent.com',
      );

      debugPrint(
        'GMAIL: GOOGLE INICIALIZADO',
      );
    } catch (e) {
      debugPrint(
        'GMAIL: ERROR INICIALIZANDO GOOGLE: $e',
      );

      rethrow;
    }
  }


Future<void> _iniciarSesionDesdeLogin(
  String entidad,
  String codigo,
  String clave,
) async {
  debugPrint('=====================================');
  debugPrint('AUTH: NUEVO INICIO DE SESIÓN');
  debugPrint('=====================================');

  _entidadSuper900 = entidad;
  _usuarioSuper900 = codigo;
  _claveSuper900 = clave;

  _loginEjecutado = false;
  _otpProcesando = false;
  _autenticacionCompletada = false;
  _loginEsperandoResultado = false;
  _credencialesGuardadas = false;
  _nuevoInicioSesion = true;
  _tarjetaVirtualCargada = false;
  _perfilCargado = false;
  codigoBarras = null;
  cedula = 'Cargando...';

  if (mounted) {
    setState(() {
      mostrandoLoader = true;
      estado = 'Iniciando sesión...';
    });
  }

  debugPrint(
    'AUTH: DATOS DEL LOGIN RECIBIDOS',
  );

  // Primero creamos el WebView.
  _iniciarWebView();

  debugPrint(
    'AUTH: WEBVIEW INICIADO',
  );
}



Future<void> _cargarCredencialesGuardadas() async {
  debugPrint('=====================================');
  debugPrint('AUTH: BUSCANDO CREDENCIALES GUARDADAS');
  debugPrint('=====================================');

  try {
    final credenciales =
        await AuthService().obtenerCredenciales();

    if (credenciales == null) {
      debugPrint(
        'AUTH: NO HAY CREDENCIALES GUARDADAS',
      );

      if (mounted) {
        setState(() {
          _credencialesCargadas = false;
        });
      }

      return;
    }

    _entidadSuper900 =
        credenciales['entidad'] ?? 'V';

    _usuarioSuper900 =
        credenciales['codigo'] ?? '';

    _claveSuper900 =
        credenciales['clave'] ?? '';

    debugPrint(
      'AUTH: CREDENCIALES ENCONTRADAS',
    );

    debugPrint(
      'AUTH: ENTIDAD = $_entidadSuper900',
    );

    debugPrint(
      'AUTH: USUARIO CARGADO = '
      '${_usuarioSuper900.isNotEmpty ? "SÍ" : "NO"}',
    );

    debugPrint(
      'AUTH: CLAVE CARGADA = '
      '${_claveSuper900.isNotEmpty ? "SÍ" : "NO"}',
    );

    if (mounted) {
      setState(() {
        _credencialesCargadas = true;
      });
    }
  } catch (e) {
    debugPrint(
      'AUTH: ERROR LEYENDO CREDENCIALES: $e',
    );

    if (mounted) {
      setState(() {
        _credencialesCargadas = false;
      });
    }
  }
}


Future<void> _cargarCodigoBarras() async {
  if (_cargandoTarjetaVirtual) {
    return;
  }

  _cargandoTarjetaVirtual = true;

  debugPrint('=====================================');
  debugPrint('TARJETA: CARGANDO CÓDIGO DE BARRAS');
  debugPrint('=====================================');

  try {
    await controller!.loadRequest(
      Uri.parse(
        'https://super900.com/panel/tarjeta_virtual',
      ),
    );

    debugPrint(
      'TARJETA: PÁGINA DE TARJETA VIRTUAL CARGANDO',
    );
  } catch (e) {
    debugPrint(
      'TARJETA: ERROR CARGANDO TARJETA VIRTUAL: $e',
    );

    _cargandoTarjetaVirtual = false;
  }
}

  // ==========================================================
  // PROCESAR LA PÁGINA ACTUAL
  // ==========================================================

Future<void> _cargarPerfil() async {
  debugPrint('PERFIL: CARGANDO DATOS DEL USUARIO');

  try {
    await controller?.loadRequest(
      Uri.parse('https://super900.com/panel/perfil'),
    );
  } catch (e) {
    debugPrint('PERFIL: ERROR CARGANDO PERFIL: $e');
    _perfilCargado = true;
    if (mounted) {
      setState(() {
        cedula = 'No disponible';
      });
    }
  }
}

Future<List<Recarga>> _cargarRecargas() async {
  debugPrint('=====================================');
  debugPrint('RECARGAS: CARGANDO SUPER900');
  debugPrint('=====================================');

  _recargasCompleter = Completer<List<Recarga>>();

  try {
    await controller?.loadRequest(
      Uri.parse(
        'https://super900.com/webmanager/pagos',
      ),
    );

    final resultado =
        await _recargasCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException(
          'Tiempo agotado cargando las recargas.',
        );
      },
    );

    debugPrint(
      'RECARGAS: ${resultado.length} REGISTROS CARGADOS',
    );

    return resultado;
  } finally {
    _recargasCompleter = null;
  }
}


// ==========================================================
// REGRESAR AL DASHBOARD
// ==========================================================

Future<void> _volverAlDashboard() async {
  debugPrint('=====================================');
  debugPrint('WALLET 900: REGRESANDO AL DASHBOARD');
  debugPrint('=====================================');

  try {
    await controller?.loadRequest(
      Uri.parse(
        'https://super900.com/panel/dashboard',
      ),
    );

    debugPrint(
      'WALLET 900: DASHBOARD CARGANDO',
    );
  } catch (e) {
    debugPrint(
      'WALLET 900: ERROR REGRESANDO AL DASHBOARD: $e',
    );
  }
}


Future<void> _procesarPagina() async {
  await Future.delayed(
    const Duration(milliseconds: 500),
  );

  if (!mounted) return;

  try {
    final url = await controller!.currentUrl() ?? '';

    final resultado =
        await controller!.runJavaScriptReturningResult(
      '''
      (() => {
        const body = document.body?.innerText || '';

        const login =
            document.querySelector('#formLogin');

        const otp =
            document.querySelector('#formLoginOtp');

        const dashboard =
            window.location.pathname.includes('/panel/dashboard');

        const pagos =
            window.location.pathname.includes('/webmanager/pagos');

        const tarjeta =
            window.location.pathname.includes('/panel/tarjeta_virtual');

        const perfil =
            window.location.pathname.includes('/panel/perfil');

        // PERFIL: EXTRAER IDENTIFICACIÓN DE LA CUENTA ACTIVA
        if (perfil) {
          const bloques = Array.from(
            document.querySelectorAll('.dat-client')
          );

          const bloqueIdentificacion = bloques.find((bloque) => {
            const titulo = bloque.querySelector('h4')?.innerText || '';
            return titulo.toLowerCase().includes('número de identificación');
          });

          const identificacion =
            bloqueIdentificacion?.querySelector('span')?.innerText.trim() || '';

          return JSON.stringify({
            tipo: 'PERFIL',
            cedula: identificacion
          });
        }

        // TARJETA VIRTUAL
        if (tarjeta) {
          const imagen =
              document.querySelector(
                'img[alt="Código de barras"]'
              );

          return JSON.stringify({
            tipo: 'TARJETA',
            codigoBarras: imagen
                ? imagen.src
                : ''
          });
        }
        // =====================================================
        // RECARGAS
        // =====================================================
        if (pagos) {
          const filas = Array.from(
            document.querySelectorAll('#consultas-table > li')
          );

          const recargas = filas.map((li) => {
            const row = li.querySelector('.row');

            const columnas = row
                ? Array.from(row.children)
                : [];

            const texto = (indice) =>
                columnas[indice]?.innerText.trim() || '';

            return {
              codigo: texto(0),
              fecha: texto(2),
              monto: texto(3),
              moneda: texto(4),
              estado: texto(5),
            };
          });

          return JSON.stringify({
            tipo: 'RECARGAS',
            recargas: recargas,
          });
        }


        // =====================================================
        // DASHBOARD
        // =====================================================
        if (dashboard) {
          return JSON.stringify({
            tipo: 'DASHBOARD',
            texto: body
          });
        }


        // =====================================================
        // OTP
        // =====================================================
        if (otp) {
          return JSON.stringify({
            tipo: 'OTP',
            texto: body
          });
        }


        // =====================================================
        // LOGIN
        // =====================================================
        if (login) {
          return JSON.stringify({
            tipo: 'LOGIN',
            texto: body
          });
        }


        // =====================================================
        // OTRA PÁGINA
        // =====================================================
        return JSON.stringify({
          tipo: 'OTRA',
          texto: body
        });
      })()
      ''',
    );

    debugPrint(
      'PÁGINA DETECTADA: $resultado',
    );


    // =======================================================
    // DECODIFICAR RESULTADO JAVASCRIPT
    // =======================================================

    dynamic datos = resultado;

    if (datos is String) {
      try {
        datos = jsonDecode(datos);
      } catch (_) {}
    }

    if (datos is String) {
      try {
        datos = jsonDecode(datos);
      } catch (_) {}
    }


    // =======================================================
    // VERIFICAR FORMATO
    // =======================================================

    if (datos is! Map) {
      debugPrint(
        'ERROR: FORMATO DE DATOS INESPERADO: $datos',
      );
      return;
    }


    final tipo =
        datos['tipo']?.toString() ?? '';

    final texto =
        datos['texto']?.toString() ?? '';


    debugPrint(
      'TIPO DETECTADO: $tipo',
    );


    // =======================================================
    // PERFIL: CÉDULA DEL USUARIO ACTUAL
    // =======================================================

    if (tipo == 'PERFIL') {
      final identificacion =
          datos['cedula']?.toString().trim() ?? '';

      if (identificacion.isNotEmpty) {
        if (mounted) {
          setState(() {
            cedula = identificacion;
          });
        }
        debugPrint('PERFIL: IDENTIFICACIÓN DEL USUARIO EXTRAÍDA');
      } else {
        if (mounted) {
          setState(() {
            cedula = 'No disponible';
          });
        }
        debugPrint('PERFIL: NO SE ENCONTRÓ NÚMERO DE IDENTIFICACIÓN');
      }

      _perfilCargado = true;
      await _volverAlDashboard();
      return;
    }

    // =======================================================
    // RECARGAS
    // =======================================================

if (tipo == 'TARJETA') {
  final src =
      datos['codigoBarras']?.toString() ?? '';

  debugPrint(
    'TARJETA: SRC DEL CÓDIGO OBTENIDO: '
    '${src.isNotEmpty ? "SÍ" : "NO"}',
  );

  const prefijo =
      'data:image/png;base64,';

  if (src.startsWith(prefijo)) {
    try {
      final base64Data =
          src.substring(prefijo.length);

      final bytes =
          base64Decode(base64Data);
if (mounted) {
  setState(() {
    codigoBarras =
        Uint8List.fromList(bytes);
  });
}

_tarjetaVirtualCargada = true;

debugPrint(
  'TARJETA: CÓDIGO DE BARRAS EXTRAÍDO '
  '(${bytes.length} bytes)',
);

      debugPrint(
        'TARJETA: CÓDIGO DE BARRAS EXTRAÍDO '
        '(${bytes.length} bytes)',
      );
    } catch (e) {
      debugPrint(
        'TARJETA: ERROR DECODIFICANDO BASE64: $e',
      );
    }
  } else {
    debugPrint(
      'TARJETA: EL SRC NO ES UN DATA PNG BASE64',
    );
  }

  _cargandoTarjetaVirtual = false;

  await _volverAlDashboard();

  return;
}




    if (tipo == 'RECARGAS') {
      debugPrint(
        'RECARGAS: PÁGINA DETECTADA',
      );

      try {
        final datosRecargas =
            datos['recargas'];

        final lista =
            <Recarga>[];

        if (datosRecargas is List) {
          for (final item in datosRecargas) {
            if (item is Map) {
              final recarga = Recarga(
                codigo:
                    item['codigo']?.toString() ?? '',
                fecha:
                    item['fecha']?.toString() ?? '',
                monto:
                    item['monto']?.toString() ?? '',
                moneda:
                    item['moneda']?.toString() ?? '',
                estado:
                    item['estado']?.toString() ?? '',
              );

              // Evitamos agregar filas vacías.
              if (recarga.codigo.isNotEmpty) {
                lista.add(recarga);
              }
            }
          }
        }

        debugPrint(
          'RECARGAS: ${lista.length} REGISTROS EXTRAÍDOS',
        );


        // ===================================================
        // ENTREGAR LAS RECARGAS A RecargasPage
        // ===================================================

        if (_recargasCompleter != null &&
            !_recargasCompleter!.isCompleted) {
          _recargasCompleter!.complete(lista);

          debugPrint(
            'RECARGAS: DATOS ENTREGADOS CORRECTAMENTE',
          );
        }
      } catch (e, stack) {
        debugPrint(
          'RECARGAS: ERROR PROCESANDO LISTA: $e',
        );

        debugPrint(
          'RECARGAS STACK: $stack',
        );

        if (_recargasCompleter != null &&
            !_recargasCompleter!.isCompleted) {
          _recargasCompleter!.completeError(e);
        }
      }

      return;
    }


    // =======================================================
    // LOGIN
    // =======================================================
  
if (tipo == 'LOGIN') {
  debugPrint('TIPO DETECTADO: LOGIN');

  final textoLogin =
      datos['texto']?.toString().toLowerCase() ?? '';

  if (_loginEsperandoResultado &&
    (textoLogin.contains(
          'usuario o clave incorrecta',
        ) ||
        textoLogin.contains(
          'error, usuario o clave incorrecta',
        ))) {
    debugPrint(
      'LOGIN: CREDENCIALES INCORRECTAS',
    );
    _loginEsperandoResultado = false;

    _loginTimer?.cancel();

    _loginEjecutado = false;
    _otpProcesando = false;

    if (mounted) {
      setState(() {
        _credencialesCargadas = false;
        _webViewIniciado = false;
        mostrandoLoader = false;
        estado = 'Credenciales incorrectas.';
        _loginKey++;
      });

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Credenciales incorrectas.',
            style: TextStyle(
              fontFamily: 'Tahoma',
            ),
          ),
          backgroundColor: Color(0xFFB3261E),
          duration: Duration(seconds: 3),
        ),
      );
    }

    return;
  }

  _hacerLogin();

  return;
}

    // =======================================================
    // OTP
    // =======================================================

    if (tipo == 'OTP') {
      debugPrint(
        'OTP DETECTADO',
      );

      _detectarOtp();

      return;
    }


   // =======================================================
// DASHBOARD
// =======================================================

if (tipo == 'DASHBOARD') {
  debugPrint(
    'DASHBOARD DETECTADO',
  );

  debugPrint(
    'DASHBOARD: EXTRAYENDO DATOS...',
  );

  _extraerDatosDashboard(texto);
  _extraerMovimientos(texto);

  // =====================================================
  // AUTENTICACIÓN DEL TELÉFONO
  // =====================================================

  if (!_autenticacionCompletada) {
    debugPrint(
      'AUTENTICACIÓN: INICIANDO VERIFICACIÓN DEL DISPOSITIVO...',
    );

    final biometricService = BiometricService();

    final puedeAutenticar =
        await biometricService.puedeAutenticar();

    debugPrint(
      'AUTENTICACIÓN: PUEDE AUTENTICAR = $puedeAutenticar',
    );

    if (!puedeAutenticar) {
      debugPrint(
        'AUTENTICACIÓN: EL DISPOSITIVO NO SOPORTA AUTENTICACIÓN',
      );

      if (mounted) {
        setState(() {
          mostrandoLoader = false;
          estado = 'Autenticación no disponible';
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        mostrandoLoader = true;
        estado = 'Verificando identidad...';
      });
    }

    debugPrint(
      'AUTENTICACIÓN: ABRIENDO DIÁLOGO DEL SISTEMA...',
    );

    final autenticado =
        await biometricService.autenticar();

    debugPrint(
      'AUTENTICACIÓN: RESULTADO = $autenticado',
    );

    if (!autenticado) {
      debugPrint(
        'AUTENTICACIÓN: ACCESO DENEGADO O CANCELADO',
      );

      if (mounted) {
        setState(() {
          mostrandoLoader = false;
          estado = 'Autenticación cancelada';
        });
      }

      return;
    }

    // SOLO MARCAMOS COMO COMPLETADA
    // DESPUÉS DE AUTENTICAR CORRECTAMENTE.
    _autenticacionCompletada = true;



    if (!_tarjetaVirtualCargada) {
  await _cargarCodigoBarras();
}

    if (_tarjetaVirtualCargada && !_perfilCargado) {
      await _cargarPerfil();
      return;
    }

    debugPrint(
      'AUTENTICACIÓN: ACCESO AUTORIZADO',
    );
  }


  // =====================================================
  // ACCESO CONCEDIDO
  // =====================================================

  if (mounted) {
    setState(() {
      mostrandoLoader = false;
      estado = 'Saldo actualizado';
    });
  }

if (!_credencialesGuardadas) {
  try {
    debugPrint(
      'AUTH: GUARDANDO CREDENCIALES...',
    );

    await AuthService().guardarCredenciales(
      entidad: _entidadSuper900,
      codigo: _usuarioSuper900,
      clave: _claveSuper900,
    );

    _credencialesGuardadas = true;

    debugPrint(
      'AUTH: CREDENCIALES GUARDADAS CORRECTAMENTE',
    );
  } catch (e, stackTrace) {
    debugPrint(
      'AUTH: ERROR GUARDANDO CREDENCIALES: $e',
    );

    debugPrint(
      'AUTH: STACKTRACE: $stackTrace',
    );
  }
}


  debugPrint(
    'DASHBOARD: ACCESO COMPLETADO',
  );

  return;
}

    // =======================================================
    // PÁGINA NO RECONOCIDA
    // =======================================================

    debugPrint(
      'PÁGINA NO RECONOCIDA: $url',
    );

  } catch (e, stack) {
    debugPrint(
      'ERROR PROCESANDO PÁGINA: $e',
    );

    debugPrint(
      'STACK: $stack',
    );
  }
}








  // ==========================================================
  // EXTRAER DATOS DEL DASHBOARD
  // ==========================================================

  void _extraerDatosDashboard(String texto) {
    try {
      debugPrint(
        '========== TEXTO DASHBOARD ==========',
      );

      debugPrint(texto);

      debugPrint(
        '=====================================',
      );

      String nuevoSaldoBs = '0,00';
      String nuevoSaldoUsd = '0.00';
      String nuevaTasaBcv = '0.00';

      // ======================================================
      // SALDO EN BOLÍVARES
      // ======================================================

      final saldoBsMatch = RegExp(
        r'(\d{1,3}(?:\.\d{3})*,\d{2})\s*Bs',
      ).firstMatch(texto);

      if (saldoBsMatch != null) {
        nuevoSaldoBs =
            saldoBsMatch.group(1) ?? '0,00';
      }

      // ======================================================
      // TASA BCV
      // ======================================================

      final tasaIndex =
          texto.indexOf('TASA DEL DÍA BCV');

      if (tasaIndex != -1) {
        final parteTasa =
            texto.substring(tasaIndex);

        final tasaMatch = RegExp(
          r'(\d+\.\d{2})\s*Bs',
        ).firstMatch(parteTasa);

        if (tasaMatch != null) {
          nuevaTasaBcv =
              tasaMatch.group(1) ?? '0.00';
        }
      }

      // ======================================================
      // SALDO EN DÓLARES
      // ======================================================

      final saldoIndex =
          texto.indexOf('SALDO TOTAL');

      if (saldoIndex != -1) {
        final parteSaldo =
            texto.substring(saldoIndex);

        final valoresUsd = RegExp(
          r'\b\d+\.\d{2}\b',
        ).allMatches(parteSaldo);

        if (valoresUsd.isNotEmpty) {
          nuevoSaldoUsd =
              valoresUsd.first.group(0) ?? '0.00';
        }
      }

      // ======================================================
      // GUARDAR DATOS
      // ======================================================

      if (!mounted) return;

      setState(() {
        saldoBs = nuevoSaldoBs;
        saldoUsd = nuevoSaldoUsd;
        tasaBcv = nuevaTasaBcv;
      });

      debugPrint(
        '-------------------------------------',
      );

      debugPrint(
        'SALDO BS: $saldoBs',
      );

      debugPrint(
        'SALDO USD: $saldoUsd',
      );

      debugPrint(
        'TASA BCV: $tasaBcv',
      );

      debugPrint(
        '-------------------------------------',
      );
    } catch (e, stack) {
      debugPrint(
        'DASHBOARD: ERROR EXTRAYENDO DATOS: $e',
      );

      debugPrint(
        'DASHBOARD STACK: $stack',
      );
    }
  }

  // ==========================================================
  // EXTRAER MOVIMIENTOS
  // ==========================================================

  void _extraerMovimientos(String texto) {
    try {
      final lineas = texto
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final nuevosMovimientos =
          <Movimiento>[];

      final patronFecha = RegExp(
        r'^\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2}$',
      );

      for (int i = 0;
          i < lineas.length;
          i++) {
        final linea = lineas[i];

        if (!patronFecha.hasMatch(linea)) {
          continue;
        }

        if (i + 5 >= lineas.length) {
          continue;
        }

        final fecha =
            lineas[i];

        final codigo =
            lineas[i + 1];

        final tipo =
            lineas[i + 2];

        final valorBs =
            lineas[i + 3];

        final valorUsd =
            lineas[i + 4];

        final restanteUsd =
            lineas[i + 5];

        if (tipo != 'DEBITO' &&
            tipo != 'ABONO') {
          continue;
        }

        nuevosMovimientos.add(
          Movimiento(
            fecha: fecha,
            codigo: codigo,
            tipo: tipo,
            valorBs: valorBs,
            valorUsd: valorUsd,
            restanteUsd: restanteUsd,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        movimientos =
            nuevosMovimientos;
      });

      debugPrint(
        'MOVIMIENTOS ENCONTRADOS: ${movimientos.length}',
      );

      for (final movimiento
          in movimientos) {
        debugPrint(
          '${movimiento.fecha} | '
          '${movimiento.codigo} | '
          '${movimiento.tipo} | '
          '${movimiento.valorBs} | '
          '${movimiento.valorUsd} | '
          '${movimiento.restanteUsd}',
        );
      }
    } catch (e, stack) {
      debugPrint(
        'MOVIMIENTOS: ERROR EXTRAYENDO: $e',
      );

      debugPrint(
        'MOVIMIENTOS STACK: $stack',
      );
    }
  }

  // ==========================================================
  // LOGIN AUTOMÁTICO
  // ==========================================================


void _hacerLogin() {
  if (_loginEjecutado) {
    return;
  }

  _loginEjecutado = true;
  _loginEsperandoResultado = true;
  debugPrint(
    'INICIANDO LOGIN AUTOMÁTICO...',
  );

  debugPrint(
    'LOGIN: ENTIDAD = $_entidadSuper900',
  );

  debugPrint(
    'LOGIN: USUARIO = $_usuarioSuper900',
  );

  debugPrint(
  'LOGIN: LONGITUD USUARIO = ${_usuarioSuper900.length}',
);

debugPrint(
  'LOGIN: CLAVE RECIBIDA = ${_claveSuper900.isNotEmpty ? "SÍ" : "NO"}',
);

debugPrint(
  'LOGIN: LONGITUD CLAVE = ${_claveSuper900.length}',
);

  if (mounted) {
    setState(() {
      estado = 'Iniciando sesión...';
    });
  }

  _loginTimer?.cancel();

  int intentos = 0;

  _loginTimer = Timer.periodic(
    const Duration(milliseconds: 300),
    (timer) async {
      intentos++;

      if (intentos > 30) {
        timer.cancel();

        _loginEjecutado = false;

        debugPrint(
          'LOGIN: TIEMPO_AGOTADO',
        );

        if (mounted) {
          setState(() {
            estado =
                'No se pudo iniciar sesión.';
          });
        }

        return;
      }

      try {
        final resultado =
            await controller!
                .runJavaScriptReturningResult(
          '''
          (() => {

            const entidad =
                document.querySelector('#entidad');

            const usuario =
                document.querySelector(
                  'input[name="codigo"]'
                );

            const clave =
                document.querySelector(
                  'input[name="clave"]'
                );

            const boton =
                document.querySelector(
                  '#formLogin button[type="submit"]'
                );

            if (!entidad) {
              return 'NO_ENTIDAD';
            }

            if (!usuario) {
              return 'NO_USUARIO';
            }

            if (!clave) {
              return 'NO_CLAVE';
            }

            if (!boton) {
              return 'NO_BOTON';
            }

         const setter =
    Object.getOwnPropertyDescriptor(
      HTMLSelectElement.prototype,
      'value'
    ).set;

setter.call(
  entidad,
  ${_jsString(_entidadSuper900)}
);

entidad.dispatchEvent(
  new Event(
    'input',
    { bubbles: true }
  )
);

entidad.dispatchEvent(
  new Event(
    'change',
    { bubbles: true }
  )
);
            usuario.focus();

            usuario.value =
                ${_jsString(_usuarioSuper900)};

            usuario.dispatchEvent(
              new Event(
                'input',
                { bubbles: true }
              )
            );

            usuario.dispatchEvent(
              new Event(
                'change',
                { bubbles: true }
              )
            );

            clave.focus();

            clave.value =
                ${_jsString(_claveSuper900)};

            clave.dispatchEvent(
              new Event(
                'input',
                { bubbles: true }
              )
            );

            clave.dispatchEvent(
              new Event(
                'change',
                { bubbles: true }
              )
            );

            if (
              entidad.value !==
              ${_jsString(_entidadSuper900)}
            ) {
              return 'ERROR_ENTIDAD';
            }

            if (
              usuario.value !==
              ${_jsString(_usuarioSuper900)}
            ) {
              return 'ERROR_USUARIO';
            }

            if (
              clave.value !==
              ${_jsString(_claveSuper900)}
            ) {
              return 'ERROR_CLAVE';
            }


            console.log(
  'SUPER900 LOGIN ENTIDAD REAL:',
  entidad.value
);

console.log(
  'SUPER900 LOGIN USUARIO REAL:',
  usuario.value
);

console.log(
  'SUPER900 LOGIN CLAVE CARGADA:',
  clave.value.length
);

            return 'DATOS_LISTOS';

          })();
          ''',
        );

        debugPrint(
          'LOGIN: $resultado',
        );

        if (resultado
            .toString()
            .contains('DATOS_LISTOS')) {
          timer.cancel();

          if (mounted) {
            setState(() {
              estado =
                  'Verificando credenciales...';
            });
          }

          debugPrint(
            'LOGIN: DATOS_CONFIRMADOS',
          );

          await Future.delayed(
            const Duration(
              milliseconds: 500,
            ),
          );

          final envio =
              await controller!
                  .runJavaScriptReturningResult(
            '''
            (() => {

              const boton =
                  document.querySelector(
                    '#formLogin button[type="submit"]'
                  );

              if (!boton) {
                return 'BOTON_NO_ENCONTRADO';
              }

              boton.click();

              return 'BOTON_PULSADO';

            })();
            ''',
          );

          debugPrint(
            'LOGIN: $envio',
          );
        }
      } catch (e) {
        debugPrint(
          'LOGIN: ERROR: $e',
        );
      }
    },
  );
}


  // ==========================================================
  // DETECTAR OTP
  // ==========================================================

  Future<void> _detectarOtp() async {
    if (_otpProcesando) {
      return;
    }

    _otpProcesando = true;
    _loginEjecutado = false;

    debugPrint(
      'OTP DETECTADO',
    );

    if (mounted) {
      setState(() {
        estado =
            'Esperando código de seguridad...';
      });
    }

    final resultado =
        await controller!
            .runJavaScriptReturningResult(
      '''
      (() => {

        const otp =
            document.getElementById('login_otp');

        if (!otp) {
          return 'NO_OTP';
        }

        return 'OTP_ENCONTRADO';

      })();
      ''',
    );

    debugPrint(
      'CAMPO OTP: $resultado',
    );

    if (!resultado
        .toString()
        .contains('OTP_ENCONTRADO')) {
      _otpProcesando = false;
      return;
    }

    // ========================================================
    // OBTENER OTP DESDE GMAIL
    // ========================================================

    final codigo =
        await _obtenerOtpDesdeGmail();

    if (codigo == null) {
      debugPrint(
        'OTP: NO SE ENCONTRÓ EL CÓDIGO',
      );

      if (mounted) {
        setState(() {
          estado =
              'No se encontró el código. Reintentando...';
        });
      }

      _otpProcesando = false;

      await Future.delayed(
        const Duration(seconds: 3),
      );

      if (mounted) {
        _detectarOtp();
      }

      return;
    }

    debugPrint(
      'OTP: CÓDIGO ENCONTRADO',
    );

    if (mounted) {
      setState(() {
        estado =
            'Código encontrado. Verificando...';
      });
    }

    // ========================================================
    // COLOCAR OTP EN SUPER900
    // ========================================================

    final resultadoOtp =
        await controller!
            .runJavaScriptReturningResult(
      '''
      (() => {

        const otp =
            document.getElementById('login_otp');

        if (!otp) {
          return 'NO_OTP';
        }

        otp.focus();

        otp.value =
            ${_jsString(codigo)};

        otp.dispatchEvent(
          new Event(
            'input',
            { bubbles: true }
          )
        );

        otp.dispatchEvent(
          new Event(
            'change',
            { bubbles: true }
          )
        );

        return 'OTP_CARGADO';

      })();
      ''',
    );

    debugPrint(
      'OTP: $resultadoOtp',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    // ========================================================
    // PULSAR VERIFICAR
    // ========================================================

    final verificar =
        await controller!
            .runJavaScriptReturningResult(
      '''
      (() => {

        const formulario =
            document.getElementById(
              'formLoginOtp'
            );

        if (!formulario) {
          return 'FORMULARIO_NO_ENCONTRADO';
        }

        const boton =
            formulario.querySelector(
              'button[type="submit"]'
            );

        if (boton) {
          boton.click();

          return 'VERIFICAR_PULSADO';
        }

        formulario.submit();

        return 'FORMULARIO_ENVIADO';

      })();
      ''',
    );

    debugPrint(
      'OTP: $verificar',
    );

    _otpProcesando = false;
  }

  // ==========================================================
  // GMAIL - OBTENER OTP
  // ==========================================================

Future<String?> _obtenerOtpDesdeGmail() async {
  try {
    debugPrint('GMAIL: INICIANDO...');

    await _googleInitialization;

    debugPrint('GMAIL: GOOGLE LISTO');

    if (mounted) {
      setState(() {
        estado = 'Conectando con Gmail...';
      });
    }

    // ========================================================
    // INTENTAR RECUPERAR LA CUENTA GOOGLE EXISTENTE
    // ========================================================

GoogleSignInAccount? usuarioGoogle;

try {
  // ========================================================
  // NUEVO INICIO DE SESIÓN
  // ========================================================

  if (_nuevoInicioSesion) {
    debugPrint(
      'GMAIL: NUEVO INICIO DE SESIÓN DETECTADO',
    );

    debugPrint(
      'GMAIL: CERRANDO CUENTA GOOGLE ANTERIOR...',
    );

    try {
      await _googleSignIn.signOut();

      debugPrint(
        'GMAIL: CUENTA GOOGLE ANTERIOR CERRADA',
      );
    } catch (e) {
      debugPrint(
        'GMAIL: ERROR CERRANDO CUENTA GOOGLE ANTERIOR: $e',
      );
    }

    // Ya no intentamos recuperar automáticamente
    // la cuenta anterior.
    usuarioGoogle = null;
  } else {
    // ======================================================
    // INICIO AUTOMÁTICO CON CREDENCIALES GUARDADAS
    // ======================================================

    debugPrint(
      'GMAIL: INTENTANDO RECUPERAR SESIÓN EXISTENTE...',
    );

    usuarioGoogle =
        await _googleSignIn.attemptLightweightAuthentication();

    if (usuarioGoogle != null) {
      debugPrint(
        'GMAIL: SESIÓN GOOGLE RECUPERADA: ${usuarioGoogle.email}',
      );
    } else {
      debugPrint(
        'GMAIL: NO HAY SESIÓN GOOGLE RECUPERABLE',
      );
    }
  }
} catch (e, stack) {
  debugPrint(
    'GMAIL: ERROR RECUPERANDO SESIÓN: $e',
  );

  debugPrint(
    'GMAIL: STACK: $stack',
  );
}
    // ========================================================
    // SI NO HAY SESIÓN, AUTENTICAR NORMALMENTE
    // ========================================================

    if (usuarioGoogle == null) {
      debugPrint(
        'GMAIL: SE NECESITA AUTENTICACIÓN GOOGLE',
      );

      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint(
          'GMAIL: AUTHENTICATE NO SOPORTADO',
        );
        return null;
      }

      try {
        usuarioGoogle = await _googleSignIn.authenticate(
          scopeHint: gmailScopes,
        );

        debugPrint(
          'GMAIL: AUTENTICACIÓN GOOGLE COMPLETADA',
        );
      } catch (e, stack) {
        debugPrint(
          'GMAIL: ERROR AUTENTICANDO GOOGLE: $e',
        );
        debugPrint(
          'GMAIL: STACK: $stack',
        );
        return null;
      }
    }

    if (usuarioGoogle == null) {
      debugPrint(
        'GMAIL: NO SE OBTUVO CUENTA GOOGLE',
      );
      return null;
    }

    debugPrint(
      'GMAIL: CUENTA ACTIVA: ${usuarioGoogle.email}',
    );


if (_nuevoInicioSesion) {
  debugPrint(
    'GMAIL: NUEVA CUENTA SELECCIONADA: ${usuarioGoogle.email}',
  );

  // Ya procesamos la elección para este inicio.
  _nuevoInicioSesion = false;
}
    // ========================================================
    // AUTORIZACIÓN GMAIL
    // ========================================================

    GoogleSignInClientAuthorization? authorization;

    try {
      debugPrint(
        'GMAIL: COMPROBANDO AUTORIZACIÓN EXISTENTE...',
      );

      authorization =
          await usuarioGoogle.authorizationClient
              .authorizationForScopes(
        gmailScopes,
      );

      if (authorization != null) {
        debugPrint(
          'GMAIL: AUTORIZACIÓN GMAIL YA EXISTE',
        );
      } else {
        debugPrint(
          'GMAIL: GMAIL TODAVÍA NO ESTÁ AUTORIZADO',
        );
      }
    } catch (e) {
      debugPrint(
        'GMAIL: ERROR COMPROBANDO AUTORIZACIÓN: $e',
      );
    }

    // ========================================================
    // PEDIR AUTORIZACIÓN SOLO SI HACE FALTA
    // ========================================================

    if (authorization == null) {
      debugPrint(
        'GMAIL: SOLICITANDO AUTORIZACIÓN GMAIL...',
      );

      try {
        authorization =
            await usuarioGoogle.authorizationClient
                .authorizeScopes(
          gmailScopes,
        );

        debugPrint(
          'GMAIL: AUTORIZACIÓN GMAIL COMPLETADA',
        );
      } catch (e, stack) {
        debugPrint(
          'GMAIL: ERROR AUTORIZANDO GMAIL: $e',
        );
        debugPrint(
          'GMAIL: STACK: $stack',
        );
        return null;
      }
    }

    if (authorization == null) {
      debugPrint(
        'GMAIL: NO SE OBTUVO AUTORIZACIÓN',
      );
      return null;
    }

    // ========================================================
    // CLIENTE GOOGLE APIS
    // ========================================================

    final auth.AuthClient client =
        authorization.authClient(
      scopes: gmailScopes,
    );

    final gmailApi = gmail.GmailApi(client);

    // ========================================================
    // BUSCAR OTP
    // ========================================================

    if (mounted) {
      setState(() {
        estado = 'Buscando código en Gmail...';
      });
    }

    for (int intento = 0; intento < 6; intento++) {
      debugPrint(
        'GMAIL: BUSCANDO OTP - '
        'INTENTO ${intento + 1}',
      );

      final lista =
          await gmailApi.users.messages.list(
        'me',
        q: 'newer_than:10m "Tu codigo de seguridad es"',
        maxResults: 10,
      );

      final mensajes =
          lista.messages ?? <gmail.Message>[];

      debugPrint(
        'GMAIL: MENSAJES ENCONTRADOS: '
        '${mensajes.length}',
      );

      for (final mensaje in mensajes) {
        final id = mensaje.id;

        if (id == null) {
          continue;
        }

        final completo =
            await gmailApi.users.messages.get(
          'me',
          id,
          format: 'full',
        );

        final texto =
            _extraerTextoMensaje(completo);

        final codigo =
            _extraerCodigoOtp(texto);

        if (codigo != null) {
          debugPrint(
            'GMAIL: OTP ENCONTRADO',
          );

          client.close();

          return codigo;
        }
      }

      if (intento < 5) {
        await Future.delayed(
          const Duration(seconds: 2),
        );
      }
    }

    client.close();

    debugPrint(
      'GMAIL: OTP NO ENCONTRADO',
    );

    return null;
  } catch (e, stack) {
    debugPrint(
      'GMAIL: ERROR GENERAL: $e',
    );

    debugPrint(
      'GMAIL STACK: $stack',
    );

    return null;
  }
}
  // ==========================================================
  // EXTRAER TEXTO DEL CORREO
  // ==========================================================

  String _extraerTextoMensaje(
    gmail.Message mensaje,
  ) {
    final partes = <String>[];

    void recorrer(
      gmail.MessagePart? parte,
    ) {
      if (parte == null) {
        return;
      }

      final mime =
          parte.mimeType ?? '';

      final body =
          parte.body;

      if (body != null &&
          body.data != null &&
          body.data!.isNotEmpty) {
        try {
          final decoded =
              utf8.decode(
            base64Url.decode(
              base64Url.normalize(
                body.data!,
              ),
            ),
            allowMalformed: true,
          );

          if (mime.contains('text/plain') ||
              mime.contains('text/html') ||
              mime.isEmpty) {
            partes.add(decoded);
          }
        } catch (e) {
          debugPrint(
            'GMAIL: ERROR DECODIFICANDO PARTE: $e',
          );
        }
      }

      final subpartes =
          parte.parts ??
              <gmail.MessagePart>[];

      for (final subparte
          in subpartes) {
        recorrer(subparte);
      }
    }

    recorrer(mensaje.payload);

    return partes.join('\n');
  }

  // ==========================================================
  // EXTRAER LOS 6 DÍGITOS
  // ==========================================================

  String? _extraerCodigoOtp(
    String texto,
  ) {
    final patronPrincipal = RegExp(
      r'Tu\s+c[oó]digo\s+de\s+seguridad\s+es\s*:\s*\*{0,2}\s*(\d{6})',
      caseSensitive: false,
    );

    final coincidencia =
        patronPrincipal.firstMatch(
      texto,
    );

    if (coincidencia != null) {
      return coincidencia.group(1);
    }

    final todos =
        RegExp(r'\b\d{6}\b')
            .allMatches(texto);

    for (final match in todos) {
      final codigo =
          match.group(0);

      if (codigo != null) {
        return codigo;
      }
    }

    return null;
  }

  // ==========================================================
  // DASHBOARD
  // ==========================================================

Future<void> _mostrarDashboard() async {
  debugPrint(
    'DASHBOARD DETECTADO',
  );

  debugPrint(
    'DASHBOARD: SESIÓN INICIADA CORRECTAMENTE',
  );

  // Solo guardamos las credenciales cuando el login
  // llegó realmente al dashboard.
  if (!_credencialesCargadas) {
    try {
      debugPrint(
        'AUTH: GUARDANDO CREDENCIALES...',
      );

      await AuthService().guardarCredenciales(
        entidad: _entidadSuper900,
        codigo: _usuarioSuper900,
        clave: _claveSuper900,
      );

      debugPrint(
        'AUTH: CREDENCIALES GUARDADAS CORRECTAMENTE',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'AUTH: ERROR GUARDANDO CREDENCIALES: $e',
      );

      debugPrint(
        'AUTH: STACKTRACE: $stackTrace',
      );
    }
  } else {
    debugPrint(
      'AUTH: CREDENCIALES YA ESTABAN CARGADAS',
    );
  }

  if (!mounted) return;

  setState(() {
    mostrandoLoader = false;
    estado = 'Sesión iniciada';
    _credencialesCargadas = true;
  });
}
  // ==========================================================
  // ESCAPAR TEXTO PARA JAVASCRIPT
  // ==========================================================

  String _jsString(String valor) {
    final escaped = valor
        .replaceAll(
          '\\',
          '\\\\',
        )
        .replaceAll(
          "'",
          "\\'",
        )
        .replaceAll(
          '\n',
          '\\n',
        )
        .replaceAll(
          '\r',
          '\\r',
        );

    return "'$escaped'";
  }

  // ==========================================================
  // FORMATEAR MOVIMIENTO
  // ==========================================================

  String _formatearFecha(String fecha) {
    try {
      final partes = fecha.split(' ');

      if (partes.length >= 2) {
        return '${partes[0]} · ${partes[1]}';
      }
    } catch (_) {}

    return fecha;
  }




  // ==========================================================
  // TARJETA
  // ==========================================================

  Widget _buildTarjeta() {
    return GestureDetector(
     onTap: () {
  setState(() {
    tarjetaVolteada = !tarjetaVolteada;
  });
},
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: tarjetaVolteada
              ? 3.141592653589793
              : 0,
        ),
        duration:
            const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
        builder:
            (context, angulo, child) {
          final mostrarReverso =
              angulo >
                  1.5707963267948966;

          final anguloVisual =
              mostrarReverso
                  ? angulo -
                      3.141592653589793
                  : angulo;

          return Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()
                  ..setEntry(
                    3,
                    2,
                    0.0012,
                  )
                  ..rotateY(
                    anguloVisual,
                  ),
            child: mostrarReverso
                ? _buildReverso()
                : _buildFrente(),
          );
        },
      ),
    );
  }

  // ==========================================================
  // FRENTE DE TARJETA
  // ==========================================================

 Widget _buildFrente() {
  return Container(
    width: double.infinity,
    height: 215,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FA),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.30),
          blurRadius: 18,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Stack(
      children: [
        // ==================================================
        // FONDO POLIGONAL DESVANECIDO
        // ==================================================
        Positioned.fill(
          child: CustomPaint(
            painter: _TarjetaPoligonalPainter(),
          ),
        ),

Positioned(
  left: 24,
  top: 25,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'SALDO DISPONIBLE',
        style: TextStyle(
          color: Color(0xFF3159A8),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),

      const SizedBox(height: 1),

      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '\$. $saldoUsd',
            style: const TextStyle(
              color: Color(0xFF172A46),
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'USD',
            style: TextStyle(
              color: Color(0xFF3159A8),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),

      const SizedBox(height: 0),

      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'Bs.$saldoBs',
            style: const TextStyle(
              color: Color(0xFF172A46),
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'VES',
            style: TextStyle(
              color: Color(0xFF3159A8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ],
  ),
),
     // ==================================================
// LOGO SUPER 900
// ==================================================
Positioned(
  top: 18,
  right: 24,
  child: Image.asset(
    'assets/logo_super900.png',
    width: 105,
    fit: BoxFit.contain,
  ),
),

        // ==================================================
        // FRANJA AZUL INFERIOR
        // ==================================================
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 78,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1688E8),
                  Color(0xFF1769C5),
                ],
              ),
            ),
          ),
        ),

        // ==================================================
        // LÍNEA VERDE
        // ==================================================
        Positioned(
          left: 19,
          bottom: 18,
          child: Container(
            width: 5,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFFC7F22B),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        // ==================================================
        // NOMBRE
        // ==================================================
        Positioned(
          left: 35,
          bottom: 39,
          right: 20,
          child: Text(
            'JHOSWAN DAVID CAMACHO THEIS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),

        // ==================================================
        // CÉDULA
        // ==================================================
        Positioned(
          left: 35,
          bottom: 12,
          child: Text(
            cedula,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}

  // ==========================================================
  // REVERSO DE TARJETA
  // ==========================================================

Widget _buildReverso() {
  return Container(
    width: double.infinity,
    height: 215,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF3F7FB),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 18,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Stack(
      children: [
        // ==================================================
        // FONDO POLIGONAL
        // ==================================================
        Positioned.fill(
          child: CustomPaint(
            painter: _TarjetaPoligonalPainter(),
          ),
        ),
// ==================================================
// LOGO SUPER 900 DESVANECIDO
// ==================================================
Positioned.fill(
  child: Center(
    child: Opacity(
      opacity: 0.080,
      child: Image.asset(
        'assets/logo_super900.png',
        width: 230,
        fit: BoxFit.contain,
      ),
    ),
  ),
),

        // ==================================================
        // TEXTO DEL REVERSO
        // ==================================================
        Positioned(
          left: 25,
          right: 25,
          top: 18,
          child: Column(
            children: const [
              Text(
                'ESTÁ PROHIBIDA LA NEGOCIACIÓN TOTAL O PARCIAL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              Text(
                'POR DINERO U OTROS BIENES Y SERVICIOS QUE NO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              Text(
                'SEAN COMERCIALIZADOS POR SUPER 900',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ESTA TARJETA ES PERSONAL E INTRANSFERIBLE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'SUPER900.COM/AREACLIENTE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        // ==================================================
        // COSTO DE REIMPRESIÓN
        // ==================================================
        Positioned(
          left: 25,
          right: 25,
          top: 92,
          child: const Text(
            'EL COSTO DE REIMPRESIÓN DE LA TARJETA EN CASO DE\n'
            'PÉRDIDA O EXTRAVÍO ES DE \$2',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF222222),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),

        // ==================================================
        // CÓDIGO DE BARRAS
        // ==================================================
        Positioned(
          left: 25,
          right: 25,
          bottom: 23,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
            clipBehavior: Clip.antiAlias,
           child: codigoBarras != null
    ? Image.memory(
        codigoBarras!,
        width: double.infinity,
        height: 42,
        fit: BoxFit.fill,
      )
    : const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
          ),
        ),
      ],
    ),
  );
}
  // ==========================================================
  // CABECERA
  // ==========================================================

Widget _buildHeader() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Expanded(
        child: Text(
          'Mi billetera',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      GestureDetector(
        onTap: () {
    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RecargasPage(
      cargarRecargas: _cargarRecargas,
      volverAlDashboard: _volverAlDashboard,
    ),
  ),
);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: Color(0xFFD5B45A),
                size: 17,
              ),
              SizedBox(width: 5),
              Text(
                'RECARGAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
  // ==========================================================
  // TASA BCV
  // ==========================================================

  Widget _buildTasaBcv() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF7F0DD),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons.currency_exchange,
              color:
                  Color(0xFF9D7A27),
              size: 19,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasa BCV',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tasa del día',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '$tasaBcv Bs',
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF151515),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESUMEN DE SALDOS
  // ==========================================================

  Widget _buildResumen() {
    return Row(
      children: [
        Expanded(
          child: _buildSaldoMiniCard(
            titulo: 'Bolívares',
            valor: saldoBs,
            moneda: 'Bs',
            icono:
                Icons.account_balance,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child: _buildSaldoMiniCard(
            titulo: 'Dólares',
            valor: saldoUsd,
            moneda: 'USD',
            icono:
                Icons.attach_money,
          ),
        ),
      ],
    );
  }

  Widget _buildSaldoMiniCard({
    required String titulo,
    required String valor,
    required String moneda,
    required IconData icono,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                size: 16,
                color:
                    Colors.black54,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                titulo,
                style:
                    const TextStyle(
                  fontSize: 11,
                  color:
                      Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            valor,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          Text(
            moneda,
            style:
                const TextStyle(
              fontSize: 10,
              color:
                  Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MOVIMIENTOS
  // ==========================================================

  Widget _buildMovimientos() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            const Text(
              'Movimientos',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            Text(
              '${movimientos.length}',
              style:
                  const TextStyle(
                color:
                    Color(0xFF9D7A27),
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        if (movimientos.isEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(
              22,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color:
                      Colors.grey.shade400,
                  size: 30,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'No hay movimientos.',
                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        ...movimientos.map(
          (movimiento) {
            return _buildMovimiento(
              movimiento,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMovimiento(
    Movimiento movimiento,
  ) {
    final abono =
        movimiento.esAbono;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration:
                BoxDecoration(
              color: abono
                  ? const Color(
                      0xFFE9F5EC,
                    )
                  : const Color(
                      0xFFF8EAEA,
                    ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              abono
                  ? Icons
                      .arrow_downward_rounded
                  : Icons
                      .arrow_upward_rounded,
              color: abono
                  ? const Color(
                      0xFF2E8B57,
                    )
                  : const Color(
                      0xFFC84B4B,
                    ),
              size: 19,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.tipo,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _formatearFecha(
                    movimiento.fecha,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Colors.black45,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  movimiento.codigo,
                  style:
                      const TextStyle(
                    fontSize: 9,
                    color:
                        Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '${movimiento.valorUsd} USD',
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                '${movimiento.valorBs} Bs',
                style:
                    const TextStyle(
                  fontSize: 10,
                  color:
                      Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INTERFAZ PRINCIPAL
  // ==========================================================

// ==========================================================
// BILLETERA
// ==========================================================
Widget _buildWallet() {
  return Stack(
    children: [
      const Positioned.fill(
        child: AnimatedPolygonBackground(),
      ),

      SafeArea(
        child: RefreshIndicator(
          onRefresh: _actualizarDatos,
          color: const Color(0xFF1769C5),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              18,
              15,
              18,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 22),

                _buildTarjeta(),

                const SizedBox(height: 18),

                Center(
                  child: Text(
                    'Toca la tarjeta para voltearla',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildResumen(),

                const SizedBox(height: 12),

                _buildTasaBcv(),

                const SizedBox(height: 25),

                _buildMovimientos(),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> _actualizarDatos() async {
  debugPrint('🔄 ACTUALIZANDO WALLET 900...');

  try {
    if (mounted) {
      setState(() {
        estado = 'Actualizando saldo...';
      });
    }

    // Reiniciamos el estado del flujo de login
    _loginEjecutado = false;
    _otpProcesando = false;

    // Recargar Super900 en segundo plano
    await controller!.reload();

    // Esperamos a que la página termine de procesarse.
    await Future.delayed(
      const Duration(seconds: 4),
    );

    debugPrint('✅ WALLET 900 ACTUALIZADA');
  } catch (e) {
    debugPrint('❌ ERROR ACTUALIZANDO WALLET: $e');
  }
}




  // ==========================================================
  // LOADER
  // ==========================================================

  Widget _buildLoader() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF111111),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child:
                  const Center(
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Color(0xFFD5B45A),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Mi Saldo',
              style: TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 40,
              ),
              child: Text(
                estado,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

@override
Widget build(BuildContext context) {
  // ====================================================
  // PRIMER INICIO
  // ====================================================
if (!_credencialesCargadas) {
  return LoginPage(
    key: ValueKey(_loginKey),
    onLogin: _iniciarSesionDesdeLogin,
  );
}
  // ====================================================
  // WALLET / WEBVIEW
  // ====================================================

  return Scaffold(
    body: Stack(
      children: [
        // ====================================================
        // WEBVIEW INVISIBLE
        // ====================================================

        if (_webViewIniciado)
          Positioned(
            left: 0,
            top: 0,
            width: 1,
            height: 1,
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.0,
                child: WebViewWidget(
                  controller: controller!,
                ),
              ),
            ),
          ),

        // ====================================================
        // WALLET
        // ====================================================

        if (!mostrandoLoader)
          Positioned.fill(
            child: _buildWallet(),
          ),

        // ====================================================
        // LOADER
        // ====================================================

        if (mostrandoLoader)
          Positioned.fill(
            child: _buildLoader(),
          ),
      ],
    ),
  );
}

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _loginTimer?.cancel();

    super.dispose();
  }
}

class _TarjetaPoligonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Fondo base
    paint.color = const Color(0xFFF3F7FB);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Polígono superior izquierdo
    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.38, 0)
      ..lineTo(size.width * 0.22, size.height * 0.48)
      ..lineTo(0, size.height * 0.35)
      ..close();

    paint.color = const Color(0xFFE6EDF5).withOpacity(0.55);
    canvas.drawPath(path1, paint);

    // Polígono central
    final path2 = Path()
      ..moveTo(size.width * 0.38, 0)
      ..lineTo(size.width * 0.73, 0)
      ..lineTo(size.width * 0.55, size.height * 0.55)
      ..lineTo(size.width * 0.22, size.height * 0.48)
      ..close();

    paint.color = const Color(0xFFDCE6F1).withOpacity(0.38);
    canvas.drawPath(path2, paint);

    // Polígono derecho
    final path3 = Path()
      ..moveTo(size.width * 0.73, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(size.width * 0.55, size.height * 0.55)
      ..close();

    paint.color = const Color(0xFFE8EEF5).withOpacity(0.60);
    canvas.drawPath(path3, paint);

    // Polígono inferior izquierdo
    final path4 = Path()
      ..moveTo(0, size.height * 0.35)
      ..lineTo(size.width * 0.22, size.height * 0.48)
      ..lineTo(size.width * 0.38, size.height)
      ..lineTo(0, size.height)
      ..close();

    paint.color = const Color(0xFFE0E8F1).withOpacity(0.45);
    canvas.drawPath(path4, paint);

    // Polígono central inferior
    final path5 = Path()
      ..moveTo(size.width * 0.22, size.height * 0.48)
      ..lineTo(size.width * 0.55, size.height * 0.55)
      ..lineTo(size.width * 0.72, size.height)
      ..lineTo(size.width * 0.38, size.height)
      ..close();

    paint.color = const Color(0xFFD8E3EF).withOpacity(0.32);
    canvas.drawPath(path5, paint);

    // Polígono derecho inferior
    final path6 = Path()
      ..moveTo(size.width * 0.55, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.72, size.height)
      ..close();

    paint.color = const Color(0xFFE9EFF5).withOpacity(0.50);
    canvas.drawPath(path6, paint);

    // Líneas diagonales muy suaves
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.48),
      Offset(size.width * 0.38, 0),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.48),
      Offset(size.width * 0.38, size.height),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.55),
      Offset(size.width * 0.73, 0),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.55),
      Offset(size.width * 0.72, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}