library pinenacl.api.crypto.tweetnacl;

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'hmac_sha512.dart';
import 'poly1305.dart';

part 'tweetnacl_ext.dart';
// ignore_for_file: constant_identifier_names

class TweetNaCl {
  static const int keyLength = 32;

  static const int macBytes = 16;

  // Constants
  static const int seedSize = 32;

  // Length of public key in bytes.
  static const int publicKeyLength = 32;
  // Default length of the secret key in bytes.
  static const int secretKeyLength = 32;
  // Length of precomputed shared key in bytes.
  static const int sharedKeyLength = 32;
  // Length of nonce in bytes.
  static const int nonceLength = 24;
  // zero bytes in case box
  static const int zerobytesLength = 32;
  // zero bytes in case open box
  static const int boxzerobytesLength = 16;
  // Length of overhead added to box compared to original message.
  static const int overheadLength = 16;

  // Signature length
  static const int signatureLength = 64;

  static const _0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  static const _9 = [
    9, 0, 0, 0, 0, 0, 0, 0, // 0-7
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
  ];

  static const _gf0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; //16
  static const _gf1 = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; //16

  static const _121665 = [
    0xDB41,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0
  ]; //16

  static const _D = [
    0x78a3, 0x1359, 0x4dca, 0x75eb, // 0-3
    0xd8ab, 0x4141, 0x0a4d, 0x0070,
    0xe898, 0x7779, 0x4079, 0x8cc7,
    0xfe73, 0x2b6f, 0x6cee, 0x5203
  ];

  static const _D2 = [
    0xf159, 0x26b2, 0x9b94, 0xebd6, // 0-3
    0xb156, 0x8283, 0x149a, 0x00e0,
    0xd130, 0xeef3, 0x80f2, 0x198e,
    0xfce7, 0x56df, 0xd9dc, 0x2406
  ];

  static const _X = [
    0xd51a, 0x8f25, 0x2d60, 0xc956, // 0-3
    0xa7b2, 0x9525, 0xc760, 0x692c,
    0xdc5c, 0xfdd6, 0xe231, 0xc0a4,
    0x53fe, 0xcd6e, 0x36d3, 0x2169
  ];

  static const _Y = [
    0x6658, 0x6666, 0x6666, 0x6666, // 0-3
    0x6666, 0x6666, 0x6666, 0x6666,
    0x6666, 0x6666, 0x6666, 0x6666,
    0x6666, 0x6666, 0x6666, 0x6666
  ];

  static const _I = [
    0xa0b0, 0x4a0e, 0x1b27, 0xc4ee, // 0-3
    0xe478, 0xad2f, 0x1806, 0x2f43,
    0xd7a7, 0x3dfb, 0x0099, 0x2b4d,
    0xdf0b, 0x4fc1, 0x2480, 0x2b83
  ];

  static void _ts64(Uint8List x, final int xoff, int u) {
    ///int i;
    ///for (i = 7;i >= 0;--i) { x[i+xoff] = (byte)(u&0xff); u >>= 8; }

    x[7 + xoff] = (u & 0xff).toInt();
    u = u >> 8;
    x[6 + xoff] = (u & 0xff).toInt();
    u = u >> 8;
    x[5 + xoff] = (u & 0xff).toInt();
    u = u >> 8;
    x[4 + xoff] = (u & 0xff).toInt();
    u = u >> 8;
    x[3 + xoff] = (u & 0xff).toInt();
    u = u >> 8;
    x[2 + xoff] = (u & 0xff).toInt();
    u = u >> 8;
    x[1 + xoff] = (u & 0xff).toInt();
    u = u >> 8;
    x[0 + xoff] = (u & 0xff).toInt();

    ///u >>= 8;
  }

  static int _vn(
      Uint8List x, final int xoff, Uint8List y, final int yoff, int n) {
    int i, d = 0;
    for (i = 0; i < n; i++) {
      d |= (x[i + xoff] ^ y[i + yoff]) & 0xff;
    }
    return (1 & ((d - 1) >> 8)) - 1;
  }

  static int _crypto_verify_16(
      Uint8List x, final int xoff, Uint8List y, final int yoff) {
    return _vn(x, xoff, y, yoff, 16);
  }

  static int crypto_verify_16(Uint8List x, Uint8List y) {
    return _crypto_verify_16(x, 0, y, 0);
  }

  static int _crypto_verify_32(
      Uint8List x, final int xoff, Uint8List y, final int yoff) {
    return _vn(x, xoff, y, yoff, 32);
  }

  static int crypto_verify_32(Uint8List x, Uint8List y) {
    return _crypto_verify_32(x, 0, y, 0);
  }

  static void _core_salsa20(
      Uint8List o, List<int> p, Uint8List k, List<int> c) {
    var j0 = c[0] & 0xff |
            (c[1] & 0xff) << 8 |
            (c[2] & 0xff) << 16 |
            (c[3] & 0xff) << 24,
        j1 = k[0] & 0xff |
            (k[1] & 0xff) << 8 |
            (k[2] & 0xff) << 16 |
            (k[3] & 0xff) << 24,
        j2 = k[4] & 0xff |
            (k[5] & 0xff) << 8 |
            (k[6] & 0xff) << 16 |
            (k[7] & 0xff) << 24,
        j3 = k[8] & 0xff |
            (k[9] & 0xff) << 8 |
            (k[10] & 0xff) << 16 |
            (k[11] & 0xff) << 24,
        j4 = k[12] & 0xff |
            (k[13] & 0xff) << 8 |
            (k[14] & 0xff) << 16 |
            (k[15] & 0xff) << 24,
        j5 = c[4] & 0xff |
            (c[5] & 0xff) << 8 |
            (c[6] & 0xff) << 16 |
            (c[7] & 0xff) << 24,
        j6 = p[0] & 0xff |
            (p[1] & 0xff) << 8 |
            (p[2] & 0xff) << 16 |
            (p[3] & 0xff) << 24,
        j7 = p[4] & 0xff |
            (p[5] & 0xff) << 8 |
            (p[6] & 0xff) << 16 |
            (p[7] & 0xff) << 24,
        j8 = p[8] & 0xff |
            (p[9] & 0xff) << 8 |
            (p[10] & 0xff) << 16 |
            (p[11] & 0xff) << 24,
        j9 = p[12] & 0xff |
            (p[13] & 0xff) << 8 |
            (p[14] & 0xff) << 16 |
            (p[15] & 0xff) << 24,
        j10 = c[8] & 0xff |
            (c[9] & 0xff) << 8 |
            (c[10] & 0xff) << 16 |
            (c[11] & 0xff) << 24,
        j11 = k[16] & 0xff |
            (k[17] & 0xff) << 8 |
            (k[18] & 0xff) << 16 |
            (k[19] & 0xff) << 24,
        j12 = k[20] & 0xff |
            (k[21] & 0xff) << 8 |
            (k[22] & 0xff) << 16 |
            (k[23] & 0xff) << 24,
        j13 = k[24] & 0xff |
            (k[25] & 0xff) << 8 |
            (k[26] & 0xff) << 16 |
            (k[27] & 0xff) << 24,
        j14 = k[28] & 0xff |
            (k[29] & 0xff) << 8 |
            (k[30] & 0xff) << 16 |
            (k[31] & 0xff) << 24,
        j15 = c[12] & 0xff |
            (c[13] & 0xff) << 8 |
            (c[14] & 0xff) << 16 |
            (c[15] & 0xff) << 24;

    Int32 x0 = Int32(j0),
        x1 = Int32(j1),
        x2 = Int32(j2),
        x3 = Int32(j3),
        x4 = Int32(j4),
        x5 = Int32(j5),
        x6 = Int32(j6),
        x7 = Int32(j7),
        x8 = Int32(j8),
        x9 = Int32(j9),
        x10 = Int32(j10),
        x11 = Int32(j11),
        x12 = Int32(j12),
        x13 = Int32(j13),
        x14 = Int32(j14),
        x15 = Int32(j15),
        u;

    for (var i = 0; i < 20; i += 2) {
      u = x0 + x12 | 0 as Int32;
      x4 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x4 + x0 | 0 as Int32;
      x8 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x8 + x4 | 0 as Int32;
      x12 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x12 + x8 | 0 as Int32;
      x0 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x5 + x1 | 0 as Int32;
      x9 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x9 + x5 | 0 as Int32;
      x13 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x13 + x9 | 0 as Int32;
      x1 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x1 + x13 | 0 as Int32;
      x5 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x10 + x6 | 0 as Int32;
      x14 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x14 + x10 | 0 as Int32;
      x2 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x2 + x14 | 0 as Int32;
      x6 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x6 + x2 | 0 as Int32;
      x10 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x15 + x11 | 0 as Int32;
      x3 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x3 + x15 | 0 as Int32;
      x7 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x7 + x3 | 0 as Int32;
      x11 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x11 + x7 | 0 as Int32;
      x15 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x0 + x3 | 0 as Int32;
      x1 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x1 + x0 | 0 as Int32;
      x2 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x2 + x1 | 0 as Int32;
      x3 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x3 + x2 | 0 as Int32;
      x0 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x5 + x4 | 0 as Int32;
      x6 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x6 + x5 | 0 as Int32;
      x7 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x7 + x6 | 0 as Int32;
      x4 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x4 + x7 | 0 as Int32;
      x5 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x10 + x9 | 0 as Int32;
      x11 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x11 + x10 | 0 as Int32;
      x8 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x8 + x11 | 0 as Int32;
      x9 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x9 + x8 | 0 as Int32;
      x10 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x15 + x14 | 0 as Int32;
      x12 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x12 + x15 | 0 as Int32;
      x13 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x13 + x12 | 0 as Int32;
      x14 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x14 + x13 | 0 as Int32;
      x15 ^= u << 18 | u.shiftRightUnsigned(32 - 18);
    }
    x0 = x0 + j0 | 0 as Int32;
    x1 = x1 + j1 | 0 as Int32;
    x2 = x2 + j2 | 0 as Int32;
    x3 = x3 + j3 | 0 as Int32;
    x4 = x4 + j4 | 0 as Int32;
    x5 = x5 + j5 | 0 as Int32;
    x6 = x6 + j6 | 0 as Int32;
    x7 = x7 + j7 | 0 as Int32;
    x8 = x8 + j8 | 0 as Int32;
    x9 = x9 + j9 | 0 as Int32;
    x10 = x10 + j10 | 0 as Int32;
    x11 = x11 + j11 | 0 as Int32;
    x12 = x12 + j12 | 0 as Int32;
    x13 = x13 + j13 | 0 as Int32;
    x14 = x14 + j14 | 0 as Int32;
    x15 = x15 + j15 | 0 as Int32;

    o[0] = (x0.shiftRightUnsigned(0) & 0xff).toInt();
    o[1] = (x0.shiftRightUnsigned(8) & 0xff).toInt();
    o[2] = (x0.shiftRightUnsigned(16) & 0xff).toInt();
    o[3] = (x0.shiftRightUnsigned(24) & 0xff).toInt();

    o[4] = (x1.shiftRightUnsigned(0) & 0xff).toInt();
    o[5] = (x1.shiftRightUnsigned(8) & 0xff).toInt();
    o[6] = (x1.shiftRightUnsigned(16) & 0xff).toInt();
    o[7] = (x1.shiftRightUnsigned(24) & 0xff).toInt();

    o[8] = (x2.shiftRightUnsigned(0) & 0xff).toInt();
    o[9] = (x2.shiftRightUnsigned(8) & 0xff).toInt();
    o[10] = (x2.shiftRightUnsigned(16) & 0xff).toInt();
    o[11] = (x2.shiftRightUnsigned(24) & 0xff).toInt();

    o[12] = (x3.shiftRightUnsigned(0) & 0xff).toInt();
    o[13] = (x3.shiftRightUnsigned(8) & 0xff).toInt();
    o[14] = (x3.shiftRightUnsigned(16) & 0xff).toInt();
    o[15] = (x3.shiftRightUnsigned(24) & 0xff).toInt();

    o[16] = (x4.shiftRightUnsigned(0) & 0xff).toInt();
    o[17] = (x4.shiftRightUnsigned(8) & 0xff).toInt();
    o[18] = (x4.shiftRightUnsigned(16) & 0xff).toInt();
    o[19] = (x4.shiftRightUnsigned(24) & 0xff).toInt();

    o[20] = (x5.shiftRightUnsigned(0) & 0xff).toInt();
    o[21] = (x5.shiftRightUnsigned(8) & 0xff).toInt();
    o[22] = (x5.shiftRightUnsigned(16) & 0xff).toInt();
    o[23] = (x5.shiftRightUnsigned(24) & 0xff).toInt();

    o[24] = (x6.shiftRightUnsigned(0) & 0xff).toInt();
    o[25] = (x6.shiftRightUnsigned(8) & 0xff).toInt();
    o[26] = (x6.shiftRightUnsigned(16) & 0xff).toInt();
    o[27] = (x6.shiftRightUnsigned(24) & 0xff).toInt();

    o[28] = (x7.shiftRightUnsigned(0) & 0xff).toInt();
    o[29] = (x7.shiftRightUnsigned(8) & 0xff).toInt();
    o[30] = (x7.shiftRightUnsigned(16) & 0xff).toInt();
    o[31] = (x7.shiftRightUnsigned(24) & 0xff).toInt();

    o[32] = (x8.shiftRightUnsigned(0) & 0xff).toInt();
    o[33] = (x8.shiftRightUnsigned(8) & 0xff).toInt();
    o[34] = (x8.shiftRightUnsigned(16) & 0xff).toInt();
    o[35] = (x8.shiftRightUnsigned(24) & 0xff).toInt();

    o[36] = (x9.shiftRightUnsigned(0) & 0xff).toInt();
    o[37] = (x9.shiftRightUnsigned(8) & 0xff).toInt();
    o[38] = (x9.shiftRightUnsigned(16) & 0xff).toInt();
    o[39] = (x9.shiftRightUnsigned(24) & 0xff).toInt();

    o[40] = (x10.shiftRightUnsigned(0) & 0xff).toInt();
    o[41] = (x10.shiftRightUnsigned(8) & 0xff).toInt();
    o[42] = (x10.shiftRightUnsigned(16) & 0xff).toInt();
    o[43] = (x10.shiftRightUnsigned(24) & 0xff).toInt();

    o[44] = (x11.shiftRightUnsigned(0) & 0xff).toInt();
    o[45] = (x11.shiftRightUnsigned(8) & 0xff).toInt();
    o[46] = (x11.shiftRightUnsigned(16) & 0xff).toInt();
    o[47] = (x11.shiftRightUnsigned(24) & 0xff).toInt();

    o[48] = (x12.shiftRightUnsigned(0) & 0xff).toInt();
    o[49] = (x12.shiftRightUnsigned(8) & 0xff).toInt();
    o[50] = (x12.shiftRightUnsigned(16) & 0xff).toInt();
    o[51] = (x12.shiftRightUnsigned(24) & 0xff).toInt();

    o[52] = (x13.shiftRightUnsigned(0) & 0xff).toInt();
    o[53] = (x13.shiftRightUnsigned(8) & 0xff).toInt();
    o[54] = (x13.shiftRightUnsigned(16) & 0xff).toInt();
    o[55] = (x13.shiftRightUnsigned(24) & 0xff).toInt();

    o[56] = (x14.shiftRightUnsigned(0) & 0xff).toInt();
    o[57] = (x14.shiftRightUnsigned(8) & 0xff).toInt();
    o[58] = (x14.shiftRightUnsigned(16) & 0xff).toInt();
    o[59] = (x14.shiftRightUnsigned(24) & 0xff).toInt();

    o[60] = (x15.shiftRightUnsigned(0) & 0xff).toInt();
    o[61] = (x15.shiftRightUnsigned(8) & 0xff).toInt();
    o[62] = (x15.shiftRightUnsigned(16) & 0xff).toInt();
    o[63] = (x15.shiftRightUnsigned(24) & 0xff).toInt();
  }

