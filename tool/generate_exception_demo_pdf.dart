import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final document = pw.Document(title: 'Exception Handling Demonstration');

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey900,
      ),
    ),
  );

  pw.Widget body(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
    ),
  );

  pw.Widget bullet(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(left: 8, bottom: 5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('- ', style: const pw.TextStyle(fontSize: 11)),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
          ),
        ),
      ],
    ),
  );

  pw.Widget scenario(String title, List<String> steps, String userSees) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 6),
            ...steps.map((s) => bullet(s)),
            pw.SizedBox(height: 4),
            pw.Text(
              'User sees: $userSees',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ],
        ),
      );

  document.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      ),
      build: (context) => [
        pw.Text(
          'Restaurant App: Exception Handling Demonstration',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Date: 24 April 2026',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 14),

        heading('1) Plain-language summary'),
        body(
          'When failures happen (no internet, server errors, invalid response), '
          'the app converts technical exceptions into readable messages and '
          'shows a retry path instead of crashing.',
        ),

        heading('2) Exception model in this app'),
        bullet(
          'AppException(message, statusCode?) is the app-level error object.',
        ),
        bullet(
          'ExceptionHandler.handle(error) normalizes unknown errors into a safe fallback message.',
        ),

        heading('3) Where errors are generated (API layer)'),
        bullet(
          'HTTP status not 2xx -> AppException(parsed message OR "Request failed with status <code>.")',
        ),
        bullet('SocketException -> AppException("No internet connection.")'),
        bullet('HttpException -> AppException(error.message)'),
        bullet(
          'FormatException -> AppException("Unexpected response format.")',
        ),
        bullet('Unknown errors -> ExceptionHandler.handle(error)'),

        heading('4) Where errors are consumed (Controller + UI)'),
        bullet(
          'RestaurantListController catches errors in loadRestaurants(...) and loadMore().',
        ),
        bullet(
          'Controller writes message: errorMessage.value = ExceptionHandler.handle(error).message',
        ),
        bullet(
          'RestaurantListScreen shows ErrorView + Retry when list is empty and error is present.',
        ),

        heading('5) Demonstration scenarios'),
        scenario('Scenario A: No internet', [
          'User opens the app or performs search.',
          'SocketException occurs in network request.',
          'API maps it to AppException("No internet connection.").',
          'Controller stores this message in errorMessage.',
          'UI displays error state with Retry action.',
        ], 'No internet connection.'),
        scenario(
          'Scenario B: Server returns 500',
          [
            'HTTP response status is 500.',
            'API tries to extract a message from response body JSON.',
            'If no message is available, fallback message is used.',
            'Controller forwards message to UI.',
            'UI shows retry option.',
          ],
          'Request failed with status 500. (or server-provided message)',
        ),
        scenario('Scenario C: Malformed JSON response', [
          'jsonDecode throws FormatException.',
          'API maps it to AppException("Unexpected response format.").',
          'Controller updates error message observable.',
          'UI shows recoverable error state with Retry.',
        ], 'Unexpected response format.'),

        heading('6) Why this is user-friendly'),
        bullet('Consistent error messages across screens.'),
        bullet('No raw stack traces shown to end users.'),
        bullet('Retry is available without restarting the app.'),

        heading('7) Optional next improvements'),
        bullet('Localization for all user-facing error messages.'),
        bullet('Structured analytics by error type/status code.'),
        bullet('Dedicated timeout messages and offline cache fallback.'),
      ],
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
    ),
  );

  final outputDir = Directory('docs');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File('docs/Exception_Handling_Demonstration.pdf');
  await outputFile.writeAsBytes(await document.save());

  stdout.writeln('PDF created at ${outputFile.path}');
}
