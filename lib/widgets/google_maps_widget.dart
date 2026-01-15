import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapsWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? markerTitle;
  final Function(double, double)? onMapTap;
  final bool enableMapSelection; // true jika ingin user bisa pilih lokasi

  const GoogleMapsWidget({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.markerTitle = 'Lokasi',
    this.onMapTap,
    this.enableMapSelection = false,
  }) : super(key: key);

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  late double _latitude;
  late double _longitude;
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _latitude = -5.1400;
    _longitude = 119.4837;
    _initializeWebView();
    _initializeLocation();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            print('Maps loaded successfully');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      );
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _latitude = widget.initialLatitude!;
        _longitude = widget.initialLongitude!;
      } else {
        await _getCurrentLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
      _latitude = -5.1400;
      _longitude = 119.4837;
    }

    // Load the map after location is set
    _loadMap();

    setState(() {
      _isLoading = false;
    });
  }

  void _loadMap() {
    _webViewController.loadHtmlString('''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>body { margin: 0; padding: 0; } iframe { width: 100%; height: 100%; border: none; }</style>
</head>
<body>
  <iframe src="https://www.google.com/maps?q=$_latitude,$_longitude&z=15&output=embed" allowfullscreen="" loading="lazy"></iframe>
</body>
</html>''');
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          _latitude = -5.1400;
          _longitude = 119.4837;
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (e) {
      print('Error getting location: $e');
      _latitude = -5.1400;
      _longitude = 119.4837;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: _webViewController);
  }
}