  static void _core_hsalsa20(
      Uint8List o, List<int> p, Uint8List k, List<int> c) {
    c = _sigma;

    var j0 = c[0] & 0xff |
            (c[1] & 0xff) << 8 |
            (c[2] & 0xff) << 16 |
            (c[3] & 0xff) << 24,
        j1 = k[0] & 0xff |
            (k[1] & 0xff) << 8 |
            (k[2] & 0xff) << 16 |
            (k[3] & 0xff) << 24,
        j2 = k[4] & 0xff |
            (k[5] & 0xff) << 8 |
            (k[6] & 0xff) << 16 |
            (k[7] & 0xff) << 24,
        j3 = k[8] & 0xff |
            (k[9] & 0xff) << 8 |
            (k[10] & 0xff) << 16 |
            (k[11] & 0xff) << 24,
        j4 = k[12] & 0xff |
            (k[13] & 0xff) << 8 |
            (k[14] & 0xff) << 16 |
            (k[15] & 0xff) << 24,
        j5 = c[4] & 0xff |
            (c[5] & 0xff) << 8 |
            (c[6] & 0xff) << 16 |
            (c[7] & 0xff) << 24,
        j6 = p[0] & 0xff |
            (p[1] & 0xff) << 8 |
            (p[2] & 0xff) << 16 |
            (p[3] & 0xff) << 24,
        j7 = p[4] & 0xff |
            (p[5] & 0xff) << 8 |
            (p[6] & 0xff) << 16 |
            (p[7] & 0xff) << 24,
        j8 = p[8] & 0xff |
            (p[9] & 0xff) << 8 |
            (p[10] & 0xff) << 16 |
            (p[11] & 0xff) << 24,
        j9 = p[12] & 0xff |
            (p[13] & 0xff) << 8 |
            (p[14] & 0xff) << 16 |
            (p[15] & 0xff) << 24,
        j10 = c[8] & 0xff |
            (c[9] & 0xff) << 8 |
            (c[10] & 0xff) << 16 |
            (c[11] & 0xff) << 24,
        j11 = k[16] & 0xff |
            (k[17] & 0xff) << 8 |
            (k[18] & 0xff) << 16 |
            (k[19] & 0xff) << 24,
        j12 = k[20] & 0xff |
            (k[21] & 0xff) << 8 |
            (k[22] & 0xff) << 16 |
            (k[23] & 0xff) << 24,
        j13 = k[24] & 0xff |
            (k[25] & 0xff) << 8 |
            (k[26] & 0xff) << 16 |
            (k[27] & 0xff) << 24,
        j14 = k[28] & 0xff |
            (k[29] & 0xff) << 8 |
            (k[30] & 0xff) << 16 |
            (k[31] & 0xff) << 24,
        j15 = c[12] & 0xff |
            (c[13] & 0xff) << 8 |
            (c[14] & 0xff) << 16 |
            (c[15] & 0xff) << 24;

    Int32 x0 = Int32(j0),
        x1 = Int32(j1),
        x2 = Int32(j2),
        x3 = Int32(j3),
        x4 = Int32(j4),
        x5 = Int32(j5),
        x6 = Int32(j6),
        x7 = Int32(j7),
        x8 = Int32(j8),
        x9 = Int32(j9),
        x10 = Int32(j10),
        x11 = Int32(j11),
        x12 = Int32(j12),
        x13 = Int32(j13),
        x14 = Int32(j14),
        x15 = Int32(j15),
        u;

    for (var i = 0; i < 20; i += 2) {
      u = x0 + x12 | 0 as Int32;
      x4 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x4 + x0 | 0 as Int32;
      x8 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x8 + x4 | 0 as Int32;
      x12 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x12 + x8 | 0 as Int32;
      x0 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x5 + x1 | 0 as Int32;
      x9 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x9 + x5 | 0 as Int32;
      x13 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x13 + x9 | 0 as Int32;
      x1 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x1 + x13 | 0 as Int32;
      x5 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x10 + x6 | 0 as Int32;
      x14 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x14 + x10 | 0 as Int32;
      x2 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x2 + x14 | 0 as Int32;
      x6 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x6 + x2 | 0 as Int32;
      x10 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x15 + x11 | 0 as Int32;
      x3 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x3 + x15 | 0 as Int32;
      x7 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x7 + x3 | 0 as Int32;
      x11 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x11 + x7 | 0 as Int32;
      x15 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x0 + x3 | 0 as Int32;
      x1 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x1 + x0 | 0 as Int32;
      x2 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x2 + x1 | 0 as Int32;
      x3 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x3 + x2 | 0 as Int32;
      x0 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x5 + x4 | 0 as Int32;
      x6 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x6 + x5 | 0 as Int32;
      x7 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x7 + x6 | 0 as Int32;
      x4 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x4 + x7 | 0 as Int32;
      x5 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x10 + x9 | 0 as Int32;
      x11 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x11 + x10 | 0 as Int32;
      x8 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x8 + x11 | 0 as Int32;
      x9 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x9 + x8 | 0 as Int32;
      x10 ^= u << 18 | u.shiftRightUnsigned(32 - 18);

      u = x15 + x14 | 0 as Int32;
      x12 ^= u << 7 | u.shiftRightUnsigned(32 - 7);
      u = x12 + x15 | 0 as Int32;
      x13 ^= u << 9 | u.shiftRightUnsigned(32 - 9);
      u = x13 + x12 | 0 as Int32;
      x14 ^= u << 13 | u.shiftRightUnsigned(32 - 13);
      u = x14 + x13 | 0 as Int32;
      x15 ^= u << 18 | u.shiftRightUnsigned(32 - 18);
    }

    o[0] = (x0.shiftRightUnsigned(0) & 0xff).toInt();
    o[1] = (x0.shiftRightUnsigned(8) & 0xff).toInt();
    o[2] = (x0.shiftRightUnsigned(16) & 0xff).toInt();
    o[3] = (x0.shiftRightUnsigned(24) & 0xff).toInt();

    o[4] = (x5.shiftRightUnsigned(0) & 0xff).toInt();
    o[5] = (x5.shiftRightUnsigned(8) & 0xff).toInt();
    o[6] = (x5.shiftRightUnsigned(16) & 0xff).toInt();
    o[7] = (x5.shiftRightUnsigned(24) & 0xff).toInt();

    o[8] = (x10.shiftRightUnsigned(0) & 0xff).toInt();
    o[9] = (x10.shiftRightUnsigned(8) & 0xff).toInt();
    o[10] = (x10.shiftRightUnsigned(16) & 0xff).toInt();
    o[11] = (x10.shiftRightUnsigned(24) & 0xff).toInt();

    o[12] = (x15.shiftRightUnsigned(0) & 0xff).toInt();
    o[13] = (x15.shiftRightUnsigned(8) & 0xff).toInt();
    o[14] = (x15.shiftRightUnsigned(16) & 0xff).toInt();
    o[15] = (x15.shiftRightUnsigned(24) & 0xff).toInt();

    o[16] = (x6.shiftRightUnsigned(0) & 0xff).toInt();
    o[17] = (x6.shiftRightUnsigned(8) & 0xff).toInt();
    o[18] = (x6.shiftRightUnsigned(16) & 0xff).toInt();
    o[19] = (x6.shiftRightUnsigned(24) & 0xff).toInt();

    o[20] = (x7.shiftRightUnsigned(0) & 0xff).toInt();
    o[21] = (x7.shiftRightUnsigned(8) & 0xff).toInt();
    o[22] = (x7.shiftRightUnsigned(16) & 0xff).toInt();
    o[23] = (x7.shiftRightUnsigned(24) & 0xff).toInt();

    o[24] = (x8.shiftRightUnsigned(0) & 0xff).toInt();
    o[25] = (x8.shiftRightUnsigned(8) & 0xff).toInt();
    o[26] = (x8.shiftRightUnsigned(16) & 0xff).toInt();
    o[27] = (x8.shiftRightUnsigned(24) & 0xff).toInt();

    o[28] = (x9.shiftRightUnsigned(0) & 0xff).toInt();
    o[29] = (x9.shiftRightUnsigned(8) & 0xff).toInt();
    o[30] = (x9.shiftRightUnsigned(16) & 0xff).toInt();
    o[31] = (x9.shiftRightUnsigned(24) & 0xff).toInt();
  }

