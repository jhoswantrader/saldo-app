
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final Future<void> Function(
    String entidad,
    String codigo,
    String clave,
  ) onLogin;

  const LoginPage({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _codigoController =
      TextEditingController();

  final TextEditingController _claveController =
      TextEditingController();

  String _entidad = 'V';

  bool _cargando = false;
  bool _ocultarClave = true;

  @override
  void dispose() {
    _codigoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final codigo =
        _codigoController.text.trim();

    final clave =
        _claveController.text;

    if (codigo.isEmpty) {
      _mostrarError(
        'Ingresa tu código de usuario.',
      );
      return;
    }

    if (clave.isEmpty) {
      _mostrarError(
        'Ingresa tu clave.',
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      await widget.onLogin(
        _entidad,
        codigo,
        clave,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });

        _mostrarError(
          'No fue posible iniciar sesión.',
        );
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            fontFamily: 'Tahoma',
          ),
        ),
        backgroundColor:
            const Color(0xFFB3261E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0054D1),
      body: SafeArea(
        child: Stack(
          children: [
            // =================================================
            // FONDO
            // =================================================

            Positioned.fill(
              child: CustomPaint(
                painter: _LoginBackgroundPainter(),
              ),
            ),

            // =================================================
            // CONTENIDO
            // =================================================

            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 430,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // =======================================
                      // LÍNEAS SUPERIORES
                      // =======================================

                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration:
                            const BoxDecoration(
                          color: Colors.white,
                        ),
                      ),

                      Container(
                        height: 2,
                        width: double.infinity,
                        margin:
                            const EdgeInsets.only(
                          top: 3,
                          bottom: 25,
                        ),
                        color: Colors.white
                            .withOpacity(.35),
                      ),

                      // =======================================
                      // LOGO
                      // =======================================

                      Image.network(
                        'https://super900.com/public/img/super900-hpdf.png',
                        height: 75,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Text(
                            '900',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight:
                                  FontWeight.bold,
                              fontFamily:
                                  'Arial',
                            ),
                          );
                        },
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        'Bienvenidos al Sistema',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w600,
                          fontFamily:
                              'Tahoma',
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // =======================================
                      // CONTENEDOR LOGIN
                      // =======================================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.fromLTRB(
                          22,
                          18,
                          22,
                          20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(
                            4,
                          ),
                        ),
                        child: Column(
                          children: [
                            // =================================
                            // AVISO DE SEGURIDAD
                            // =================================

                            Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFF0054D1,
                                ).withOpacity(.22),
                                border:
                                    Border.all(
                                  color:
                                      const Color(
                                    0xFF9CBDE8,
                                  ).withOpacity(.45),
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  5,
                                ),
                              ),
                              child: const Text(
                                'Estamos implementando cambios para mejorar la seguridad de tu cuenta. Ahora recibirás un código OTP en tu correo para iniciar sesión.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  color: Color(
                                    0xFFEAF5FF,
                                  ),
                                  fontSize: 12,
                                  height: 1.45,
                                  fontFamily:
                                      'Tahoma',
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            // =================================
                            // SENSIBLE A MAYÚSCULAS
                            // =================================

                            const Text(
                              'El sistema es sensible a minúsculas y mayúsculas.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily:
                                    'Tahoma',
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // =================================
                            // USUARIO
                            // =================================

                            Container(
                              height: 52,
                              decoration:
                                  BoxDecoration(
                                color: Colors.white
                                    .withOpacity(.10),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  3,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                  ),

                                  const Icon(
                                    Icons.person,
                                    color:
                                        Colors.white,
                                    size: 21,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  // ENTIDAD
                                  DropdownButtonHideUnderline(
                                    child:
                                        DropdownButton<
                                            String>(
                                      value:
                                          _entidad,
                                      dropdownColor:
                                          Colors.white,
                                      icon:
                                          const Icon(
                                        Icons
                                            .arrow_drop_down,
                                        color:
                                            Colors.white,
                                      ),
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize: 16,
                                        fontFamily:
                                            'Tahoma',
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'V',
                                          child: Text(
                                            'V',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.black,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'E',
                                          child: Text(
                                            'E',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.black,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'J',
                                          child: Text(
                                            'J',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.black,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'G',
                                          child: Text(
                                            'G',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.black,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '-',
                                          child: Text(
                                            '-',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged:
                                          _cargando
                                              ? null
                                              : (
                                                  valor,
                                                ) {
                                                  if (valor ==
                                                      null) {
                                                    return;
                                                  }

                                                  setState(
                                                    () {
                                                      _entidad =
                                                          valor;
                                                    },
                                                  );
                                                },
                                    ),
                                  ),

                                  Container(
                                    height: 28,
                                    width: 1,
                                    color: Colors
                                        .white
                                        .withOpacity(
                                      .25,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Expanded(
                                    child:
                                        TextField(
                                      controller:
                                          _codigoController,
                                      enabled:
                                          !_cargando,
                                      keyboardType:
                                          TextInputType
                                              .number,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize: 16,
                                        fontFamily:
                                            'Tahoma',
                                      ),
                                      decoration:
                                          const InputDecoration(
                                        hintText:
                                            '00000000',
                                        hintStyle:
                                            TextStyle(
                                          color:
                                              Colors.white54,
                                          fontFamily:
                                              'Tahoma',
                                        ),
                                        border:
                                            InputBorder
                                                .none,
                                        isDense:
                                            true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // =================================
                            // CLAVE
                            // =================================

                            Container(
                              height: 52,
                              decoration:
                                  BoxDecoration(
                                color: Colors.white
                                    .withOpacity(.10),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  3,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                  ),

                                  const Icon(
                                    Icons.key,
                                    color:
                                        Colors.white,
                                    size: 21,
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child:
                                        TextField(
                                      controller:
                                          _claveController,
                                      enabled:
                                          !_cargando,
                                      obscureText:
                                          _ocultarClave,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize: 16,
                                        fontFamily:
                                            'Tahoma',
                                      ),
                                      decoration:
                                          const InputDecoration(
                                        hintText:
                                            '●●●●●●',
                                        hintStyle:
                                            TextStyle(
                                          color:
                                              Colors.white54,
                                          fontFamily:
                                              'Tahoma',
                                        ),
                                        border:
                                            InputBorder
                                                .none,
                                        isDense:
                                            true,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    onPressed:
                                        _cargando
                                            ? null
                                            : () {
                                                setState(
                                                  () {
                                                    _ocultarClave =
                                                        !_ocultarClave;
                                                  },
                                                );
                                              },
                                    icon: Icon(
                                      _ocultarClave
                                          ? Icons
                                              .visibility_off
                                          : Icons
                                              .visibility,
                                      color:
                                          Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            // =================================
                            // BOTÓN INICIAR
                            // =================================

                            SizedBox(
                              width:
                                  double.infinity,
                              height: 48,
                              child:
                                  ElevatedButton(
                                onPressed:
                                    _cargando
                                        ? null
                                        : _iniciarSesion,
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      const Color(
                                    0xFF0066FF,
                                  ),
                                  foregroundColor:
                                      Colors.white,
                                  elevation: 0,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      3,
                                    ),
                                  ),
                                ),
                                child: _cargando
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color: Colors
                                              .white,
                                        ),
                                      )
                                    : const Text(
                                        'Iniciar',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              15,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          fontFamily:
                                              'Tahoma',
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // =================================
                            // RECUPERAR
                            // =================================

                            GestureDetector(
                              onTap: _cargando
                                  ? null
                                  : () {
                                      // Lo dejamos visualmente
                                      // como en Super900.
                                    },
                              child:
                                  const Text(
                                'Recuperar',
                                style:
                                    TextStyle(
                                  color: Color(
                                    0xFFB8B8B8,
                                  ),
                                  fontSize: 14,
                                  fontFamily:
                                      'Tahoma',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // =======================================
                      // LÍNEA INFERIOR
                      // =======================================

                      Container(
                        height: 2,
                        width: double.infinity,
                        color: Colors.white
                            .withOpacity(.30),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// FONDO DEL LOGIN
// ===========================================================

class _LoginBackgroundPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint();

    paint.color =
        const Color(0xFF0048B8);

    canvas.drawRect(
      Offset.zero &
          size,
      paint,
    );

    final path1 = Path();

    path1.moveTo(
      0,
      size.height * .15,
    );

    path1.lineTo(
      size.width * .45,
      0,
    );

    path1.lineTo(
      size.width * .75,
      0,
    );

    path1.lineTo(
      size.width * .15,
      size.height,
    );

    path1.lineTo(
      0,
      size.height,
    );

    path1.close();

    paint.color =
        const Color(0xFF0054D1)
            .withOpacity(.65);

    canvas.drawPath(
      path1,
      paint,
    );

    final path2 = Path();

    path2.moveTo(
      size.width,
      size.height * .25,
    );

    path2.lineTo(
      size.width * .55,
      0,
    );

    path2.lineTo(
      size.width,
      0,
    );

    path2.close();

    paint.color =
        const Color(0xFF0068E8)
            .withOpacity(.45);

    canvas.drawPath(
      path2,
      paint,
    );

    final path3 = Path();

    path3.moveTo(
      size.width,
      size.height,
    );

    path3.lineTo(
      size.width * .55,
      size.height,
    );

    path3.lineTo(
      size.width,
      size.height * .55,
    );

    path3.close();

    paint.color =
        const Color(0xFF003B9A)
            .withOpacity(.50);

    canvas.drawPath(
      path3,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

