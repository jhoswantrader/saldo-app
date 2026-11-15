import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _entidadKey = 'super900_entidad';
  static const String _codigoKey = 'super900_codigo';
  static const String _claveKey = 'super900_clave';
  static const String _configuradoKey = 'super900_configurado';

  Future<void> guardarCredenciales({
    required String entidad,
    required String codigo,
    required String clave,
  }) async {
    await _storage.write(
      key: _entidadKey,
      value: entidad,
    );

    await _storage.write(
      key: _codigoKey,
      value: codigo,
    );

    await _storage.write(
      key: _claveKey,
      value: clave,
    );

    await _storage.write(
      key: _configuradoKey,
      value: 'true',
    );
  }

  Future<Map<String, String>?> obtenerCredenciales() async {
    final configurado =
        await _storage.read(key: _configuradoKey);

    if (configurado != 'true') {
      return null;
    }

    final entidad =
        await _storage.read(key: _entidadKey);

    final codigo =
        await _storage.read(key: _codigoKey);

    final clave =
        await _storage.read(key: _claveKey);

    if (entidad == null ||
        codigo == null ||
        clave == null ||
        entidad.isEmpty ||
        codigo.isEmpty ||
        clave.isEmpty) {
      return null;
    }

    return {
      'entidad': entidad,
      'codigo': codigo,
      'clave': clave,
    };
  }

  Future<bool> tieneCredenciales() async {
    final configurado =
        await _storage.read(key: _configuradoKey);

    return configurado == 'true';
  }

  Future<void> eliminarCredenciales() async {
    await _storage.delete(key: _entidadKey);
    await _storage.delete(key: _codigoKey);
    await _storage.delete(key: _claveKey);
    await _storage.delete(key: _configuradoKey);
  }
}