  static int crypto_core_salsa20(
      Uint8List out, List<int> input, Uint8List k, List<int> c) {
    ///core(out,in,k,c,0);
    _core_salsa20(out, input, k, c);
    return 0;
  }

  static Uint8List crypto_core_hsalsa20(
      Uint8List out, List<int> input, Uint8List k, List<int> c) {
    ///core(out,in,k,c,1);
    _core_hsalsa20(out, input, k, c);
    return out;
  }

// "expand 32-byte k"
  static const _sigma = [
    101, 120, 112, 97, //0-7
    110, 100, 32, 51,
    50, 45, 98, 121,
    116, 101, 32, 107
  ];

  static int crypto_stream_salsa20_xor(Uint8List c, int cpos, Uint8List m,
      int mpos, int b, Uint8List n, Uint8List k,
      [int ic = 0]) {
    var z = Uint8List(16), x = Uint8List(64);
    int i;
    Int32 u;
    for (i = 0; i < 16; i++) {
      z[i] = 0;
    }
    ;
    for (i = 0; i < 8; i++) {
      z[i] = n[i];
    }
    ;
    for (i = 8; i < 16; i++) {
      z[i] = (ic & 0xff);
      ic >>= 8;
    }

    while (b >= 64) {
      crypto_core_salsa20(x, z, k, _sigma);
      for (i = 0; i < 64; i++) {
        c[cpos + i] = ((m[mpos + i] ^ x[i]) & 0xff).toInt();
      }
      u = Int32(1);
      for (i = 8; i < 16; i++) {
        u = u + (z[i] & 0xff) | 0 as Int32;
        z[i] = (u & 0xff).toInt();
        u = u.shiftRightUnsigned(8);
      }
      b -= 64;
      cpos += 64;
      mpos += 64;
    }
    if (b > 0) {
      crypto_core_salsa20(x, z, k, _sigma);
      for (i = 0; i < b; i++) {
        c[cpos + i] = ((m[mpos + i] ^ x[i]) & 0xff).toInt();
      }
    }

    return 0;
  }

  static int crypto_stream_salsa20(
      Uint8List c, int cpos, int b, Uint8List n, Uint8List k) {
    var z = Uint8List(16), x = Uint8List(64);
    int i;
    Int32 u;
    for (i = 0; i < 16; i++) {
      z[i] = 0;
    }
    for (i = 0; i < 8; i++) {
      z[i] = n[i];
    }
    while (b >= 64) {
      crypto_core_salsa20(x, z, k, _sigma);
      for (i = 0; i < 64; i++) {
        c[cpos + i] = x[i];
      }
      u = Int32(1);
      for (i = 8; i < 16; i++) {
        u = u + (z[i] & 0xff) | 0 as Int32;
        z[i] = (u & 0xff).toInt();
        u = u.shiftRightUnsigned(8);
      }
      b -= 64;
      cpos += 64;
    }
    if (b > 0) {
      crypto_core_salsa20(x, z, k, _sigma);
      for (i = 0; i < b; i++) {
        c[cpos + i] = x[i];
      }
    }

    return 0;
  }

  static int crypto_stream(
      Uint8List c, int cpos, int d, Uint8List n, Uint8List k) {
    var s = Uint8List(32);
    crypto_core_hsalsa20(s, n, k, _sigma);
    var sn = Uint8List(8);
    for (var i = 0; i < 8; i++) {
      sn[i] = n[i + 16];
    }
    return crypto_stream_salsa20(c, cpos, d, sn, s);
  }

  static int crypto_stream_xor(Uint8List c, int cpos, Uint8List m, int mpos,
      int d, Uint8List n, Uint8List k) {
    var s = Uint8List(32);

    crypto_core_hsalsa20(s, n, k, _sigma);
    var sn = Uint8List(8);
    for (var i = 0; i < 8; i++) {
      sn[i] = n[i + 16];
    }
    return crypto_stream_salsa20_xor(c, cpos, m, mpos, d, sn, s);
  }

  static int _crypto_onetimeauth(Uint8List out, final int outpos, Uint8List m,
      final int mpos, int n, Uint8List k) {
    final s = Poly1305(k);
    s.update(m, mpos, n);
    s.finish(out, outpos);
    return 0;
  }

  static int crypto_onetimeauth(
      Uint8List out, Uint8List m, int n, Uint8List k) {
    return _crypto_onetimeauth(out, 0, m, 0, n, k);
  }

  static int _crypto_onetimeauth_verify(Uint8List h, final int hoff,
      Uint8List m, final int moff, int /*long*/ n, Uint8List k) {
    final x = Uint8List(16);
    _crypto_onetimeauth(x, 0, m, moff, n, k);
    return _crypto_verify_16(h, hoff, x, 0);
  }

  static int _crypto_onetimeauth_verify_len(
      Uint8List h, Uint8List m, int n, Uint8List k) {
    return _crypto_onetimeauth_verify(h, 0, m, 0, n, k);
  }

  static int crypto_onetimeauth_verify(Uint8List h, Uint8List m, Uint8List k) {
    return _crypto_onetimeauth_verify_len(h, m, m.length, k);
  }

  static Uint8List crypto_secretbox(
      Uint8List c, Uint8List m, int d, Uint8List n, Uint8List k) {
    if (d < 32) {
      throw 'SecretBox is invalid';
    }
    ;

    crypto_stream_xor(c, 0, m, 0, d, n, k);
    _crypto_onetimeauth(c, 16, c, 32, d - 32, c);

    // FIXME: Check in tweetnacl where these 16 bytes disappear?
    //for (i = 0; i < 16; i++) c[i] = 0;
    return c.sublist(16);
  }

  static Uint8List crypto_secretbox_open(
      Uint8List m, Uint8List c, int d, Uint8List n, Uint8List k) {
    final x = Uint8List(32);
    if (d < 32) {
      throw 'The message is forged or malformed or the shared secret is invalid';
      // return -1;
    }

    crypto_stream(x, 0, 32, n, k);
    // NOTE: the hash offset is zero instead of 16
    if (_crypto_onetimeauth_verify(c, 16, c, 32, d - 32, x) != 0) {
      throw 'The message is forged or malformed or the shared secret is invalid';
      //return -1;
    }
    crypto_stream_xor(m, 0, c, 0, d, n, k);

    ///for (i = 0; i < 32; i++) m[i] = 0;
    // FIXME: Check in tweetnacl where these 32 bytes disappear?
    return m.sublist(32);
  }

  static void _set25519(Uint64List r, List<int> a) {
    int i;
    for (i = 0; i < 16; i++) {
      r[i] = a[i];
    }
  }

  static void _car25519(Uint64List o) {
    int i;
    int v, c = 1;
    for (i = 0; i < 16; i++) {
      v = o[i] + c + 65535;
      c = v >> 16;
      o[i] = v - c * 65536;
    }
    o[0] += c - 1 + 37 * (c - 1);
  }

  static void _sel25519(Uint64List p, Uint64List q, int b) {
    _sel25519_off(p, 0, q, 0, b);
  }

  static void _sel25519_off(
      Uint64List p, final int poff, Uint64List q, final int qoff, int b) {
    int t, c = ~(b - 1);
    for (var i = 0; i < 16; i++) {
      t = c & (p[i + poff] ^ q[i + qoff]);
      p[i + poff] ^= t;
      q[i + qoff] ^= t;
    }
  }

  static void _pack25519(Uint8List o, Uint64List n, final int noff) {
    int i, j, b;
    var m = Uint64List(16), t = Uint64List(16);
    for (i = 0; i < 16; i++) {
      t[i] = n[i + noff];
    }
    _car25519(t);
    _car25519(t);
    _car25519(t);
    for (j = 0; j < 2; j++) {
      m[0] = t[0] - 0xffed;
      for (i = 1; i < 15; i++) {
        m[i] = t[i] - 0xffff - ((m[i - 1] >> 16) & 1);
        m[i - 1] &= 0xffff;
      }
      m[15] = t[15] - 0x7fff - ((m[14] >> 16) & 1);
      b = ((m[15] >> 16) & 1);
      m[14] &= 0xffff;
      _sel25519_off(t, 0, m, 0, 1 - b);
    }
    for (i = 0; i < 16; i++) {
      o[2 * i] = (t[i] & 0xff).toInt();
      o[2 * i + 1] = (t[i] >> 8);
    }
  }

