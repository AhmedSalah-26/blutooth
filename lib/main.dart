import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Serial App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _devices = [];
  BluetoothConnection? _connection;
  String _message = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    _getPairedDevices();
  }

  void _getPairedDevices() async {
    List<BluetoothDevice> devices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {
      _devices = devices;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connectedDevice = device;
      });

      _connection!.input?.listen((data) {
        setState(() {
          _message = String.fromCharCodes(data);
        });
      }).onDone(() {
        setState(() {
          _connectedDevice = null;
        });
      });
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void _sendMessage(String message) async {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(utf8.encode(message + "\r\n"));
      await _connection!.output.allSent;
    }
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Serial'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(
                'Bluetooth Status: ${_bluetoothState.toString().split('.').last}'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name ?? "Unknown Device"),
                  onTap: () => _connectToDevice(_devices[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter message',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _sendMessage(_controller.text);
              _controller.clear();
            },
            child: Text('Send Message'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Received: $_message'),
          ),
        ],
      ),
    );
  }
}
