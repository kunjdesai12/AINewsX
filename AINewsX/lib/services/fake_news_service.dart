import 'dart:convert';
import 'package:http/http.dart' as http;

class FakeNewsService {
  // ⚠️ Replace with your backend server address
  final String baseUrl = "http://127.0.0.1:5000";
  // Use http://192.168.x.x:5000 if testing on a real device connected to same WiFi

  Future<Map<String, dynamic>> detectFakeNews({required String text}) async {
    final url = Uri.parse("$baseUrl/predict");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Parse structured backend response
      return {
        "claim": data["claim"],
        "ml_label": data["ml"]["label"],
        "fake_prob": data["ml"]["probabilities"]["Fake"],
        "real_prob": data["ml"]["probabilities"]["Real"],
        "final_verdict": data["final"]["final_verdict"],
        "reason": data["final"]["reason"],
        "top_matches": data["fact"]["top_matches"] ?? [],
      };
    } else {
      throw Exception("API Error: ${response.statusCode} - ${response.body}");
    }
  }
}