  static int _neq25519(Uint64List a, Uint64List b) {
    return _neq25519_off(a, 0, b, 0);
  }

  static int _neq25519_off(
      Uint64List a, final int aoff, Uint64List b, final int boff) {
    var c = Uint8List(32), d = Uint8List(32);
    _pack25519(c, a, aoff);
    _pack25519(d, b, boff);
    return _crypto_verify_32(c, 0, d, 0);
  }

  static int _par25519(Uint64List a) {
    return _par25519_off(a, 0);
  }

  static int _par25519_off(Uint64List a, final int aoff) {
    var d = Uint8List(32);
    _pack25519(d, a, aoff);
    return (d[0] & 1);
  }

  static void _unpack25519(Uint64List o, Uint8List n) {
    int i;
    for (i = 0; i < 16; i++) {
      o[i] = (n[2 * i] & 0xff) + (((n[2 * i + 1] << 8) & 0xffff));
    }
    o[15] &= 0x7fff;
  }

  static void _A(Uint64List o, Uint64List a, Uint64List b) {
    _A_off(o, 0, a, 0, b, 0);
  }

  static void _A_off(Uint64List o, final int ooff, Uint64List a, final int aoff,
      Uint64List b, final int boff) {
    int i;
    for (i = 0; i < 16; i++) {
      o[i + ooff] = a[i + aoff] + b[i + boff];
    }
  }

  static void _Z(Uint64List o, Uint64List a, Uint64List b) {
    _Z_off(o, 0, a, 0, b, 0);
  }

  static void _Z_off(Uint64List o, final int ooff, Uint64List a, final int aoff,
      Uint64List b, final int boff) {
    int i;
    for (i = 0; i < 16; i++) {
      o[i + ooff] = a[i + aoff] - b[i + boff];
    }
  }

  static void _M(Uint64List o, Uint64List a, Uint64List b) {
    _M_off(o, 0, a, 0, b, 0);
  }

  static void _M_off(Uint64List o, final int ooff, Uint64List a, final int aoff,
      Uint64List b, final int boff) {
    int v,
        c,
        t0 = 0,
        t1 = 0,
        t2 = 0,
        t3 = 0,
        t4 = 0,
        t5 = 0,
        t6 = 0,
        t7 = 0,
        t8 = 0,
        t9 = 0,
        t10 = 0,
        t11 = 0,
        t12 = 0,
        t13 = 0,
        t14 = 0,
        t15 = 0,
        t16 = 0,
        t17 = 0,
        t18 = 0,
        t19 = 0,
        t20 = 0,
        t21 = 0,
        t22 = 0,
        t23 = 0,
        t24 = 0,
        t25 = 0,
        t26 = 0,
        t27 = 0,
        t28 = 0,
        t29 = 0,
        t30 = 0,
        b0 = b[0 + boff],
        b1 = b[1 + boff],
        b2 = b[2 + boff],
        b3 = b[3 + boff],
        b4 = b[4 + boff],
        b5 = b[5 + boff],
        b6 = b[6 + boff],
        b7 = b[7 + boff],
        b8 = b[8 + boff],
        b9 = b[9 + boff],
        b10 = b[10 + boff],
        b11 = b[11 + boff],
        b12 = b[12 + boff],
        b13 = b[13 + boff],
        b14 = b[14 + boff],
        b15 = b[15 + boff];

    v = a[0 + aoff];
    t0 += v * b0;
    t1 += v * b1;
    t2 += v * b2;
    t3 += v * b3;
    t4 += v * b4;
    t5 += v * b5;
    t6 += v * b6;
    t7 += v * b7;
    t8 += v * b8;
    t9 += v * b9;
    t10 += v * b10;
    t11 += v * b11;
    t12 += v * b12;
    t13 += v * b13;
    t14 += v * b14;
    t15 += v * b15;
    v = a[1 + aoff];
    t1 += v * b0;
    t2 += v * b1;
    t3 += v * b2;
    t4 += v * b3;
    t5 += v * b4;
    t6 += v * b5;
    t7 += v * b6;
    t8 += v * b7;
    t9 += v * b8;
    t10 += v * b9;
    t11 += v * b10;
    t12 += v * b11;
    t13 += v * b12;
    t14 += v * b13;
    t15 += v * b14;
    t16 += v * b15;
    v = a[2 + aoff];
    t2 += v * b0;
    t3 += v * b1;
    t4 += v * b2;
    t5 += v * b3;
    t6 += v * b4;
    t7 += v * b5;
    t8 += v * b6;
    t9 += v * b7;
    t10 += v * b8;
    t11 += v * b9;
    t12 += v * b10;
    t13 += v * b11;
    t14 += v * b12;
    t15 += v * b13;
    t16 += v * b14;
    t17 += v * b15;
    v = a[3 + aoff];
    t3 += v * b0;
    t4 += v * b1;
    t5 += v * b2;
    t6 += v * b3;
    t7 += v * b4;
    t8 += v * b5;
    t9 += v * b6;
    t10 += v * b7;
    t11 += v * b8;
    t12 += v * b9;
    t13 += v * b10;
    t14 += v * b11;
    t15 += v * b12;
    t16 += v * b13;
    t17 += v * b14;
    t18 += v * b15;
    v = a[4 + aoff];
    t4 += v * b0;
    t5 += v * b1;
    t6 += v * b2;
    t7 += v * b3;
    t8 += v * b4;
    t9 += v * b5;
    t10 += v * b6;
    t11 += v * b7;
    t12 += v * b8;
    t13 += v * b9;
    t14 += v * b10;
    t15 += v * b11;
    t16 += v * b12;
    t17 += v * b13;
    t18 += v * b14;
    t19 += v * b15;
    v = a[5 + aoff];
    t5 += v * b0;
    t6 += v * b1;
    t7 += v * b2;
    t8 += v * b3;
    t9 += v * b4;
    t10 += v * b5;
    t11 += v * b6;
    t12 += v * b7;
    t13 += v * b8;
    t14 += v * b9;
    t15 += v * b10;
    t16 += v * b11;
    t17 += v * b12;
    t18 += v * b13;
    t19 += v * b14;
    t20 += v * b15;
    v = a[6 + aoff];
    t6 += v * b0;
    t7 += v * b1;
    t8 += v * b2;
    t9 += v * b3;
    t10 += v * b4;
    t11 += v * b5;
    t12 += v * b6;
    t13 += v * b7;
    t14 += v * b8;
    t15 += v * b9;
    t16 += v * b10;
    t17 += v * b11;
    t18 += v * b12;
    t19 += v * b13;
    t20 += v * b14;
    t21 += v * b15;
    v = a[7 + aoff];
    t7 += v * b0;
    t8 += v * b1;
    t9 += v * b2;
    t10 += v * b3;
    t11 += v * b4;
    t12 += v * b5;
    t13 += v * b6;
    t14 += v * b7;
    t15 += v * b8;
    t16 += v * b9;
    t17 += v * b10;
    t18 += v * b11;
    t19 += v * b12;
    t20 += v * b13;
    t21 += v * b14;
    t22 += v * b15;
    v = a[8 + aoff];
    t8 += v * b0;
    t9 += v * b1;
    t10 += v * b2;
    t11 += v * b3;
    t12 += v * b4;
    t13 += v * b5;
    t14 += v * b6;
    t15 += v * b7;
    t16 += v * b8;
    t17 += v * b9;
    t18 += v * b10;
    t19 += v * b11;
    t20 += v * b12;
    t21 += v * b13;
    t22 += v * b14;
    t23 += v * b15;
    v = a[9 + aoff];
    t9 += v * b0;
    t10 += v * b1;
    t11 += v * b2;
    t12 += v * b3;
    t13 += v * b4;
    t14 += v * b5;
    t15 += v * b6;
    t16 += v * b7;
    t17 += v * b8;
    t18 += v * b9;
    t19 += v * b10;
    t20 += v * b11;
    t21 += v * b12;
    t22 += v * b13;
    t23 += v * b14;
    t24 += v * b15;
    v = a[10 + aoff];
    t10 += v * b0;
    t11 += v * b1;
    t12 += v * b2;
    t13 += v * b3;
    t14 += v * b4;
    t15 += v * b5;
    t16 += v * b6;
    t17 += v * b7;
    t18 += v * b8;
    t19 += v * b9;
    t20 += v * b10;
    t21 += v * b11;
    t22 += v * b12;
    t23 += v * b13;
    t24 += v * b14;
    t25 += v * b15;
    v = a[11 + aoff];
    t11 += v * b0;
    t12 += v * b1;
    t13 += v * b2;
    t14 += v * b3;
    t15 += v * b4;
    t16 += v * b5;
    t17 += v * b6;
    t18 += v * b7;
    t19 += v * b8;
    t20 += v * b9;
    t21 += v * b10;
    t22 += v * b11;
    t23 += v * b12;
    t24 += v * b13;
    t25 += v * b14;
    t26 += v * b15;
    v = a[12 + aoff];
    t12 += v * b0;
    t13 += v * b1;
    t14 += v * b2;
    t15 += v * b3;
    t16 += v * b4;
    t17 += v * b5;
    t18 += v * b6;
    t19 += v * b7;
    t20 += v * b8;
    t21 += v * b9;
    t22 += v * b10;
    t23 += v * b11;
    t24 += v * b12;
    t25 += v * b13;
    t26 += v * b14;
    t27 += v * b15;
    v = a[13 + aoff];
    t13 += v * b0;
    t14 += v * b1;
    t15 += v * b2;
    t16 += v * b3;
    t17 += v * b4;
    t18 += v * b5;
    t19 += v * b6;
    t20 += v * b7;
    t21 += v * b8;
    t22 += v * b9;
    t23 += v * b10;
    t24 += v * b11;
    t25 += v * b12;
    t26 += v * b13;
    t27 += v * b14;
    t28 += v * b15;
    v = a[14 + aoff];
    t14 += v * b0;
    t15 += v * b1;
    t16 += v * b2;
    t17 += v * b3;
    t18 += v * b4;
    t19 += v * b5;
    t20 += v * b6;
    t21 += v * b7;
    t22 += v * b8;
    t23 += v * b9;
    t24 += v * b10;
    t25 += v * b11;
    t26 += v * b12;
    t27 += v * b13;
    t28 += v * b14;
    t29 += v * b15;
    v = a[15 + aoff];
    t15 += v * b0;
    t16 += v * b1;
    t17 += v * b2;
    t18 += v * b3;
    t19 += v * b4;
    t20 += v * b5;
    t21 += v * b6;
    t22 += v * b7;
    t23 += v * b8;
    t24 += v * b9;
    t25 += v * b10;
    t26 += v * b11;
    t27 += v * b12;
    t28 += v * b13;
    t29 += v * b14;
    t30 += v * b15;

    t0 += 38 * t16;
    t1 += 38 * t17;
    t2 += 38 * t18;
    t3 += 38 * t19;
    t4 += 38 * t20;
    t5 += 38 * t21;
    t6 += 38 * t22;
    t7 += 38 * t23;
    t8 += 38 * t24;
    t9 += 38 * t25;
    t10 += 38 * t26;
    t11 += 38 * t27;
    t12 += 38 * t28;
    t13 += 38 * t29;
    t14 += 38 * t30;
// t15 left as is

// first car
    c = 1;
    v = t0 + c + 65535;
    c = v >> 16;
    t0 = v - c * 65536;
    v = t1 + c + 65535;
    c = v >> 16;
    t1 = v - c * 65536;
    v = t2 + c + 65535;
    c = v >> 16;
    t2 = v - c * 65536;
    v = t3 + c + 65535;
    c = v >> 16;
    t3 = v - c * 65536;
    v = t4 + c + 65535;
    c = v >> 16;
    t4 = v - c * 65536;
    v = t5 + c + 65535;
    c = v >> 16;
    t5 = v - c * 65536;
    v = t6 + c + 65535;
    c = v >> 16;
    t6 = v - c * 65536;
    v = t7 + c + 65535;
    c = v >> 16;
    t7 = v - c * 65536;
    v = t8 + c + 65535;
    c = v >> 16;
    t8 = v - c * 65536;
    v = t9 + c + 65535;
    c = v >> 16;
    t9 = v - c * 65536;
    v = t10 + c + 65535;
    c = v >> 16;
    t10 = v - c * 65536;
    v = t11 + c + 65535;
    c = v >> 16;
    t11 = v - c * 65536;
    v = t12 + c + 65535;
    c = v >> 16;
    t12 = v - c * 65536;
    v = t13 + c + 65535;
    c = v >> 16;
    t13 = v - c * 65536;
    v = t14 + c + 65535;
    c = v >> 16;
    t14 = v - c * 65536;
    v = t15 + c + 65535;
    c = v >> 16;
    t15 = v - c * 65536;
    t0 += c - 1 + 37 * (c - 1);

// second car
    c = 1;
    v = t0 + c + 65535;
    c = v >> 16;
    t0 = v - c * 65536;
    v = t1 + c + 65535;
    c = v >> 16;
    t1 = v - c * 65536;
    v = t2 + c + 65535;
    c = v >> 16;
    t2 = v - c * 65536;
    v = t3 + c + 65535;
    c = v >> 16;
    t3 = v - c * 65536;
    v = t4 + c + 65535;
    c = v >> 16;
    t4 = v - c * 65536;
    v = t5 + c + 65535;
    c = v >> 16;
    t5 = v - c * 65536;
    v = t6 + c + 65535;
    c = v >> 16;
    t6 = v - c * 65536;
    v = t7 + c + 65535;
    c = v >> 16;
    t7 = v - c * 65536;
    v = t8 + c + 65535;
    c = v >> 16;
    t8 = v - c * 65536;
    v = t9 + c + 65535;
    c = v >> 16;
    t9 = v - c * 65536;
    v = t10 + c + 65535;
    c = v >> 16;
    t10 = v - c * 65536;
    v = t11 + c + 65535;
    c = v >> 16;
    t11 = v - c * 65536;
    v = t12 + c + 65535;
    c = v >> 16;
    t12 = v - c * 65536;
    v = t13 + c + 65535;
    c = v >> 16;
    t13 = v - c * 65536;
    v = t14 + c + 65535;
    c = v >> 16;
    t14 = v - c * 65536;
    v = t15 + c + 65535;
    c = v >> 16;
    t15 = v - c * 65536;
    t0 += c - 1 + 37 * (c - 1);

    o[0 + ooff] = t0;
    o[1 + ooff] = t1;
    o[2 + ooff] = t2;
    o[3 + ooff] = t3;
    o[4 + ooff] = t4;
    o[5 + ooff] = t5;
    o[6 + ooff] = t6;
    o[7 + ooff] = t7;
    o[8 + ooff] = t8;
    o[9 + ooff] = t9;
    o[10 + ooff] = t10;
    o[11 + ooff] = t11;
    o[12 + ooff] = t12;
    o[13 + ooff] = t13;
    o[14 + ooff] = t14;
    o[15 + ooff] = t15;
  }

