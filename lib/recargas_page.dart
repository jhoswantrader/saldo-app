import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';




class Recarga {
  final String codigo;
  final String fecha;
  final String monto;
  final String moneda;
  final String estado;

  Recarga({
    required this.codigo,
    required this.fecha,
    required this.monto,
    required this.moneda,
    required this.estado,
  });
}




class RecargasPage extends StatefulWidget {
  final Future<List<Recarga>> Function() cargarRecargas;

  final Future<void> Function() volverAlDashboard;

  const RecargasPage({
    super.key,
    required this.cargarRecargas,
    required this.volverAlDashboard,
  });

  @override
  State<RecargasPage> createState() => _RecargasPageState();
}



class _RecargasPageState extends State<RecargasPage> {


  List<Recarga> recargas = [];
  bool cargandoRecargas = true;
  String? errorRecargas;
  // =========================
  // CONTROLADORES
  // =========================

  final TextEditingController referenciaController =
      TextEditingController();

  final TextEditingController montoController =
      TextEditingController();

  final TextEditingController observacionController =
      TextEditingController();

  // =========================
  // VALORES DEL FORMULARIO
  // =========================

  String? moneda;
  String? metodo;
  String? bancoOrigen;
  String? bancoDestino;

  File? comprobante;

  // =========================
  // COLORES
  // =========================

  static const Color negro = Color(0xFF080808);
  static const Color dorado = Color(0xFFD5B45A);
  static const Color fondo = Color(0xFFF7F7F5);


  @override
  void initState() {
    super.initState();
    _cargarListaRecargas();
  }

  Future<void> _cargarListaRecargas() async {
    if (mounted) {
      setState(() {
        cargandoRecargas = true;
        errorRecargas = null;
      });
    }

    try {
      final resultado = await widget.cargarRecargas();

      if (!mounted) return;

      setState(() {
        recargas = resultado;
        cargandoRecargas = false;
      });
    } catch (e) {
      debugPrint('RECARGAS: ERROR: $e');

      if (!mounted) return;

      setState(() {
        cargandoRecargas = false;
        errorRecargas = 'No se pudieron cargar las recargas.';
      });
    }
  }



  @override
  void dispose() {
    referenciaController.dispose();
    montoController.dispose();
    observacionController.dispose();
    super.dispose();
  }

  // =========================
  // SELECCIONAR COMPROBANTE
  // =========================

  Future<void> _seleccionarComprobante() async {
    final ImagePicker picker = ImagePicker();

    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (imagen == null) return;

    setState(() {
      comprobante = File(imagen.path);
    });
  }

  // =========================
  // GUARDAR
  // =========================

  void _guardarRecarga() {
    if (moneda == null ||
        metodo == null ||
        bancoOrigen == null ||
        bancoDestino == null ||
        referenciaController.text.trim().isEmpty ||
        montoController.text.trim().isEmpty) {
      _mostrarMensaje(
        'Completa todos los campos obligatorios.',
        esError: true,
      );
      return;
    }

    _mostrarMensaje(
      'El formulario está listo para conectarse con Super900.',
    );
  }

  // =========================
  // MENSAJE
  // =========================

