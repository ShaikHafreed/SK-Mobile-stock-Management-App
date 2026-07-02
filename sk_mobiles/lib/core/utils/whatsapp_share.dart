import 'package:url_launcher/url_launcher.dart';

class WhatsAppShare {
  /// Share bill text via WhatsApp.
  /// [phone] optional 10-digit Indian number.
  /// Empty phone → WhatsApp opens contact picker.
  static Future<bool> shareBill({
    required String billText,
    String phone = '',
  }) async {
    final encoded = Uri.encodeComponent(billText);
    final url = phone.trim().isNotEmpty
        ? 'https://wa.me/91${phone.trim()}?text=$encoded'
        : 'https://wa.me/?text=$encoded';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }

  /// Build formatted bill message
  static String buildBillText({
    required String billNo,
    required String dateStr,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double gst,
    required double total,
  }) {
    final buf = StringBuffer();
    buf.writeln('🧾 *SK MOBILES*');
    buf.writeln('Mobile Accessories Store');
    buf.writeln('');
    buf.writeln('Bill No: $billNo');
    buf.writeln('Date: $dateStr');
    if (customerName.isNotEmpty) {
      buf.writeln('Customer: $customerName');
    }
    buf.writeln('─────────────────');
    for (final item in items) {
      buf.writeln(
          '${item['name']}\n  ${item['qty']} x ₹${item['price']} = ₹${item['total']}');
    }
    buf.writeln('─────────────────');
    buf.writeln(
        'Subtotal: ₹${subtotal.toStringAsFixed(2)}');
    buf.writeln('GST (18%): ₹${gst.toStringAsFixed(2)}');
    buf.writeln(
        '*GRAND TOTAL: ₹${total.toStringAsFixed(2)}*');
    buf.writeln('');
    buf.writeln('Thank you for shopping with us! 🙏');
    return buf.toString();
  }
}