  static void _S(Uint64List o, Uint64List a) {
    _S_off(o, 0, a, 0);
  }

  static void _S_off(
      Uint64List o, final int ooff, Uint64List a, final int aoff) {
    _M_off(o, ooff, a, aoff, a, aoff);
  }

  static void _inv25519(
      Uint64List o, final int ooff, Uint64List i, final int ioff) {
    var c = Uint64List(16);
    int a;
    for (a = 0; a < 16; a++) {
      c[a] = i[a + ioff];
    }
    for (a = 253; a >= 0; a--) {
      _S_off(c, 0, c, 0);
      if (a != 2 && a != 4) _M_off(c, 0, c, 0, i, ioff);
    }
    for (a = 0; a < 16; a++) {
      o[a + ooff] = c[a];
    }
  }

  static void _pow2523(Uint64List o, Uint64List i) {
    var c = Uint64List(16);
    int a;

    for (a = 0; a < 16; a++) {
      c[a] = i[a];
    }

    for (a = 250; a >= 0; a--) {
      _S_off(c, 0, c, 0);
      if (a != 1) _M_off(c, 0, c, 0, i, 0);
    }

    for (a = 0; a < 16; a++) {
      o[a] = c[a];
    }
  }

  static Uint8List crypto_scalarmult(Uint8List q, Uint8List n, List<int> p) {
    var z = Int8List(32);
    var x = Uint64List(80);
    int r, i;
    var a = Uint64List(16),
        b = Uint64List(16),
        c = Uint64List(16),
        d = Uint64List(16),
        e = Uint64List(16),
        f = Uint64List(16);
    for (i = 0; i < 31; i++) {
      z[i] = n[i];
    }
    z[31] = (((n[31] & 127) | 64) & 0xff).toInt();
    z[0] &= 248;
    _unpack25519(x, Uint8List.fromList(p));
    for (i = 0; i < 16; i++) {
      b[i] = x[i];
      d[i] = a[i] = c[i] = 0;
    }
    a[0] = d[0] = 1;
    for (i = 254; i >= 0; --i) {
      r = (Int32(z[Int32(i).shiftRightUnsigned(3).toInt()])
                  .shiftRightUnsigned(i & 7))
              .toInt() &
          1;
      _sel25519(a, b, r);
      _sel25519(c, d, r);
      _A(e, a, c);
      _Z(a, a, c);
      _A(c, b, d);
      _Z(b, b, d);
      _S(d, e);
      _S(f, a);
      _M(a, c, a);
      _M(c, b, e);
      _A(e, a, c);
      _Z(a, a, c);
      _S(b, a);
      _Z(c, d, f);
      _M(a, c, Uint64List.fromList(_121665));
      _A(a, a, d);
      _M(c, c, a);
      _M(a, d, f);
      _M(d, b, x);
      _S(b, e);
      _sel25519(a, b, r);
      _sel25519(c, d, r);
    }
    for (i = 0; i < 16; i++) {
      x[i + 16] = a[i];
      x[i + 32] = c[i];
      x[i + 48] = b[i];
      x[i + 64] = d[i];
    }
    _inv25519(x, 32, x, 32);
    _M_off(x, 16, x, 16, x, 32);
    _pack25519(q, x, 16);

    return q;
  }

  static Uint8List crypto_scalarmult_base(Uint8List q, Uint8List n) {
    return crypto_scalarmult(q, n, _9);
  }

  static Uint8List crypto_box_keypair(Uint8List y, Uint8List x) {
    // NOTE: Check
    x = _randombytes_array_len(x, x.length);
    return crypto_scalarmult_base(y, x);
  }

  static Uint8List crypto_box_beforenm(Uint8List k, Uint8List y, Uint8List x) {
    var s = Uint8List(32);
    crypto_scalarmult(s, x, y);

    final res = crypto_core_hsalsa20(k, _0, s, _sigma);
    return res;
  }

  static Uint8List crypto_box_afternm(
      Uint8List c, Uint8List m, int /*long*/ d, Uint8List n, Uint8List k) {
    return crypto_secretbox(c, m, d, n, k);
  }

  static Uint8List crypto_box_open_afternm(
      Uint8List m, Uint8List c, int /*long*/ d, Uint8List n, Uint8List k) {
    return crypto_secretbox_open(m, c, d, n, k);
  }

  Uint8List crypto_box(Uint8List c, Uint8List m, int /*long*/ d, Uint8List n,
      Uint8List y, Uint8List x) {
    final k = Uint8List(32);
    crypto_box_beforenm(k, y, x);
    return crypto_box_afternm(c, m, d, n, k);
  }

  Uint8List crypto_box_open(Uint8List m, Uint8List c, int /*long*/ d,
      Uint8List n, Uint8List y, Uint8List x) {
    final k = Uint8List(32);
    crypto_box_beforenm(k, y, x);
    return crypto_box_open_afternm(m, c, d, n, k);
  }

