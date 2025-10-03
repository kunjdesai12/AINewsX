import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../services/fake_news_service.dart';

class FakeNewsScreen extends StatefulWidget {
  const FakeNewsScreen({super.key});

  @override
  State<FakeNewsScreen> createState() => _FakeNewsScreenState();
}

class _FakeNewsScreenState extends State<FakeNewsScreen> {
  final TextEditingController _textController = TextEditingController();
  final FakeNewsService _fakeNewsService = FakeNewsService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isLoading = false;

  // Results
  String? _mlLabel;
  double? _fakeProb;
  double? _realProb;
  String? _finalVerdict;
  String? _reason;
  List<dynamic>? _topMatches;
  String? _error;

  // ------------------------------
  // Call Backend
  // ------------------------------
  Future<void> _detectFakeNews() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter news text')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _fakeNewsService.detectFakeNews(
        text: _textController.text.trim(),
      );

      setState(() {
        _mlLabel = result["ml_label"];
        _fakeProb = result["fake_prob"];
        _realProb = result["real_prob"];
        _finalVerdict = result["final_verdict"];
        _reason = result["reason"];
        _topMatches = result["top_matches"];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ------------------------------
  // Speech-to-Text
  // ------------------------------
  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech Error: $e')),
        ),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) => setState(() {
            _textController.text = result.recognizedWords;
          }),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // ------------------------------
  // Open URL in browser
  // ------------------------------
  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch $url")),
      );
    }
  }

  // ------------------------------
  // UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake News Detection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Field
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter news text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _toggleListening,
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Detect Button
            ElevatedButton(
              onPressed: _isLoading ? null : _detectFakeNews,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Detect Fake News'),
            ),
            const SizedBox(height: 20),

            // Error
            if (_error != null)
              Text(
                "Error: $_error",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),

            // Results
            if (_finalVerdict != null) ...[
              Text(
                "Final Verdict: $_finalVerdict",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _finalVerdict!.contains("Fake")
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Reason: $_reason",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_mlLabel != null)
                Text("ML Model Prediction: $_mlLabel",
                    style: const TextStyle(fontSize: 14)),
              if (_fakeProb != null && _realProb != null)
                Text(
                  "Fake: ${(_fakeProb! * 100).toStringAsFixed(2)}% | "
                      "Real: ${(_realProb! * 100).toStringAsFixed(2)}%",
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 16),

              // Fact-check evidence
              if (_topMatches != null && _topMatches!.isNotEmpty)
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        "Supporting Articles:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._topMatches!.map((match) => Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(match["title"] ?? "No title"),
                          subtitle: Text(
                            "${match["source"] ?? "Unknown Source"} "
                                " | Sim: ${(match["similarity"] * 100).toStringAsFixed(1)}%",
                          ),
                          trailing: const Icon(Icons.open_in_new,
                              color: Colors.blue),
                          onTap: () {
                            if (match["url"] != null &&
                                match["url"].toString().isNotEmpty) {
                              _openArticle(match["url"]);
                            }
                          },
                        ),
                      )),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }
}
