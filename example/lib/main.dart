import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ping_discover_network_plus/ping_discover_network_plus.dart';
import 'package:wifi_info_plugin_plus/wifi_info_plugin_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String localIp = '';
  List<String> devices = [];
  bool isDiscovering = false;
  int found = -1;
  TextEditingController portController = TextEditingController(text: '80');

  void discover(BuildContext ctx) async {
    final scaffoldMessage = ScaffoldMessenger.of(context);

    setState(() {
      isDiscovering = true;
      devices.clear();
      found = -1;
    });

    String ip;
    try {
      ip = (await WifiInfoPlugin.wifiDetails)?.ipAddress ?? 'NO IP DETECTED';
      log('local ip:\t$ip');
    } catch (e) {
      const snackBar = SnackBar(
          content: Text('WiFi is not connected', textAlign: TextAlign.center));
      scaffoldMessage.showSnackBar(snackBar);
      return;
    }
    setState(() {
      localIp = ip;
    });

    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    int port = 80;
    try {
      port = int.parse(portController.text);
    } catch (e) {
      portController.text = port.toString();
    }
    log('subnet:\t$subnet, port:\t$port');

    final stream = NetworkAnalyzer.i.discover(subnet, port);

    stream.listen((NetworkAddress addr) {
      if (addr.exists) {
        log('Found device: ${addr.ip}');
        setState(() {
          devices.add(addr.ip);
          found = devices.length;
        });
      }
    })
      ..onDone(() {
        setState(() {
          isDiscovering = false;
          found = devices.length;
        });
      })
      ..onError((dynamic e) {
        const snackBar = SnackBar(
            content: Text('Unexpected exception', textAlign: TextAlign.center));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Local Network'),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: 'Port',
                  ),
                ),
                const SizedBox(height: 10),
                Text('Local ip: $localIp',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 15),
                ElevatedButton(
                    onPressed: isDiscovering ? null : () => discover(context),
                    child: Text(isDiscovering ? 'Discovering...' : 'Discover')),
                const SizedBox(height: 15),
                found >= 0
                    ? Text('Found: $found device(s)',
                        style: const TextStyle(fontSize: 16))
                    : Container(),
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: <Widget>[
                          Container(
                            height: 60,
                            padding: const EdgeInsets.only(left: 10),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.devices),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        '${devices[index]}:${portController.text}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}