  static final List<Int64> K = <Int64>[
    Int64.fromInts(0x428a2f98, 0xd728ae22),
    Int64.fromInts(0x71374491, 0x23ef65cd),
    Int64.fromInts(0xb5c0fbcf, 0xec4d3b2f),
    Int64.fromInts(0xe9b5dba5, 0x8189dbbc),
    Int64.fromInts(0x3956c25b, 0xf348b538),
    Int64.fromInts(0x59f111f1, 0xb605d019),
    Int64.fromInts(0x923f82a4, 0xaf194f9b),
    Int64.fromInts(0xab1c5ed5, 0xda6d8118),
    Int64.fromInts(0xd807aa98, 0xa3030242),
    Int64.fromInts(0x12835b01, 0x45706fbe),
    Int64.fromInts(0x243185be, 0x4ee4b28c),
    Int64.fromInts(0x550c7dc3, 0xd5ffb4e2),
    Int64.fromInts(0x72be5d74, 0xf27b896f),
    Int64.fromInts(0x80deb1fe, 0x3b1696b1),
    Int64.fromInts(0x9bdc06a7, 0x25c71235),
    Int64.fromInts(0xc19bf174, 0xcf692694),
    Int64.fromInts(0xe49b69c1, 0x9ef14ad2),
    Int64.fromInts(0xefbe4786, 0x384f25e3),
    Int64.fromInts(0x0fc19dc6, 0x8b8cd5b5),
    Int64.fromInts(0x240ca1cc, 0x77ac9c65),
    Int64.fromInts(0x2de92c6f, 0x592b0275),
    Int64.fromInts(0x4a7484aa, 0x6ea6e483),
    Int64.fromInts(0x5cb0a9dc, 0xbd41fbd4),
    Int64.fromInts(0x76f988da, 0x831153b5),
    Int64.fromInts(0x983e5152, 0xee66dfab),
    Int64.fromInts(0xa831c66d, 0x2db43210),
    Int64.fromInts(0xb00327c8, 0x98fb213f),
    Int64.fromInts(0xbf597fc7, 0xbeef0ee4),
    Int64.fromInts(0xc6e00bf3, 0x3da88fc2),
    Int64.fromInts(0xd5a79147, 0x930aa725),
    Int64.fromInts(0x06ca6351, 0xe003826f),
    Int64.fromInts(0x14292967, 0x0a0e6e70),
    Int64.fromInts(0x27b70a85, 0x46d22ffc),
    Int64.fromInts(0x2e1b2138, 0x5c26c926),
    Int64.fromInts(0x4d2c6dfc, 0x5ac42aed),
    Int64.fromInts(0x53380d13, 0x9d95b3df),
    Int64.fromInts(0x650a7354, 0x8baf63de),
    Int64.fromInts(0x766a0abb, 0x3c77b2a8),
    Int64.fromInts(0x81c2c92e, 0x47edaee6),
    Int64.fromInts(0x92722c85, 0x1482353b),
    Int64.fromInts(0xa2bfe8a1, 0x4cf10364),
    Int64.fromInts(0xa81a664b, 0xbc423001),
    Int64.fromInts(0xc24b8b70, 0xd0f89791),
    Int64.fromInts(0xc76c51a3, 0x0654be30),
    Int64.fromInts(0xd192e819, 0xd6ef5218),
    Int64.fromInts(0xd6990624, 0x5565a910),
    Int64.fromInts(0xf40e3585, 0x5771202a),
    Int64.fromInts(0x106aa070, 0x32bbd1b8),
    Int64.fromInts(0x19a4c116, 0xb8d2d0c8),
    Int64.fromInts(0x1e376c08, 0x5141ab53),
    Int64.fromInts(0x2748774c, 0xdf8eeb99),
    Int64.fromInts(0x34b0bcb5, 0xe19b48a8),
    Int64.fromInts(0x391c0cb3, 0xc5c95a63),
    Int64.fromInts(0x4ed8aa4a, 0xe3418acb),
    Int64.fromInts(0x5b9cca4f, 0x7763e373),
    Int64.fromInts(0x682e6ff3, 0xd6b2b8a3),
    Int64.fromInts(0x748f82ee, 0x5defb2fc),
    Int64.fromInts(0x78a5636f, 0x43172f60),
    Int64.fromInts(0x84c87814, 0xa1f0ab72),
    Int64.fromInts(0x8cc70208, 0x1a6439ec),
    Int64.fromInts(0x90befffa, 0x23631e28),
    Int64.fromInts(0xa4506ceb, 0xde82bde9),
    Int64.fromInts(0xbef9a3f7, 0xb2c67915),
    Int64.fromInts(0xc67178f2, 0xe372532b),
    Int64.fromInts(0xca273ece, 0xea26619c),
    Int64.fromInts(0xd186b8c7, 0x21c0c207),
    Int64.fromInts(0xeada7dd6, 0xcde0eb1e),
    Int64.fromInts(0xf57d4f7f, 0xee6ed178),
    Int64.fromInts(0x06f067aa, 0x72176fba),
    Int64.fromInts(0x0a637dc5, 0xa2c898a6),
    Int64.fromInts(0x113f9804, 0xbef90dae),
    Int64.fromInts(0x1b710b35, 0x131c471b),
    Int64.fromInts(0x28db77f5, 0x23047d84),
    Int64.fromInts(0x32caab7b, 0x40c72493),
    Int64.fromInts(0x3c9ebe0a, 0x15c9bebc),
    Int64.fromInts(0x431d67c4, 0x9c100d4c),
    Int64.fromInts(0x4cc5d4be, 0xcb3e42b6),
    Int64.fromInts(0x597f299c, 0xfc657e2a),
    Int64.fromInts(0x5fcb6fab, 0x3ad6faec),
    Int64.fromInts(0x6c44198c, 0x4a475817)
  ];

  static int crypto_hashblocks_hl(
      List<Int32> hh, List<Int32> hl, Uint8List m, final int moff, int n) {
    ///String dbgt = "";
    ///for (var dbg = 0; dbg < n; dbg ++) dbgt += " "+m[dbg+moff];
    ///Log.d(TAG, "crypto_hashblocks_hl m/"+n + "-> "+dbgt);

    int i, j;

    var wh = List<Int32>.filled(16, Int32(0)),
        wl = List<Int32>.filled(16, Int32(0));
    Int32 bh0,
        bh1,
        bh2,
        bh3,
        bh4,
        bh5,
        bh6,
        bh7,
        bl0,
        bl1,
        bl2,
        bl3,
        bl4,
        bl5,
        bl6,
        bl7,
        th,
        tl,
        h,
        l,
        a,
        b,
        c,
        d;

    var ah0 = hh[0],
        ah1 = hh[1],
        ah2 = hh[2],
        ah3 = hh[3],
        ah4 = hh[4],
        ah5 = hh[5],
        ah6 = hh[6],
        ah7 = hh[7],
        al0 = hl[0],
        al1 = hl[1],
        al2 = hl[2],
        al3 = hl[3],
        al4 = hl[4],
        al5 = hl[5],
        al6 = hl[6],
        al7 = hl[7];

    var pos = 0;
    while (n >= 128) {
      for (i = 0; i < 16; i++) {
        j = 8 * i + pos;
        wh[i] = Int32((m[j + 0 + moff] & 0xff) << 24) |
            ((m[j + 1 + moff] & 0xff) << 16) |
            ((m[j + 2 + moff] & 0xff) << 8) |
            ((m[j + 3 + moff] & 0xff) << 0);
        wl[i] = Int32((m[j + 4 + moff] & 0xff) << 24) |
            ((m[j + 5 + moff] & 0xff) << 16) |
            ((m[j + 6 + moff] & 0xff) << 8) |
            ((m[j + 7 + moff] & 0xff) << 0);
      }
      for (i = 0; i < 80; i++) {
        bh0 = ah0;
        bh1 = ah1;
        bh2 = ah2;
        bh3 = ah3;
        bh4 = ah4;
        bh5 = ah5;
        bh6 = ah6;
        bh7 = ah7;

        bl0 = al0;
        bl1 = al1;
        bl2 = al2;
        bl3 = al3;
        bl4 = al4;
        bl5 = al5;
        bl6 = al6;
        bl7 = al7;

        // add
        h = ah7;
        l = al7;

        a = l & 0xffff;
        b = l.shiftRightUnsigned(16);
        c = h & 0xffff;
        d = h.shiftRightUnsigned(16);

        // Sigma1
        h = ((ah4.shiftRightUnsigned(14)) | (al4 << (32 - 14))) ^
            ((ah4.shiftRightUnsigned(18)) | (al4 << (32 - 18))) ^
            ((al4.shiftRightUnsigned((41 - 32))) | (ah4 << (32 - (41 - 32))));
        l = ((al4.shiftRightUnsigned(14)) | (ah4 << (32 - 14))) ^
            ((al4.shiftRightUnsigned(18)) | (ah4 << (32 - 18))) ^
            ((ah4.shiftRightUnsigned((41 - 32))) | (al4 << (32 - (41 - 32))));

        a = a + (l & 0xffff) as Int32;
        b = b + l.shiftRightUnsigned(16) as Int32;
        c = c + (h & 0xffff) as Int32;
        d = d + h.shiftRightUnsigned(16) as Int32;

        // Ch
        h = (ah4 & ah5) ^ (~ah4 & ah6);
        l = (al4 & al5) ^ (~al4 & al6);

        a = a + (l & 0xffff) as Int32;
        b = b + l.shiftRightUnsigned(16) as Int32;
        c = c + (h & 0xffff) as Int32;
        d = d + h.shiftRightUnsigned(16) as Int32;

        // K
        ///h = K[i*2];
        ///l = K[i*2+1];
        h = Int32((K[i].shiftRightUnsigned(32) & 0xffffffff).toInt());
        l = Int32((K[i].shiftRightUnsigned(0) & 0xffffffff).toInt());

        a = a + (l & 0xffff) as Int32;
        b = b + l.shiftRightUnsigned(16) as Int32;
        c = c + (h & 0xffff) as Int32;
        d = d + h.shiftRightUnsigned(16) as Int32;

        // w
        h = wh[i % 16];
        l = wl[i % 16];

        a = a + (l & 0xffff) as Int32;
        b = b + l.shiftRightUnsigned(16) as Int32;
        c = c + (h & 0xffff) as Int32;
        d = d + h.shiftRightUnsigned(16) as Int32;

        b = b + a.shiftRightUnsigned(16) as Int32;
        c = c + b.shiftRightUnsigned(16) as Int32;
        d = d + c.shiftRightUnsigned(16) as Int32;

        th = c & 0xffff | d << 16;
        tl = a & 0xffff | b << 16;

        // add
        h = th;
        l = tl;

        a = l & 0xffff;
        b = l.shiftRightUnsigned(16);
        c = h & 0xffff;
        d = h.shiftRightUnsigned(16);

        // Sigma0
        h = ((ah0.shiftRightUnsigned(28)) | (al0 << (32 - 28))) ^
            ((al0.shiftRightUnsigned((34 - 32))) | (ah0 << (32 - (34 - 32)))) ^
            ((al0.shiftRightUnsigned((39 - 32))) | (ah0 << (32 - (39 - 32))));
        l = ((al0.shiftRightUnsigned(28)) | (ah0 << (32 - 28))) ^
            ((ah0.shiftRightUnsigned((34 - 32))) | (al0 << (32 - (34 - 32)))) ^
            ((ah0.shiftRightUnsigned((39 - 32))) | (al0 << (32 - (39 - 32))));

        a = a + (l & 0xffff) as Int32;
        b = b + l.shiftRightUnsigned(16) as Int32;
        c = c + (h & 0xffff) as Int32;
        d = d + h.shiftRightUnsigned(16) as Int32;

        // Maj
        h = (ah0 & ah1) ^ (ah0 & ah2) ^ (ah1 & ah2);
        l = (al0 & al1) ^ (al0 & al2) ^ (al1 & al2);

        a = a + (l & 0xffff) as Int32;
        b = b + l.shiftRightUnsigned(16) as Int32;
        c = c + (h & 0xffff) as Int32;
        d = d + h.shiftRightUnsigned(16) as Int32;

        b = b + a.shiftRightUnsigned(16) as Int32;
        c = c + b.shiftRightUnsigned(16) as Int32;
        d = d + c.shiftRightUnsigned(16) as Int32;

        bh7 = (c & 0xffff) | (d << 16);
        bl7 = (a & 0xffff) | (b << 16);

        // add
        h = bh3;
        l = bl3;

        a = l & 0xffff;
        b = l.shiftRightUnsigned(16);
        c = h & 0xffff;
        d = h.shiftRightUnsigned(16);

        h = th;
        l = tl;

        a = a + (l & 0xffff) as Int32;
        b = b + l.shiftRightUnsigned(16) as Int32;
        c = c + (h & 0xffff) as Int32;
        d = d + h.shiftRightUnsigned(16) as Int32;

        b = b + a.shiftRightUnsigned(16) as Int32;
        c = c + b.shiftRightUnsigned(16) as Int32;
        d = d + c.shiftRightUnsigned(16) as Int32;

        bh3 = (c & 0xffff) | (d << 16);
        bl3 = (a & 0xffff) | (b << 16);

        ah1 = bh0;
        ah2 = bh1;
        ah3 = bh2;
        ah4 = bh3;
        ah5 = bh4;
        ah6 = bh5;
        ah7 = bh6;
        ah0 = bh7;

        al1 = bl0;
        al2 = bl1;
        al3 = bl2;
        al4 = bl3;
        al5 = bl4;
        al6 = bl5;
        al7 = bl6;
        al0 = bl7;

        if (i % 16 == 15) {
          for (j = 0; j < 16; j++) {
            // add
            h = wh[j];
            l = wl[j];

            a = l & 0xffff;
            b = l.shiftRightUnsigned(16);
            c = h & 0xffff;
            d = h.shiftRightUnsigned(16);

            h = wh[(j + 9) % 16];
            l = wl[(j + 9) % 16];

            a = a + (l & 0xffff) as Int32;
            b = b + l.shiftRightUnsigned(16) as Int32;
            c = c + (h & 0xffff) as Int32;
            d = d + h.shiftRightUnsigned(16) as Int32;

            // sigma0
            th = wh[(j + 1) % 16];
            tl = wl[(j + 1) % 16];
            h = ((th.shiftRightUnsigned(1)) | (tl << (32 - 1))) ^
                ((th.shiftRightUnsigned(8)) | (tl << (32 - 8))) ^
                (th.shiftRightUnsigned(7));
            l = ((tl.shiftRightUnsigned(1)) | (th << (32 - 1))) ^
                ((tl.shiftRightUnsigned(8)) | (th << (32 - 8))) ^
                ((tl.shiftRightUnsigned(7)) | (th << (32 - 7)));

            a = a + (l & 0xffff) as Int32;
            b = b + l.shiftRightUnsigned(16) as Int32;
            c = c + (h & 0xffff) as Int32;
            d = d + h.shiftRightUnsigned(16) as Int32;

            // sigma1
            th = wh[(j + 14) % 16];
            tl = wl[(j + 14) % 16];
            h = ((th.shiftRightUnsigned(19)) | (tl << (32 - 19))) ^
                ((tl.shiftRightUnsigned((61 - 32))) |
                    (th << (32 - (61 - 32)))) ^
                (th.shiftRightUnsigned(6));
            l = ((tl.shiftRightUnsigned(19)) | (th << (32 - 19))) ^
                ((th.shiftRightUnsigned((61 - 32))) |
                    (tl << (32 - (61 - 32)))) ^
                ((tl.shiftRightUnsigned(6)) | (th << (32 - 6)));

            a = a + (l & 0xffff) as Int32;
            b = b + l.shiftRightUnsigned(16) as Int32;
            c = c + (h & 0xffff) as Int32;
            d = d + h.shiftRightUnsigned(16) as Int32;

            b = b + a.shiftRightUnsigned(16) as Int32;
            c = c + b.shiftRightUnsigned(16) as Int32;
            d = d + c.shiftRightUnsigned(16) as Int32;

            wh[j] = ((c & 0xffff) | (d << 16));
            wl[j] = ((a & 0xffff) | (b << 16));
          }
        }
      }

      // add
      h = ah0;
      l = al0;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);
      h = hh[0];
      l = hl[0];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[0] = ah0 = (c & 0xffff) | (d << 16);
      hl[0] = al0 = (a & 0xffff) | (b << 16);

      h = ah1;
      l = al1;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);

