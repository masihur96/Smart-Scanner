import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_qr/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

enum QrType { url, email, phone, wifi, text, location, contact, payment }

class ResultScreen extends StatefulWidget {
  final String rawValue;

  const ResultScreen({super.key, required this.rawValue});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late QrType _type;

  @override
  void initState() {
    super.initState();
    _type = _detectType(widget.rawValue);
  }

  QrType _detectType(String value) {
    final lowerValue = value.toLowerCase();
    if (lowerValue.startsWith('http://') || lowerValue.startsWith('https://') || lowerValue.startsWith('www.')) {
      return QrType.url;
    } else if (lowerValue.startsWith('mailto:') || RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return QrType.email;
    } else if (lowerValue.startsWith('tel:') || RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
      return QrType.phone;
    } else if (value.startsWith('WIFI:')) {
      return QrType.wifi;
    } else if (value.startsWith('geo:')) {
      return QrType.location;
    } else if (value.startsWith('BEGIN:VCARD')) {
      return QrType.contact;
    } else if (value.startsWith('upi://') || 
               lowerValue.contains('bkash') || 
               lowerValue.contains('nagad')) {
      return QrType.payment;
    }
    return QrType.text;
  }

  IconData _getIcon() {
    switch (_type) {
      case QrType.url:
        return Icons.link;
      case QrType.email:
        return Icons.email;
      case QrType.phone:
        return Icons.phone;
      case QrType.wifi:
        return Icons.wifi;
      case QrType.location:
        return Icons.location_on;
      case QrType.text:
        return Icons.text_fields;
      case QrType.contact:
        return Icons.person_add;
      case QrType.payment:
        return Icons.payment;
    }
  }

  String _getTypeName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_type) {
      case QrType.url:
        return l10n.website;
      case QrType.email:
        return l10n.email;
      case QrType.phone:
        return l10n.phone;
      case QrType.wifi:
        return l10n.wifi;
      case QrType.location:
        return l10n.location;
      case QrType.text:
        return l10n.text;
      case QrType.contact:
        return 'Contact'; // TODO: Add to l10n
      case QrType.payment:
        return 'Payment'; // TODO: Add to l10n
    }
  }

  Future<void> _handleAction() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    Future<void> _launch(Uri uri, {bool external = true}) async {
      if (!await canLaunchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uri.toString())),
        );
        return;
      }
      await launchUrl(
        uri,
        mode: external
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
    }

    switch (_type) {

    // 🌐 URL
      case QrType.url:
        String raw = widget.rawValue.trim();

        // Normalize URL
        String url;
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          url = raw;
        } else {
          url = 'https://$raw';
        }

        final Uri uri = Uri.tryParse(url) ?? Uri();

        if (!uri.hasScheme) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid")),
          );
          break;
        }

        // Warn for insecure HTTP
        if (uri.scheme == 'http') {
          final bool proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.securityWarning),
              content: Text(l10n.insecureConnectionMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.openAnyway),
                ),
              ],
            ),
          ) ??
              false;

          if (!proceed) break;
        }

        // Launch externally (REQUIRED)
        if (!await canLaunchUrl(uri)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open")),
          );
          break;
        }

        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        break;

    // ✉ EMAIL
      case QrType.email:
        final email = widget.rawValue.replaceFirst('mailto:', '');
        final uri = Uri(
          scheme: 'mailto',
          path: email,
        );
        await _launch(uri, external: false);
        break;

    // 📞 PHONE
      case QrType.phone:
        final phone = widget.rawValue.replaceFirst('tel:', '');
        await _launch(Uri(scheme: 'tel', path: phone));
        break;

    // 📍 LOCATION
      case QrType.location:
        Uri uri;
        if (widget.rawValue.startsWith('geo:')) {
          uri = Uri.parse(widget.rawValue);
        } else {
          uri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.rawValue)}',
          );
        }
        await _launch(uri);
        break;

    // 📶 WIFI
      case QrType.wifi:
        final wifi = _parseWifi(widget.rawValue);

        if (wifi['P'] != null && wifi['P']!.isNotEmpty) {
          await Clipboard.setData(
            ClipboardData(text: wifi['P']!),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.rawValue)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No Password")),
          );
        }
        break;

    // 📇 CONTACT (VCARD)
      case QrType.contact:
        try {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/contact.vcf');
          await file.writeAsString(widget.rawValue);

          await Share.shareXFiles(
            [XFile(file.path)],
            text: "widget.rawValue",
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
        break;

    // 💳 PAYMENT
      case QrType.payment:
        await _launch(Uri.parse(widget.rawValue));
        break;

    // 📝 TEXT
      case QrType.text:
        await Clipboard.setData(
          ClipboardData(text: widget.rawValue),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.copiedToClipboard)),
        );
        break;
    }
  }


  Map<String, String> _parseWifi(String raw) {
    final data = <String, String>{};
    final parts = raw.substring(5).split(';');
    for (final part in parts) {
      final subParts = part.split(':');
      if (subParts.length >= 2) {
        data[subParts[0]] = subParts.sublist(1).join(':');
      }
    }
    return data;
  }

  String _getActionLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_type) {
      case QrType.url:
        return '${l10n.open} ${l10n.website}';
      case QrType.email:
        return l10n.email;
      case QrType.phone:
        return l10n.phone;
      case QrType.wifi:
        return 'Copy Password'; // TODO: l10n
      case QrType.location:
        return l10n.location;
      case QrType.contact:
        return 'Save Contact'; // TODO: l10n
      case QrType.payment:
        return 'Pay Now'; // TODO: l10n
      case QrType.text:
        return l10n.copy;
    }
  }

  String _getDisplayValue() {
    if (_type == QrType.wifi) {
      final data = _parseWifi(widget.rawValue);
      return 'SSID: ${data['S'] ?? 'Unknown'}';
    } else if (_type == QrType.contact) {
      // Simple parsing for display
      final lines = widget.rawValue.split('\n');
      for (final line in lines) {
        if (line.startsWith('FN:')) {
          return line.substring(3);
        } else if (line.startsWith('N:')) {
          return line.substring(2).replaceAll(';', ' ').trim();
        }
      }
    }
    return widget.rawValue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanResult),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(_getIcon(), size: 48, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      _getTypeName(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDisplayValue(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_type != QrType.text)
              ElevatedButton.icon(
                onPressed: _handleAction,
                icon: const Icon(Icons.open_in_new),
                label: Text(_getActionLabel(context)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.rawValue));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copiedToClipboard)),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.copy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(widget.rawValue);
                    },
                    icon: const Icon(Icons.share),
                    label: Text(l10n.share),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
