import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapsDisplayPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String title;
  final bool allowSelection;

  const MapsDisplayPage({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.title = 'Peta Lokasi',
    this.allowSelection = false,
  }) : super(key: key);

  @override
  State<MapsDisplayPage> createState() => _MapsDisplayPageState();
}

class _MapsDisplayPageState extends State<MapsDisplayPage> {
  late double _latitude;
  late double _longitude;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude ?? -5.1395119;
    _longitude = widget.initialLongitude ?? 119.4851;
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Izinkan hanya URL yang berasal dari Google Maps
            if (request.url.startsWith('https://www.google.com') ||
                request.url.startsWith('https://maps.google.com') ||
                request.url.startsWith('about:')) {
              return NavigationDecision.navigate;
            }
            // Tolak URL lain untuk menghindari intent:// scheme
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            html, body { 
              margin: 0; 
              padding: 0; 
              width: 100%;
              height: 100%;
            }
          </style>
        </head>
        <body>
          <iframe width="100%" height="100%" frameborder="0" style="border:0;display:block;" src="https://maps.google.com/maps?q=$_latitude,$_longitude&t=m&z=15&output=embed" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen="" loading="lazy"></iframe>
        </body>
        </html>
        ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 2,
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
