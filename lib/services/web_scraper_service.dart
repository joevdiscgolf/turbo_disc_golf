import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:turbo_disc_golf/models/data/user_data/pdga_player_info.dart';

class WebScraperService {
  static const String _pdgaBaseUrl = 'https://www.pdga.com';

  Future<PDGAPlayerInfo?> getPDGAPlayerInfo(int? pdgaNumber) async {
    if (pdgaNumber == null) return null;

    try {
      final http.Response response = await http.get(
        Uri.parse('$_pdgaBaseUrl/player/$pdgaNumber'),
      );

      if (response.statusCode != 200) return null;

      final Document document = html_parser.parse(response.body);
      return _parsePlayerInfo(document, pdgaNumber);
    } catch (e, trace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[WebScraperService][getPDGAPlayerInfo] exception',
      );
      return null;
    }
  }

  PDGAPlayerInfo _parsePlayerInfo(Document document, int pdgaNumber) {
    return PDGAPlayerInfo(
      pdgaNum: pdgaNumber,
      name: _parseName(document),
      location: _parseFieldByClass(document, 'location', 'Location: '),
      classification: _parseFieldByClass(
        document,
        'classification',
        'Classification: ',
      ),
      memberSince: _parseFieldByClass(document, 'join-date', 'Member Since: '),
      rating: _parseRating(document),
      careerEvents: _parseIntField(document, 'career-events', 'Career Events: '),
      careerWins: _parseIntField(document, 'career-wins', 'Career Wins: '),
      careerEarnings: _parseCareerEarnings(document),
      nextEvent: _parseFieldByClass(document, 'next-event', 'Next Event: '),
    );
  }

  String? _parseName(Document document) {
    // Try to find name in the page title or player header
    final Element? nameElement = document.querySelector('h1.page-title');
    if (nameElement != null) {
      String text = nameElement.text.trim();
      // Remove PDGA number if present (e.g., "John Doe #12345")
      final int hashIndex = text.indexOf('#');
      if (hashIndex > 0) {
        text = text.substring(0, hashIndex).trim();
      }
      return text.isNotEmpty ? text : null;
    }

    // Alternative: try pane-content
    final Element? paneElement = document.querySelector(
      'div.inside div.panel-pane div.pane-content',
    );
    if (paneElement != null) {
      String text = paneElement.text.trim();
      final int hashIndex = text.indexOf('#');
      if (hashIndex > 0) {
        text = text.substring(0, hashIndex).trim();
      }
      // Get last part after newlines
      final List<String> parts = text.split('\n');
      final String name = parts.last.trim();
      return name.isNotEmpty ? name : null;
    }

    return null;
  }

  String? _parseFieldByClass(
    Document document,
    String className,
    String prefix,
  ) {
    final Element? element = document.querySelector('li.$className');
    if (element == null) return null;

    String text = element.text.trim();
    if (text.contains(prefix)) {
      text = text.split(prefix).last.trim();
    }
    return text.isNotEmpty ? text : null;
  }

  int? _parseIntField(Document document, String className, String prefix) {
    final String? value = _parseFieldByClass(document, className, prefix);
    if (value == null) return null;
    // Remove commas from numbers like "1,234"
    final String cleanedValue = value.replaceAll(',', '');
    return int.tryParse(cleanedValue);
  }

  int? _parseRating(Document document) {
    final Element? element = document.querySelector('li.current-rating');
    if (element == null) return null;

    String text = element.text.trim();
    if (text.contains('Current Rating:')) {
      text = text.split('Current Rating:').last.trim();
      // Rating might have additional text after the number (e.g., "950 (as of...)")
      final String ratingStr = text.split(' ').first.trim();
      return int.tryParse(ratingStr);
    }
    return null;
  }

  double? _parseCareerEarnings(Document document) {
    final Element? element = document.querySelector('li.career-earnings');
    if (element == null) return null;

    String text = element.text.trim();
    if (text.contains('Career Earnings:')) {
      text = text.split('Career Earnings:').last.trim();
      // Remove dollar sign and commas: "$1,234.56" -> "1234.56"
      final String cleanedValue = text.replaceAll(RegExp(r'[\$,]'), '');
      return double.tryParse(cleanedValue);
    }
    return null;
  }
}