      h = hh[1];
      l = hl[1];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[1] = ah1 = (c & 0xffff) | (d << 16);
      hl[1] = al1 = (a & 0xffff) | (b << 16);

      h = ah2;
      l = al2;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);

      h = hh[2];
      l = hl[2];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[2] = ah2 = (c & 0xffff) | (d << 16);
      hl[2] = al2 = (a & 0xffff) | (b << 16);

      h = ah3;
      l = al3;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);

      h = hh[3];
      l = hl[3];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[3] = ah3 = (c & 0xffff) | (d << 16);
      hl[3] = al3 = (a & 0xffff) | (b << 16);

      h = ah4;
      l = al4;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);

      h = hh[4];
      l = hl[4];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[4] = ah4 = (c & 0xffff) | (d << 16);
      hl[4] = al4 = (a & 0xffff) | (b << 16);

      h = ah5;
      l = al5;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);

      h = hh[5];
      l = hl[5];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[5] = ah5 = (c & 0xffff) | (d << 16);
      hl[5] = al5 = (a & 0xffff) | (b << 16);

      h = ah6;
      l = al6;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);

      h = hh[6];
      l = hl[6];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[6] = ah6 = (c & 0xffff) | (d << 16);
      hl[6] = al6 = (a & 0xffff) | (b << 16);

      h = ah7;
      l = al7;

      a = l & 0xffff;
      b = l.shiftRightUnsigned(16);
      c = h & 0xffff;
      d = h.shiftRightUnsigned(16);

      h = hh[7];
      l = hl[7];

      a = a + (l & 0xffff) as Int32;
      b = b + l.shiftRightUnsigned(16) as Int32;
      c = c + (h & 0xffff) as Int32;
      d = d + h.shiftRightUnsigned(16) as Int32;

      b = b + a.shiftRightUnsigned(16) as Int32;
      c = c + b.shiftRightUnsigned(16) as Int32;
      d = d + c.shiftRightUnsigned(16) as Int32;

      hh[7] = ah7 = (c & 0xffff) | (d << 16);
      hl[7] = al7 = (a & 0xffff) | (b << 16);

      pos += 128;
      n -= 128;
    }

    return n;
  }

// TBD 64bits of n
  ///int crypto_hash(Uint8List out, Uint8List m, long n)
  ///
/*  
    
    hh224[0] = Int32(0x8c3d37c8);
    hh224[1] = Int32(0x73e19966);
    hh224[2] = Int32(0x1dfab7ae);
    hh224[3] = Int32(0x679dd514);
    hh224[4] = Int32(0x0f6d2b69);
    hh224[5] = Int32(0x77e36f73);
    hh224[6] = Int32(0x3f9d85a8);
    hh224[7] = Int32(0x1112e6ad);


    hl224[0] = Int32(0x19544da2);
    hl224[1] = Int32(0x89dcd4d6);
    hl224[2] = Int32(0x32ff9c82);
    hl224[3] = Int32(0x582f9fcf);
    hl224[4] = Int32(0x7bd44da8);
    hl224[5] = Int32(0x04c48942);
    hl224[6] = Int32(0x6a1d36c8);
    hl224[7] = Int32(0x91d692a1);
    */
  static int _crypto_hash_off(
      Uint8List out, Uint8List m, final int moff, int n) {
    var hh = List<Int32>.filled(8, Int32(0)),
        hl = List<Int32>.filled(8, Int32(0));
    var x = Uint8List(256);
    int i, b = n;
    int u;

    hh[0] = Int32(0x6a09e667);
    hh[1] = Int32(0xbb67ae85);
    hh[2] = Int32(0x3c6ef372);
    hh[3] = Int32(0xa54ff53a);
    hh[4] = Int32(0x510e527f);
    hh[5] = Int32(0x9b05688c);
    hh[6] = Int32(0x1f83d9ab);
    hh[7] = Int32(0x5be0cd19);

    hl[0] = Int32(0xf3bcc908);
    hl[1] = Int32(0x84caa73b);
    hl[2] = Int32(0xfe94f82b);
    hl[3] = Int32(0x5f1d36f1);
    hl[4] = Int32(0xade682d1);
    hl[5] = Int32(0x2b3e6c1f);
    hl[6] = Int32(0xfb41bd6b);
    hl[7] = Int32(0x137e2179);

    if (n >= 128) {
      crypto_hashblocks_hl(hh, hl, m, moff, n);
      n %= 128;
    }

    for (i = 0; i < n; i++) {
      x[i] = m[b - n + i + moff];
    }
    x[n] = 128;

    n = 256 - 128 * (n < 112 ? 1 : 0);
    x[n - 9] = 0;

    _ts64(x, n - 8, b << 3 /*(b / 0x20000000) | 0, b << 3*/);

    crypto_hashblocks_hl(hh, hl, x, 0, n);

    for (i = 0; i < 8; i++) {
      u = hh[i].toInt();
      u <<= 32;
      u |= hl[i].toInt() & 0xffffffff;
      _ts64(out, 8 * i, u);
    }

    return 0;
  }

  static int crypto_hash(Uint8List out, Uint8List m) {
    return _crypto_hash_off(out, m, 0, m.length);
  }

