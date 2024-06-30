import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailVerificationService {
  final String apiKey = 'f5b93236fb904aa98fc812cc47a5d5b7';

  Future<bool> verifyEmail(String email) async {
    final response = await http.get(
      Uri.parse('https://api.zerobounce.net/v2/validate?api_key=$apiKey&email=$email'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'valid';
    } else {
      throw Exception('Failed to verify email');
    }
  }
}
