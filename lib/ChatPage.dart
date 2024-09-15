import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:Navify/VoiceFlow.dart';
import 'package:Navify/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'NavigationPage.dart';
import 'Tags.dart';
import 'class/location.dart';
import 'main.dart';


class ChatPage extends ConsumerStatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController = new TextEditingController();
  InAppWebViewController? webViewController;
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });

  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationNotifier);

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to ' + serverName, style: Theme.of(context).textTheme.headlineMedium)
              : isConnected
                  ? Text(location.name, style: Theme.of(context).textTheme.headlineMedium)
                  : Text('Disconnected: ' + serverName, style: Theme.of(context).textTheme.headlineMedium))),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: SlidingUpPanel(
        boxShadow: [],
        color: Colors.transparent,
        panel: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20),
              )
          ),
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 50),
                  child: Container(width: 100, height: 5, 
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: const BorderRadius.all(Radius.circular(20))
                    ),
                  ),
                ),
              ),
              Text(location.name, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(location.description, style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: 25),
              Visibility(
                visible: location.x != 0,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("Emergency Exit", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                        trailing: Icon(Icons.arrow_forward_ios_outlined),
                        onTap: () async {
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return NavigationPage(server: widget.server, target: "s_e27ab7d3f9536d9f",);
                                },
                              )
                          ).then((value) => setState(() {
                            webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://mapped-in-navify.vercel.app/view/${location.x}/${location.y}")));
                          }));
                        },
                      ),
                      Divider(),
                      ListTile(
                        title: Text("Assistant", style: Theme.of(context).textTheme.titleLarge),
                        trailing: Icon(Icons.arrow_forward_ios_outlined),
                        onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return VoiceFlowPage(server: widget.server,);
                                },
                              )
                          ).then((value) => setState(() {
                            webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://mapped-in-navify.vercel.app/view/${location.x}/${location.y}")));
                          }));
                        },
                      ),
                      Divider(),
                      ListTile(
                        title: Text("Navigation", style: Theme.of(context).textTheme.titleLarge),
                        trailing: Icon(Icons.arrow_forward_ios_outlined),
                        onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return NavigationPage(server: widget.server,);
                                },
                              )
                          ).then((value) => setState(() {
                            webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://mapped-in-navify.vercel.app/view/${location.x}/${location.y}")));
                          }));
                        },
                      ),
                    ],
                  )
              )
            ],
          )
        ),
        body: SafeArea(
          child: (location.x != 0) ? InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri("https://mapped-in-navify.vercel.app/view/${location.x}/${location.y}")),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
          ) : Center(
            child: Text("Scan to start", style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),)
          )
        ),
      )
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      if (_messageBuffer.indexOf("*") >= 0 && _messageBuffer.indexOf("&") >= 0) {
        print(_messageBuffer);
        String trim = _messageBuffer.substring(0, _messageBuffer.indexOf("&"));
        trim = trim.substring(trim.lastIndexOf("*")+1);

        // final trim = _messageBuffer.substring(_messageBuffer.lastIndexOf("*")+1, _messageBuffer.indexOf("&"));

        setState(() {
          try {
            var data = jsonDecode(trim);
            var id = data["id"];

            ref.read(selectedLocationNotifier.notifier).setLocation(Location(
              id: id,
              name: tags[id]["name"],
              x: tags[id]["location"]["latitude"],
              y: tags[id]["location"]["longitude"],
              description: tags[id]["information"]
            ));

            webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://mapped-in-navify.vercel.app/view/${ref.read(selectedLocationNotifier).x}/${ref.read(selectedLocationNotifier).y}")));


          } catch(e) {
            print("Did not decode correctly");
          }
        });
      }


      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