  void _mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red.shade700 : negro,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

@override
Widget _buildListaRecargas() {
  // Mientras se cargan las recargas
  if (cargandoRecargas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: dorado,
        ),
      ),
    );
  }

  // Si ocurrió un error
  if (errorRecargas != null) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 38,
            color: Colors.red.shade400,
          ),

          const SizedBox(height: 10),

          Text(
            errorRecargas!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: _cargarListaRecargas,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // Si no hay recargas
  if (recargas.isEmpty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          Text(
            'Todavía no hay recargas para mostrar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar las recargas
  return Column(
    children: recargas.map((recarga) {
      return _buildRecarga(recarga);
    }).toList(),
  );
}

Widget _buildRecarga(Recarga recarga) {
  final bool activo =
      recarga.estado.toUpperCase() == 'ACTIVO';

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CÓDIGO Y ESTADO
        Row(
          children: [
            Expanded(
              child: Text(
                recarga.codigo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: activo
                    ? const Color(0xFFE9F5EC)
                    : const Color(0xFFF8EAEA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                recarga.estado,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: activo
                      ? const Color(0xFF2E8B57)
                      : const Color(0xFFC84B4B),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // FECHA
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Colors.grey.shade500,
            ),

            const SizedBox(width: 7),

            Text(
              recarga.fecha,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // MONTO
        Row(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 17,
              color: dorado,
            ),

            const SizedBox(width: 7),

            const Text(
              'Monto',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),

            const Spacer(),

            Text(
              '${recarga.monto} ${recarga.moneda.toUpperCase()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,

      appBar: AppBar(
        backgroundColor: negro,
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () async {
    await widget.volverAlDashboard();

    if (!mounted) return;

    Navigator.pop(context);
  },
),
        title: const Text(
          'Recargas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            18,
            20,
            18,
            35,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =========================
              // ENCABEZADO
              // =========================

              const Text(
                'Nueva recarga',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Registra un pago para agregar saldo a tu cuenta.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // FORMULARIO
              // =========================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // TITULO CARD
                    const Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: dorado,
                          size: 23,
                        ),

                        SizedBox(width: 10),

                        Text(
                          'Información de pago',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // =========================
                    // MONEDA
                    // =========================

                    _tituloCampo('Moneda'),

                    const SizedBox(height: 7),

                    _dropdown(
                      icon: Icons.payments_outlined,
                      hint: 'Seleccione',
                      value: moneda,
                      items: const [
                        DropdownMenuItem(
                          value: 'bs',
                          child: Text('Bolívar'),
                        ),
                        DropdownMenuItem(
                          value: 'usd',
                          child: Text('Dólar'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          moneda = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // METODO
                    // =========================

                    _tituloCampo('Método'),

                    const SizedBox(height: 7),

                    _dropdown(
                      icon: Icons.account_balance_wallet_outlined,
                      hint: 'Seleccione',
                      value: metodo,
                      items: const [
                        DropdownMenuItem(
                          value: 'efectivo',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'transferencia',
                          child: Text('Transferencia'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          metodo = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // BANCO ORIGEN
                    // =========================

                    _tituloCampo('Banco origen'),

                    const SizedBox(height: 7),

                    _dropdown(
                      icon: Icons.account_balance_outlined,
                      hint: 'Seleccione',
                      value: bancoOrigen,
                      items: const [
                        DropdownMenuItem(
                          value: '0156',
                          child: Text('100%BANCO'),
                        ),
                        DropdownMenuItem(
                          value: '0196',
                          child: Text('ABN AMRO BANK'),
                        ),
                        DropdownMenuItem(
                          value: '0172',
                          child: Text(
                            'BANCAMIGA BANCO MICROFINANCIERO',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0171',
                          child: Text(
                            'BANCO ACTIVO',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0102',
                          child: Text(
                            'BANCO DE VENEZUELA',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0114',
                          child: Text(
                            'BANCO DEL CARIBE',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0163',
                          child: Text(
                            'BANCO DEL TESORO',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0105',
                          child: Text(
                            'BANCO MERCANTIL',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0191',
                          child: Text(
                            'BANCO NACIONAL DE CREDITO',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0108',
                          child: Text(
                            'BANCO PROVINCIAL BBVA',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0134',
                          child: Text(
                            'BANESCO BANCO UNIVERSAL',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0177',
                          child: Text(
                            'BANFANB',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0146',
                          child: Text(
                            'BANGENTE',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0174',
                          child: Text(
                            'BANPLUS BANCO COMERCIAL',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '0137',
                          child: Text(
                            'SOFITASA',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          bancoOrigen = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // BANCO DESTINO
                    // =========================

                    _tituloCampo('Banco destino'),

                    const SizedBox(height: 7),

                    _dropdown(
                      icon: Icons.account_balance,
                      hint: 'Seleccione',
                      value: bancoDestino,
                      items: const [
                        DropdownMenuItem(
                          value: '0134',
                          child: Text(
                            'BANESCO BANCO UNIVERSAL',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          bancoDestino = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // REFERENCIA
                    // =========================

                    _tituloCampo('Referencia'),

                    const SizedBox(height: 7),

                    _textField(
                      controller: referenciaController,
                      hint: 'Agregar referencia',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // MONTO
                    // =========================

                    _tituloCampo('Monto'),

                    const SizedBox(height: 7),

                    _textField(
                      controller: montoController,
                      hint: '0.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // COMPROBANTE
                    // =========================

                    _tituloCampo('Comprobante'),

                    const SizedBox(height: 7),

                    GestureDetector(
                      onTap: _seleccionarComprobante,

                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: fondo,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),

                        child: Row(
                          children: [

                            const Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                comprobante == null
                                    ? 'Seleccionar imagen'
                                    : 'Comprobante seleccionado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: comprobante == null
                                      ? Colors.grey.shade600
                                      : Colors.black,
                                  fontWeight: comprobante == null
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.attach_file,
                              color: dorado,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // PREVISUALIZACION
                    if (comprobante != null) ...[
                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: Image.file(
                          comprobante!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // =========================
                    // OBSERVACION
                    // =========================

                    _tituloCampo('Observación'),

                    const SizedBox(height: 7),

                    _textField(
                      controller: observacionController,
                      hint: 'Opcional',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // AVISO
                    // =========================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E5),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: dorado.withOpacity(0.35),
                        ),
                      ),

                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Icon(
                            Icons.info_outline,
                            color: dorado,
                            size: 20,
                          ),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Verifica que los datos ingresados estén correctamente introducidos.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =========================
                    // BOTON
                    // =========================

                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton.icon(
                        onPressed: _guardarRecarga,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: negro,
                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),

                        icon: const Icon(
                          Icons.add,
                          color: dorado,
                        ),

                        label: const Text(
                          'AGREGAR RECARGA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // RECARGAS RECIENTES
              // =========================

            const Text(
  'Recargas recientes',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),
),

const SizedBox(height: 12),

_buildListaRecargas(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // TITULO CAMPO
  // =========================

  Widget _tituloCampo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // =========================
  // DROPDOWN
  // =========================

  Widget _dropdown({
    required IconData icon,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: DropdownButtonFormField<String>(
        initialValue: value,

        isExpanded: true,

        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
        ),

        hint: Text(
          hint,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),

        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey.shade600,
        ),

        items: items,

        onChanged: onChanged,
      ),
    );
  }

  // =========================
  // TEXT FIELD
  // =========================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: TextField(
        controller: controller,

        keyboardType: keyboardType,

        maxLines: maxLines,

        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(
              bottom: 0,
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey.shade700,
            ),
          ),

          hintText: hint,

          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}