import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class Person {
  final int id;
  final String name;

  Person({required this.id, required this.name});

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(id: json['id'], name: json['name']);
  }
}

class EngineService extends ChangeNotifier {
  final String _baseUrl = 'http://127.0.0.1:8000';
  final String _wsUrl = 'ws://127.0.0.1:8000/ws';

  bool _isEngineReady = false;
  bool get isEngineReady => _isEngineReady;

  List<Person> _persons = [];
  List<Person> get persons => _persons;

  WebSocketChannel? _channel;
  Map<String, dynamic> _latestEvent = {};
  Map<String, dynamic> get latestEvent => _latestEvent;

  EngineService() {
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      if (response.statusCode == 200) {
        _isEngineReady = true;
        _connectWebSocket();
        await fetchPersons();
      } else {
        _isEngineReady = false;
      }
    } catch (e) {
      _isEngineReady = false;
    }
    notifyListeners();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
    _channel?.stream.listen((message) {
      try {
        _latestEvent = jsonDecode(message);
        notifyListeners();
      } catch (e) {
        // ignore invalid json
      }
    }, onDone: () {
      _isEngineReady = false;
      notifyListeners();
    }, onError: (err) {
      _isEngineReady = false;
      notifyListeners();
    });
  }

  Future<void> fetchPersons() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/persons'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        _persons = jsonList.map((e) => Person.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> deletePerson(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/persons/$id'));
      if (response.statusCode == 200) {
        await fetchPersons();
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }
}
