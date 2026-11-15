import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> puedeAutenticar() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      print('LOCAL_AUTH: ERROR SOPORTE = $e');
      return false;
    }
  }

  Future<bool> autenticar() async {
    try {
      print('LOCAL_AUTH: LLAMANDO authenticate()...');

      final resultado = await _auth.authenticate(
        localizedReason:
            'Confirma tu identidad para entrar a saldo_app',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      print(
        'LOCAL_AUTH: RESULTADO AUTH = $resultado',
      );

      return resultado;
    } catch (e, stack) {
      print('LOCAL_AUTH: ERROR AUTH = $e');
      print('LOCAL_AUTH: STACK = $stack');
      return false;
    }
  }
}