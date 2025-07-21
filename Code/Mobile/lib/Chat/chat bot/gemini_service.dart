import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'car_problems_database.dart';

class GeminiService {
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String model = 'gemini-1.5-flash';
  
  // We use the API key from the .env file for security
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Function to search in the local database
  String? _findMatchInDatabase(String userQuestion) {
    // Clean the question from extras
    final cleanedQuestion = userQuestion.trim().toLowerCase();
    
    // 1. Search for exact match
    for (var problem in CarProblemsDatabase.carProblems) {
      final dbQuestion = problem['input']!.toLowerCase();
      
      // If there is an exact match or very close match
      if (dbQuestion == cleanedQuestion || 
          cleanedQuestion.contains(dbQuestion) || 
          dbQuestion.contains(cleanedQuestion)) {
        return problem['output'];
      }
    }
    
    // 2. Search for partial match by keywords
    // Split the question into words
    final questionWords = cleanedQuestion.split(' ');
    
    // Candidate problems with match counts
    Map<String, int> candidateMatches = {};
    
    for (var problem in CarProblemsDatabase.carProblems) {
      final dbQuestion = problem['input']!.toLowerCase();
      int matchCount = 0;
      
      // Count the number of matching words
      for (var word in questionWords) {
        if (word.length > 3 && dbQuestion.contains(word)) {
          matchCount++;
        }
      }
      
      // If there's a match for more than two key words
      if (matchCount >= 2) {
        candidateMatches[problem['output']!] = matchCount;
      }
    }
    
    // If we found candidates, we choose the highest matching one
    if (candidateMatches.isNotEmpty) {
      // Sort candidates by match count (descending)
      var sortedMatches = candidateMatches.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Return the highest matching answer
      return sortedMatches.first.key;
    }
    
    // No match found in the database
    return null;
  }
  
  // Method to send a message to the Gemini model
  Future<String> getChatResponse(String message) async {
    try {
      // 1. Check first in the local database
      final localMatch = _findMatchInDatabase(message);
      
      // If we found a match in the database, return the answer directly
      if (localMatch != null) {
        print('Found an answer in the local database');
        return localMatch;
      }
      
      // 2. If no match found, use the API
      print('No match found in the database, using API');
      final url = '$baseUrl/$model:generateContent?key=$apiKey';
      
      // Build the training context
      String context = "You are a car problem diagnostic assistant. When a user asks about a car problem, provide concise and helpful tips to solve it. Here are examples of how to respond to questions:\n\n";
      
      // Get 15 random examples from the database
      final examples = CarProblemsDatabase.getSampleProblems(15);
      
      // Add examples to the context
      for (var example in examples) {
        context += "Question: ${example['input']}\nAnswer: ${example['output']}\n\n";
      }
      
      context += "Question: $message\nAnswer:";
      
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': context,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topP': 0.95,
          'topK': 40,
          'maxOutputTokens': 8192,
          'responseMimeType': 'text/plain',
        }
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
        return 'I couldn\'t understand your query. Can you rephrase it?';
      } else {
        print('Gemini request failed: ${response.statusCode}');
        print('Error reason: ${response.body}');
        return 'An error occurred during connection. Please try again later.';
      }
    } catch (e) {
      print('Unexpected error: $e');
      return 'An unexpected error occurred. Please try again later.';
    }
  }
} 