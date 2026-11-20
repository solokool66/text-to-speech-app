import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main() async {
  const trustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  const chromiumFullVersion = '143.0.3650.75';
  const secMsGecVersion = '1-$chromiumFullVersion';
  const winEpoch = 11644473600;

  int nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  int ticks = nowSeconds + winEpoch;
  ticks -= ticks % 300;
  final ticks100ns = ticks * 10000000;
  final strToHash = '$ticks100ns$trustedClientToken';
  final gec = sha256.convert(utf8.encode(strToHash)).toString().toUpperCase();

  final url = 'wss://api.msedgeservices.com/tts/cognitiveservices/websocket/v1?Ocp-Apim-Subscription-Key=$trustedClientToken&ConnectionId=test1234&Sec-MS-GEC=$gec&Sec-MS-GEC-Version=$secMsGecVersion';

  print('Testing connection with ZERO custom headers (like browser):');
  try {
    final ws = await WebSocket.connect(url);
    print('SUCCESS! Connected with ZERO custom headers!');
    await ws.close();
  } catch (e) {
    print('Failed with zero headers: $e');
  }
}
