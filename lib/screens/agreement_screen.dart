import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AgreementGenerator extends StatefulWidget {
  @override
  _AgreementGeneratorState createState() => _AgreementGeneratorState();
}

class _AgreementGeneratorState extends State<AgreementGenerator> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pgIdController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController depositController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  bool isLoading = false;

  Future<void> generateAgreement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final pgId = pgIdController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final residentQuery = await FirebaseFirestore.instance
          .collection('residents')
          .where('email', isEqualTo: email)
          .where('pgId', isEqualTo: pgId)
          .get();
      if (residentQuery.docs.isEmpty) throw Exception('Resident not found');
      final resident = residentQuery.docs.first.data();

      final pgDoc =
          await FirebaseFirestore.instance.collection('pgs').doc(pgId).get();
      if (!pgDoc.exists) throw Exception('PG not found');
      final pgData = pgDoc.data()!;
      final ownerName = pgData['ownerName'] ?? 'N/A';
      final ownerEmail = pgData['ownerEmail'] ?? 'N/A';
      final ownerContact = pgData['contact'] ?? 'N/A';

      setState(() => isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgreementPreview(
            pgName: pgData['pgName'] ?? 'N/A',
            pgLocation: pgData['manualLocation'] ?? 'N/A',
            ownerName: ownerName,
            ownerEmail: ownerEmail,
            ownerContact: ownerContact,
            residentName: resident['name'] ?? 'N/A',
            residentEmail: resident['email'] ?? 'N/A',
            residentContact: resident['contact'] ?? 'N/A',
            roomNumber: resident['roomNumber']?.toString() ?? 'N/A',
            rent: rentController.text.trim(),
            deposit: depositController.text.trim(),
            duration: durationController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    buildStyledTextField(
                      controller: emailController,
                      labelText: 'Resident Email',
                      validator: (val) => val!.isEmpty ? 'Enter email' : null,
                    ),
                    buildStyledTextField(
                      controller: passwordController,
                      labelText: 'Password',
                      obscureText: true,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter password' : null,
                    ),
                    buildStyledTextField(
                      controller: pgIdController,
                      labelText: 'PG ID',
                      validator: (val) => val!.isEmpty ? 'Enter PG ID' : null,
                    ),
                    buildStyledTextField(
                      controller: rentController,
                      labelText: 'Rent (Rupees)',
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Enter rent' : null,
                    ),
                    buildStyledTextField(
                      controller: depositController,
                      labelText: 'Deposit (Rupees)',
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Enter deposit' : null,
                    ),
                    buildStyledTextField(
                      controller: durationController,
                      labelText: 'Duration (months)',
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter duration' : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: generateAgreement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Preview Agreement',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class AgreementPreview extends StatelessWidget {
  final String pgName, pgLocation, ownerName, ownerEmail, ownerContact;
  final String residentName, residentEmail, residentContact, roomNumber;
  final String rent, deposit, duration;

  AgreementPreview({
    required this.pgName,
    required this.pgLocation,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerContact,
    required this.residentName,
    required this.residentEmail,
    required this.residentContact,
    required this.roomNumber,
    required this.rent,
    required this.deposit,
    required this.duration,
  });

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final titleFont = await PdfGoogleFonts.eBGaramondBold();
    final bodyFont = await PdfGoogleFonts.loraRegular();
    final bodyBold = await PdfGoogleFonts.loraSemiBold();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
            padding: pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('PG Rental Agreement',
                      style: pw.TextStyle(font: titleFont, fontSize: 24)),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'This Agreement is made between the PG owner and the resident as per the following terms and conditions:',
                  style: pw.TextStyle(font: bodyFont, fontSize: 12),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 20),
                pw.Text('PG Name: $pgName',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('PG Location: $pgLocation',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Owner Name: $ownerName',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Owner Email: $ownerEmail',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Owner Contact: $ownerContact',
                    style: pw.TextStyle(font: bodyFont)),
                pw.SizedBox(height: 10),
                pw.Text('Resident Name: $residentName',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Resident Email: $residentEmail',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Resident Contact: $residentContact',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Room Number: $roomNumber',
                    style: pw.TextStyle(font: bodyFont)),
                pw.SizedBox(height: 20),
                pw.Text('Rent: Rupees $rent',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Deposit: Rupees $deposit',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Text('Duration: $duration months',
                    style: pw.TextStyle(font: bodyFont)),
                pw.SizedBox(height: 20),
                pw.Text(
                    'Signed on: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: pw.TextStyle(font: bodyFont)),
                pw.SizedBox(height: 20),
                pw.Text(
                    'The resident agrees to all the terms and conditions stated below.',
                    style: pw.TextStyle(font: bodyBold, fontSize: 12),
                    textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 20),
                pw.Text('Terms and Conditions:',
                    style: pw.TextStyle(font: bodyBold, fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Bullet(
                    text: 'Rent must be paid on or before the due date.',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Bullet(
                    text: 'Resident shall not engage in any illegal activity.',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Bullet(
                    text: 'No damage shall be done to PG property.',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Bullet(
                    text: 'Maintain cleanliness and hygiene.',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Bullet(
                    text: 'Violation may lead to termination of agreement.',
                    style: pw.TextStyle(font: bodyFont)),
                pw.Bullet(
                    text:
                        'Security deposit is refundable upon proper handover.',
                    style: pw.TextStyle(font: bodyFont)),
                pw.SizedBox(height: 40),
                pw.Text('Owner Signature: __________________________',
                    style: pw.TextStyle(font: bodyFont)),
                pw.SizedBox(height: 10),
                pw.Text('Resident Signature: ________________________',
                    style: pw.TextStyle(font: bodyFont)),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  Future<void> _savePdf(Uint8List bytes) async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission not granted');
      }

      final downloadsPath = Directory('/storage/emulated/0/Download');
      final file = File('${downloadsPath.path}/PG_Agreement_$residentName.pdf');
      await file.writeAsBytes(bytes);
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/PG_Agreement_$residentName.pdf');
      await file.writeAsBytes(bytes);
    } else {
      throw Exception('Unsupported platform');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agreement Preview'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(format),
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName: 'PG_Agreement_$residentName.pdf',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Download PDF'),
              onPressed: () async {
                try {
                  final pdfBytes = await _generatePdf(PdfPageFormat.a4);
                  await _savePdf(pdfBytes);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF saved to downloads folder')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving PDF: $e')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
