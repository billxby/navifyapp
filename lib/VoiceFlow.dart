
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import 'NavigationPage.dart';
import 'class/location.dart';

class VoiceFlowPage extends ConsumerStatefulWidget {
  final BluetoothDevice server;
  
  VoiceFlowPage({required this.server});

  @override
  ConsumerState<VoiceFlowPage> createState() => _VoiceFlowPageState();
}



class _VoiceFlowPageState extends ConsumerState<VoiceFlowPage> {

  final TextEditingController textEditingController = new TextEditingController();
  final api_key = 'VF.DM.66e651e3380effe3d506decf.GXzv4vwwZ0yKpazC';
  final String userId = "flutter_user"; // Unique user ID for the session
  late FlutterTts flutterTts;

  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    launchConversation();

    flutterTts = FlutterTts();
    flutterTts.awaitSpeakCompletion(true);
    flutterTts.setSpeechRate(0.5);// Start the conversation with a launch request
  }

  // Function to launch the conversation
  Future<void> launchConversation() async {
    await interact({"type": "launch"});
  }

  // Function to send user input and handle bot response
  Future<void> sendMessage(String userMessage) async {
    // Append the user message to the chat history
    setState(() {
      history.add({"message": userMessage, "fromBot": false});
    });

    // Send the message to the Voiceflow API
    await interact({
      "type": "text",
      "payload": userMessage,
    });
  }

  // Function to interact with the Voiceflow API
  Future<void> interact(Map<String, dynamic> request) async {
    var url = Uri.parse('https://general-runtime.voiceflow.com/state/user/$userId/interact');
    var headers = {
      "Authorization": api_key,
      "Content-Type": "application/json"
    };

    try {
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'request': request,
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        // Process the response and append bot messages to the history
        for (var trace in jsonResponse) {
          if (trace['type'] == 'speak' || trace['type'] == 'text') {
            String botMessage = trace['payload']['message'];
            if (botMessage.indexOf("I will take you to ") >= 0) {
              String targetLocation = botMessage.substring(botMessage.indexOf("I will take you to ") + 19);
              print(targetLocation);
              
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return NavigationPage(server: widget.server, target: targetLocation,);
                    },
                  )
              );
            }
            
            setState(() {
              flutterTts.stop();
              flutterTts.speak(botMessage);
              
              history.add({"message": botMessage, "fromBot": true});
            });
          } else if (trace['type'] == 'end') {
            // End of conversation
            setState(() {
              history.add({"message": "The conversation has ended.", "fromBot": true});
            });
          }
        }
      } else {
        // Handle error response
        setState(() {
          history.add({"message": "Error: Unable to connect to VoiceFlow.", "fromBot": true});
        });
      }
    } catch (error) {
      // Handle request error
      setState(() {
        history.add({"message": "Error: Something went wrong.", "fromBot": true});
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voiceflow Assistant", style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: history.length,
                itemBuilder: (BuildContext context, int index) {
                  bool fromBot = ((history[index]["fromBot"] ?? false)==true);

                  return Align(
                      alignment: fromBot ? Alignment.centerLeft : Alignment.centerRight,
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(fromBot ? 30 : 120, 0, fromBot ? 120 : 30, 20),
                          child: Container(
                            decoration: BoxDecoration(
                                color: fromBot ? Colors.lightBlueAccent : Colors.white,
                                borderRadius: const BorderRadius.all(Radius.circular(20),)
                            ),
                            padding: EdgeInsets.all(8),
                            child: Text("${history[index]["message"] ?? "Failed Message"}", style: Theme.of(context).textTheme.titleLarge),
                          )
                      )
                  );
                },

              ),
            ),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.only(top: 20, bottom: 30),
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 25.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: "Send something...",
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: true,
                      onSubmitted: (value) {
                        sendMessage(value);
                        textEditingController.clear();
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, size: 35),
                  onPressed: () {
                    sendMessage(textEditingController.text);
                    textEditingController.clear();
                  },
                )
              ],
            )
          ],
        )
      )
    );
  }

}