// gf: long[16]
  ///private static void add(gf p[4],gf q[4])
  static void _add(List<Uint64List> p, List<Uint64List> q) {
    var a = Uint64List(16);
    var b = Uint64List(16);
    var c = Uint64List(16);
    var d = Uint64List(16);
    var t = Uint64List(16);
    var e = Uint64List(16);
    var f = Uint64List(16);
    var g = Uint64List(16);
    var h = Uint64List(16);

    var p0 = p[0];
    var p1 = p[1];
    var p2 = p[2];
    var p3 = p[3];

    var q0 = q[0];
    var q1 = q[1];
    var q2 = q[2];
    var q3 = q[3];

    _Z_off(a, 0, p1, 0, p0, 0);
    _Z_off(t, 0, q1, 0, q0, 0);
    _M_off(a, 0, a, 0, t, 0);
    _A_off(b, 0, p0, 0, p1, 0);
    _A_off(t, 0, q0, 0, q1, 0);
    _M_off(b, 0, b, 0, t, 0);
    _M_off(c, 0, p3, 0, q3, 0);
    _M_off(c, 0, c, 0, Uint64List.fromList(_D2), 0);
    _M_off(d, 0, p2, 0, q2, 0);

    _A_off(d, 0, d, 0, d, 0);
    _Z_off(e, 0, b, 0, a, 0);
    _Z_off(f, 0, d, 0, c, 0);
    _A_off(g, 0, d, 0, c, 0);
    _A_off(h, 0, b, 0, a, 0);

    _M_off(p0, 0, e, 0, f, 0);
    _M_off(p1, 0, h, 0, g, 0);
    _M_off(p2, 0, g, 0, f, 0);
    _M_off(p3, 0, e, 0, h, 0);
  }

  static void _cswap(List<Uint64List> p, List<Uint64List> q, int b) {
    int i;

    for (i = 0; i < 4; i++) {
      _sel25519_off(p[i], 0, q[i], 0, b);
    }
  }

  static void _pack(Uint8List r, List<Uint64List> p) {
    var tx = Uint64List(16);
    var ty = Uint64List(16);
    var zi = Uint64List(16);

    _inv25519(zi, 0, p[2], 0);

    _M_off(tx, 0, p[0], 0, zi, 0);
    _M_off(ty, 0, p[1], 0, zi, 0);

    _pack25519(r, ty, 0);

    r[31] ^= _par25519_off(tx, 0) << 7;
  }

  static void _scalarmult(
      List<Uint64List> p, List<Uint64List> q, Uint8List s, final int soff) {
    int i;

    _set25519(p[0], _gf0);
    _set25519(p[1], _gf1);
    _set25519(p[2], _gf1);
    _set25519(p[3], _gf0);

    for (i = 255; i >= 0; --i) {
      var b = ((Int32(s[(i / 8 + soff).toInt()]).shiftRightUnsigned(i & 7))
              .toInt() &
          1);

      _cswap(p, q, b);
      _add(q, p);
      _add(p, p);
      _cswap(p, q, b);
    }
  }

  static void _scalarbase(List<Uint64List> p, Uint8List s, final int soff) {
    var q = List<Uint64List>.generate(4, (_) => Uint64List(16));

    _set25519(q[0], _X);
    _set25519(q[1], _Y);
    _set25519(q[2], _gf1);
    _M_off(q[3], 0, Uint64List.fromList(_X), 0, Uint64List.fromList(_Y), 0);
    _scalarmult(p, q, s, soff);
  }

  static int crypto_sign_keypair(Uint8List pk, Uint8List sk, Uint8List seed) {
    var k = Uint8List(64);
    var p = List<Uint64List>.generate(4, (_) => Uint64List(16));

    /// ge25519_p3 A;
    ///
    /// crypto_hash_sha512(sk, seed, 32);
    /// sk[0] &= 248;
    /// sk[31] &= 127;
    /// sk[31] |= 64;
    ///
    /// ge25519_scalarmult_base(&A, sk);
    /// ge25519_p3_tobytes(pk, &A);
    ///
    /// memmove(sk, seed, 32);
    /// memmove(sk + 32, pk, 32);

    //if (seed != 0) randombytes_array_len(sk, 32);
    _crypto_hash_off(k, seed, 0, 32);
    k[0] &= 248;
    k[31] &= 127;
    k[31] |= 64;

    _scalarbase(p, k, 0);
    _pack(pk, p);

    for (var i = 0; i < 32; i++) {
      sk[i] = seed[i];
    }
    for (var i = 0; i < 32; i++) {
      sk[i + 32] = pk[i];
    }
    return 0;
  }

  static const _L = [
    0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58, //0-7
    0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0x10
  ];
  static void _modL(Uint8List r, final int roff, Uint64List x) {
    int carry;
    int i, j;

    for (i = 63; i >= 32; --i) {
      carry = 0;
      for (j = i - 32; j < i - 12; ++j) {
        x[j] += carry - 16 * x[i] * _L[j - (i - 32)];
        carry = (x[j] + 128) >> 8;
        x[j] -= carry << 8;
      }
      x[j] += carry;
      x[i] = 0;
    }
    carry = 0;

    for (j = 0; j < 32; j++) {
      x[j] += carry - (x[31] >> 4) * _L[j];
      carry = x[j] >> 8;
      x[j] &= 255;
    }

    for (j = 0; j < 32; j++) {
      x[j] -= carry * _L[j];
    }

    for (i = 0; i < 32; i++) {
      x[i + 1] += x[i] >> 8;
      r[i + roff] = (x[i] & 255);
    }
  }

  static void _reduce(Uint8List r) {
    var x = Uint64List(64);
    int i;

    for (i = 0; i < 64; i++) {
      x[i] = (r[i] & 0xff).toInt();
    }

    for (i = 0; i < 64; i++) {
      r[i] = 0;
    }

    _modL(r, 0, x);
  }

// TBD... 64bits of n
  ///int crypto_sign(Uint8List sm, long * smlen, Uint8List m, long n, Uint8List sk)
  static int crypto_sign(Uint8List sm, int dummy /* *smlen not used*/,
      Uint8List m, final int moff, int /*long*/ n, Uint8List sk,
      [bool extended = false]) {
    var d = Uint8List(64), h = Uint8List(64), r = Uint8List(64);

    int i, j;

    var x = Uint64List(64);
    var p = List<Uint64List>.generate(4, (_) => Uint64List(16));
    var pk_offset = 32;

    /// Added support for extended private keys (96 bytes long))
    /// Assuming 64 byte-length secret keys
    /// bits have already cleared and set
    if (extended) {
      pk_offset = 64;
      for (i = 0; i < pk_offset; i++) {
        d[i] = sk[i];
      }
    } else {
      _crypto_hash_off(d, sk, 0, 32);
    }

    // For safetiness
    d[0] &= 248;
    d[31] &= 127;
    d[31] |= 64;

    //*smlen = n+64;

    for (i = 0; i < n; i++) {
      sm[64 + i] = m[i + moff];
    }

    for (i = 0; i < 32; i++) {
      sm[32 + i] = d[32 + i];
    }

    _crypto_hash_off(r, sm, 32, n + 32);
    _reduce(r);
    _scalarbase(p, r, 0);
    _pack(sm, p);

    for (i = 0; i < 32; i++) {
      sm[i + 32] = sk[i + pk_offset];
    }
    _crypto_hash_off(h, sm, 0, n + 64);
    _reduce(h);

    for (i = 0; i < 64; i++) {
      x[i] = 0;
    }

    for (i = 0; i < 32; i++) {
      x[i] = (r[i] & 0xff).toInt();
    }

    for (i = 0; i < 32; i++) {
      for (j = 0; j < 32; j++) {
        x[i + j] += (h[i] & 0xff) * (d[j] & 0xff).toInt();
      }
    }

    _modL(sm, 32, x);

    return 0;
  }

  static int _unpackneg(List<Uint64List> r, Uint8List p) {
    var t = Uint64List(16);
    var chk = Uint64List(16);
    var num = Uint64List(16);
    var den = Uint64List(16);
    var den2 = Uint64List(16);
    var den4 = Uint64List(16);
    var den6 = Uint64List(16);

    _set25519(r[2], _gf1);
    _unpack25519(r[1], p);
    _S(num, r[1]);
    _M(den, num, Uint64List.fromList(_D));
    _Z(num, num, r[2]);
    _A(den, r[2], den);

    _S(den2, den);
    _S(den4, den2);
    _M(den6, den4, den2);
    _M(t, den6, num);
    _M(t, t, den);

    _pow2523(t, t);
    _M(t, t, num);
    _M(t, t, den);
    _M(t, t, den);
    _M(r[0], t, den);

    _S(chk, r[0]);
    _M(chk, chk, den);
    if (_neq25519(chk, num) != 0) _M(r[0], r[0], Uint64List.fromList(_I));

    _S(chk, r[0]);
    _M(chk, chk, den);
    if (_neq25519(chk, num) != 0) return -1;

    if (_par25519(r[0]) ==
        (Int32(p[31] & 0xFF).shiftRightUnsigned(7).toInt())) {
      _Z(r[0], Uint64List.fromList(_gf0), r[0]);
    }

    _M(r[3], r[0], r[1]);

    return 0;
  }

  /// TBD 64bits of mlen
  ///int crypto_sign_open(Uint8Listm,long *mlen,Uint8Listsm,long n,Uint8Listpk)
  static int crypto_sign_open(Uint8List m, int dummy /* *mlen not used*/,
      Uint8List sm, final int smoff, int /*long*/ n, Uint8List pk) {
    int i;
    final t = Uint8List(32), h = Uint8List(64);
    final p = List<Uint64List>.generate(4, (_) => Uint64List(16));

    final q = List<Uint64List>.generate(4, (_) => Uint64List(16));

    ///*mlen = -1;

    if (n < 64) return -1;

    if (_unpackneg(q, pk) != 0) return -1;

    for (i = 0; i < n; i++) {
      m[i] = sm[i + smoff];
    }

    for (i = 0; i < 32; i++) {
      m[i + 32] = pk[i];
    }

    _crypto_hash_off(h, m, 0, n);

    _reduce(h);
    _scalarmult(p, q, h, 0);

    _scalarbase(q, sm, 32 + smoff);
    _add(p, q);
    _pack(t, p);

    n -= 64;
    if (_crypto_verify_32(sm, smoff, t, 0) != 0) {
// optimizing it
      ///for (i = 0; i < n; i ++) m[i] = 0;
      return -1;
    }

// TBD optimizing ...
    ///for (i = 0; i < n; i ++) m[i] = sm[i + 64 + smoff];
    ///*mlen = n;

    return 0;
  }

  static final _krandom = Random.secure();

  static Uint8List _randombytes_array(Uint8List x) {
    return _randombytes_array_len(x, x.length);
  }

  static Uint8List randombytes(int len) {
    return _randombytes_array(Uint8List(len));
  }

  static Uint8List _randombytes_array_len(Uint8List x, int len) {
    var ret = len % 4;
    Int64 rnd;
    for (var i = 0; i < len - ret; i += 4) {
      rnd = Int64(_krandom.nextInt(1 << 32));
      x[i + 0] = (rnd.shiftRightUnsigned(0).toInt());
      x[i + 1] = (rnd.shiftRightUnsigned(8).toInt());
      x[i + 2] = (rnd.shiftRightUnsigned(16).toInt());
      x[i + 3] = (rnd.shiftRightUnsigned(24).toInt());
    }
    if (ret > 0) {
      rnd = Int64(_krandom.nextInt(1 << 32));
      for (var i = len - ret; i < len; i++) {
        x[i] = (rnd.shiftRightUnsigned(8 * i).toInt());
      }
    }
    return x;
  }
}
