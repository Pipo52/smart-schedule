import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM helper for secrets that leave the device.
///
/// The wrapping key is derived from the signed-in uid plus an app pepper.
/// That keeps the Gemini key out of Firestore in plaintext (console dumps,
/// logs, backups). It is not a server-held secret: anyone with this app
/// binary and access to that user's Firestore can still decrypt.
class SecretCrypto {
  SecretCrypto._();
  static final SecretCrypto instance = SecretCrypto._();

  static const _info = 'smart-schedule.gemini.v1';
  static const _pepper = 'wQ8nV5rL0pYc2sHd9tKb6xUe1aMj4gFi';

  final AesGcm _aes = AesGcm.with256bits();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  Future<SecretKey> _keyForUid(String uid) {
    return _hkdf.deriveKey(
      secretKey: SecretKey(utf8.encode(_pepper)),
      nonce: utf8.encode(uid),
      info: utf8.encode(_info),
    );
  }

  Future<String> encrypt(String uid, String plaintext) async {
    final secretKey = await _keyForUid(uid);
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    return [
      'v1',
      base64Url.encode(nonce),
      base64Url.encode(box.cipherText),
      base64Url.encode(box.mac.bytes),
    ].join('.');
  }

  Future<String?> decrypt(String uid, String blob) async {
    final parts = blob.split('.');
    if (parts.length != 4 || parts[0] != 'v1') return null;
    try {
      final secretKey = await _keyForUid(uid);
      final clear = await _aes.decrypt(
        SecretBox(
          base64Url.decode(parts[2]),
          nonce: base64Url.decode(parts[1]),
          mac: Mac(base64Url.decode(parts[3])),
        ),
        secretKey: secretKey,
      );
      return utf8.decode(clear);
    } catch (_) {
      return null;
    }
  }
}
