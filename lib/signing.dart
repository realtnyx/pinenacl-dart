library pinenacl.api.signatures;

import "dart:core";
import 'dart:typed_data';

import 'package:convert/convert.dart';

import 'package:pinenacl/api.dart';

class VerifyKey extends ByteList implements AsymmetricKey {
  VerifyKey([List<int> list]) : super.fromList(list);
  VerifyKey.fromList(List<int> list) : super.fromList(list);
  VerifyKey.fromHexString(String hexaString) : super.fromHexString(hexaString);

  bool verify(List<int> message, [List<int> signature]) {
    if (signature != null) {
      if (signature.length != TweetNaCl.signatureLength) {
        throw Exception(
            'Signature length (${signature.length}) is invalid, expected "${TweetNaCl.signatureLength}"');
      }
      message = signature + message;
    }
    if (message == null || message.length < TweetNaCl.signatureLength) {
      throw Exception(
          'Signature length (${message.length}) is invalid, expected "${TweetNaCl.signatureLength}"');
    }

    Uint8List m = Uint8List(message.length);

    final result = TweetNaCl.crypto_sign_open(
        m, -1, Uint8List.fromList(message), 0, message.length, this);
    if (result != 0) {
      throw Exception(
          'The message is forged or malformed or the signature is invalid');
    }
    return true;
  }
}

class SigningKey extends ByteList implements AsymmetricKey {
  SigningKey._fromValidBytes(List<int> secret, List<int> public)
      : this.verifyKey = VerifyKey.fromList(public),
        super.fromList(secret, secret.length, secret.length);

  factory SigningKey({List<int> seed}) {
    if (seed is AsymmetricKey) {
      throw Exception('Seed cannot be any type of AsymmetricKey');
    }
    return SigningKey.fromList(seed);
  }

  factory SigningKey.fromHexString(String hexaString) {
    return SigningKey.fromSeed(Uint8List.fromList(hex.decode(hexaString)));
  }

  factory SigningKey.fromList(List<int> rawKey) {
    return SigningKey.fromSeed(rawKey);
  }

  factory SigningKey.fromSeed(List<int> seed) {
    if (seed == null || seed?.length != seedSize) {
      throw Exception('SigningKey must be created from a $seedSize byte seed');
    }

    final priv = Uint8List.fromList(seed + Uint8List(32));
    final pub = Uint8List(TweetNaCl.publicKeyLength);
    TweetNaCl.crypto_sign_keypair(pub, priv, Uint8List.fromList(seed));

    return SigningKey._fromValidBytes(priv, pub);
  }

  factory SigningKey.generate() {
    final secret = TweetNaCl.randombytes(keyLength);
    return SigningKey.fromSeed(secret);
  }

  static const keyLength = TweetNaCl.secretKeyLength;
  static const seedSize = TweetNaCl.seedSize;
  final VerifyKey verifyKey;

  SignedMessage sign(List<int> message) {
    // signed message
    Uint8List sm = Uint8List(message.length + TweetNaCl.signatureLength);
    final result = TweetNaCl.crypto_sign(
        sm, -1, Uint8List.fromList(message), 0, message.length, this);
    if (result != 0) {
      throw Exception('Signing the massage is failed');
    }

    return SignedMessage.fromList(signedMessage: sm);
  }
}
