import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SendToServer {
  static Future<Map<String, dynamic>> sendToServer(
    String id,
    String message,
  ) async {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final String apiUrl = 'http://$host:3902/ai'; //backend Url

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'message': message}),
      );

      if (response.statusCode == 200) {
        return {'data': response.body};
      } else if ((response.statusCode == 204)) {
        print(response.statusCode);
        return {
          'error': false,
          'status': response.statusCode,
          'body': response.body,
        };
      } else {
        print('Wrong : ${response}');
        return {
          'error': true,
          'status': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {'error': true, 'exception': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendToServerMultipart(
    String id,
    String message,
    List image_data,
  ) async {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final String apiUrl = 'http://$host:3902/ai'; //backend Url
    late var data;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'message': message, 'file': image_data}),
      );

      if (response.statusCode == 200) {
        data = jsonDecode(response.body);

        // print('$data,2');
        return {'data': data};
      } else if ((response.statusCode == 204)) {
        print(response.statusCode);
        return {
          'error': false,
          'status': response.statusCode,
          'body': response.body,
        };
      } else {
        print('Wrong : ${response}');
        return {
          'error': true,
          'status': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('Error: $e');
      return {'error': true, 'exception': e.toString()};
    }
  }
}
