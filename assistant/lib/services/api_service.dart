// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/analysis.dart';

class ApiService {
  static const baseUrl = 'http://192.168.1.166:8000'; // kendi IP'ni gir

  static Future<Analysis> fetchAnalysis() async {
    final response = await http.get(Uri.parse('$baseUrl/analysis'));
    if (response.statusCode == 200) {
      return Analysis.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Veri alınamadı');
  }

  static Future<Map<String, dynamic>> completeTask(int index) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complete-task'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'task_index': index}),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Görev tamamlanamadı');
  }

  static Future<Map<String, dynamic>> addProgress(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/progress'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': text}),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Not kaydedilemedi');
  }

  static Future<Map<String, dynamic>> createProject(String goal, int days) async {
    final response = await http.post(
      Uri.parse('$baseUrl/project'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'goal': goal, 'duration_days': days}),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Proje oluşturulamadı');
  }

  static Future<WeeklyReport> fetchWeeklyReport() async {
    final response = await http.get(Uri.parse('$baseUrl/report/weekly'));
    if (response.statusCode == 200) {
      return WeeklyReport.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Haftalık rapor alınamadı');
  }

  static Future<MonthlyReport> fetchMonthlyReport() async {
    final response = await http.get(Uri.parse('$baseUrl/report/monthly'));
    if (response.statusCode == 200) {
      return MonthlyReport.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Aylık rapor alınamadı');
  }

  static Future<Map<String, dynamic>> checkNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/check-notifications'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    return {'bildirim_var': false, 'bildirimler': []};
  }

  static Future<Map<String, dynamic>> setApiKey(String key) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set-api-key'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'api_key': key}),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('API key ayarlanamadı');
  }

  static Future<Map<String, dynamic>> getTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/tasks'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Gorevler alinamadi');
  }

  static Future<Map<String, dynamic>> getApiStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api-status'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    return {'ai_aktif': false};
  }

  static Future<Map<String, dynamic>> fetchSuggest() async {
    final response = await http.get(Uri.parse('$baseUrl/suggest'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Öneri alınamadı');
  }

  // ---- YENİ: CHAT ----

  static Future<Map<String, dynamic>> chat(
      String message, List<Map<String, dynamic>> history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message': message,
        'history': history,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Chat yanıtı alınamadı');
  }

  static Future<Map<String, dynamic>> createProjectFromChat(
      List<String> tasks) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/create-project'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'tasks': tasks}),
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Görevler eklenemedi');
  }
}