import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SendToServer {
  // =========================
  // 发送纯文本消息到后端
  // 参数：
  // id      -> 当前会话 id
  // message -> 用户输入的文本内容
  // 返回：
  // Map<String, dynamic>，包含后端返回的数据或错误信息
  // =========================
  static Future<Map<String, dynamic>> sendToServer(
    String id,
    String message,
  ) async {
    // Android 模拟器访问本机要用 10.0.2.2
    // 其他平台（如 iOS / 桌面）使用 127.0.0.1
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final String apiUrl = 'http://$host:3902/ai'; // 后端接口地址

    try {
      // 向后端发送 POST 请求
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'message': message,
        }),
      );

      // 请求成功
      if (response.statusCode == 200) {
        return {'data': response.body};
      }
      // 204 表示成功但没有返回内容
      else if (response.statusCode == 204) {
        print(response.statusCode);
        return {
          'error': false,
          'status': response.statusCode,
          'body': response.body,
        };
      }
      // 其他状态码视为请求失败
      else {
        print('Wrong : ${response}');
        return {
          'error': true,
          'status': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      // 网络异常或其他运行时错误
      print('Error: $e');
      return {'error': true, 'exception': e.toString()};
    }
  }

  // =========================
  // 发送文本 + 图片数据到后端
  // 参数：
  // id         -> 当前会话 id
  // message    -> 用户输入的文本内容
  // image_data -> 图片数据列表
  // 返回：
  // Map<String, dynamic>，包含后端返回的数据或错误信息
  // =========================
  static Future<Map<String, dynamic>> sendToServerMultipart(
    String id,
    String message,
    List image_data,
  ) async {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final String apiUrl = 'http://$host:3902/ai'; // 后端接口地址
    late var data;

    try {
      // 这里虽然函数名叫 Multipart，
      // 但当前实现实际上还是 JSON 请求，
      // 只是把图片数据一起放进 file 字段发给后端
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'message': message,
          'file': image_data,
        }),
      );

      // 请求成功
      if (response.statusCode == 200) {
        // 将后端返回的 JSON 字符串转成 Dart 对象
        data = jsonDecode(response.body);
        return {'data': data};
      }
      // 204 表示成功但没有返回内容
      else if (response.statusCode == 204) {
        print(response.statusCode);
        return {
          'error': false,
          'status': response.statusCode,
          'body': response.body,
        };
      }
      // 其他状态码视为请求失败
      else {
        print('Wrong : ${response}');
        return {
          'error': true,
          'status': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      // 网络异常或其他运行时错误
      print('Error: $e');
      return {'error': true, 'exception': e.toString()};
    }
  }
}
