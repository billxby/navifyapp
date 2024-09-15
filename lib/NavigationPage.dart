import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:Navify/VoiceFlow.dart';
import 'package:Navify/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:html/dom.dart' as dom;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:http/http.dart' as http;



import 'Tags.dart';
import 'class/location.dart';
import 'main.dart';


class NavigationPage extends ConsumerStatefulWidget {
  final BluetoothDevice server;
  final String target;

  const NavigationPage({required this.server, this.target="NONE"});

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _NavigationPageState extends ConsumerState<NavigationPage> {
  static final clientID = 0;
  BluetoothConnection? connection;
  late FlutterTts flutterTts;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController = new TextEditingController();
  InAppWebViewController? webViewController;
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  String oldTarget = "NONE";
  List<dynamic> data = [];
  List<String> instructions = [];

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    print("target is ${widget.target}");

    setState(() {
      oldTarget = widget.target;
    });

    flutterTts = FlutterTts();
    flutterTts.awaitSpeakCompletion(true);
    flutterTts.setSpeechRate(0.3);
  }

  Future<void> getWebsiteData(String scrapeUrl) async {
    print("GETTING DATA");

    final url = Uri.parse(scrapeUrl);
    final response = await http.get(url);
    dom.Document html = dom.Document.html(response.body);

    print(html.body?.classes);

    final body = html.querySelectorAll('#root > div.ChrisMcdonaldsTheGoat')
      .map((element) => element.innerHtml.trim()).toList()[0];

    print("BODY IS ${body}");
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    // if (isConnected) {
    //   isDisconnecting = true;
    //   connection?.dispose();
    //   connection = null;
    // }
    flutterTts.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Location>(selectedLocationNotifier, (prev, next) async {
      String oldUrl = (await webViewController?.getUrl())?.rawValue ?? "";
      // print("old url is ${oldUrl}");

      if (oldUrl.indexOf("/") >= 0) {
        String curr = oldUrl.substring(oldUrl.lastIndexOf("/")+1);
        // print("---------------");
        // print("curr is ${curr}");
        if (curr != "NONE") {
          oldTarget = curr;
        }
      }
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://mapped-in-navify.vercel.app/navigate/${next.x}/${next.y}/${oldTarget}")));
    });

    final location = ref.watch(selectedLocationNotifier);

    return Scaffold(
        appBar: AppBar(
            title: Text(location.name, style: Theme.of(context).textTheme.headlineMedium),),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        body: SlidingUpPanel(
          body: ((location.x != 0) ? InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri("https://mapped-in-navify.vercel.app/navigate/${location.x}/${location.y}/${oldTarget}")),
            onWebViewCreated: (controller) {
              webViewController = controller;
              controller.addJavaScriptHandler(handlerName: "steps", callback: (args) {
                print(args);

                setState(() {
                  try {
                    data = jsonDecode(args[0]);
                    print(data);
                    flutterTts.stop();

                    instructions.clear();
                    String aggregate = "";
                    for (int index=0;index<data.length;index++) {
                      instructions.add("${data[index]["type"]} ${data[index]["bearing"] != null ? "${data[index]["bearing"]} in" : ""} ${double.tryParse(data[index]["distance"].toString())?.toStringAsFixed(2)} m");
                    }
                    for (int index=1;index<data.length;index++) {
                      aggregate += instructions[index] + ". ";
                    }

                    print(aggregate);
                    flutterTts.speak(aggregate);
                  } catch(e) {
                    print(e);
                    print("Exception reached");
                    data = [];
                    instructions.clear();
                  }
                });
              });
            },
          ) : Center(
              child: Text("Scan to start", style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),)
          )),
          color: Colors.transparent,
          panel: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20),
                )
            ),
            padding: EdgeInsets.only(top: 50),
            child: SingleChildScrollView(
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: instructions.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: [
                        Text(instructions[index], style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
                        SizedBox(height: 10), Divider()
                      ],
                    );
                  },
                )
            )
          )
        )
    );
  }

}
