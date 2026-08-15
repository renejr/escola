import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> gerarECompartilharBoletim({
    required String nomeAluno,
    required List<dynamic> notas,
  }) async {
    final pdf = pw.Document();

    final headers = ['Bimestre', 'Disciplina', 'Nota'];
    
    // Sort notes by bimestre just to be sure, although backend already does it
    final sortedNotas = List<Map<String, dynamic>>.from(notas);
    sortedNotas.sort((a, b) => (a['bimestre'] as int).compareTo(b['bimestre'] as int));

    final data = sortedNotas.map((nota) {
      final double valor = nota['valor_nota'] ?? 0.0;
      return [
        '${nota['bimestre']}º',
        nota['disciplina'].toString(),
        valor.toStringAsFixed(1),
      ];
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Boletim Escolar',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Aluno(a): $nomeAluno',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                },
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Gerado pelo Sistema Escolar Alpha',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Salva e compartilha o PDF via OS Share Dialog
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'boletim_$nomeAluno.pdf',
    );
  }
}
