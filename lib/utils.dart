library utils;

import 'dart:convert';

import 'package:crypto/crypto.dart';

String encryptPassword(String pass) {
  var toEncrypt = new SHA1();
  toEncrypt.add(UTF8.encode(pass));
  return CryptoUtils.bytesToHex(toEncrypt.close());
}