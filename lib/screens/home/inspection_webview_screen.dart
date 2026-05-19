import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InspectionWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const InspectionWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Inspection Details',
  });

  @override
  State<InspectionWebViewScreen> createState() => _InspectionWebViewScreenState();
}

class _InspectionWebViewScreenState extends State<InspectionWebViewScreen> {
  bool _isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8F9FA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading page: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _controller.reload();
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.grey[600],
            ),
          ),
          IconButton(
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              }
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.grey[600],
            ),
          ),
          IconButton(
            onPressed: () async {
              if (await _controller.canGoForward()) {
                await _controller.goForward();
              }
            },
            icon: Icon(
              Icons.arrow_forward,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading inspection details...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
