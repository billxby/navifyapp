

import 'package:Navify/class/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedLocationNotifier extends Notifier<Location> {
  @override
  Location build() {
    return Location(name: "Scan a Tag", id: "JOSHUA", x: 0.0, y:0.0);
  }
  void setLocation(Location location) {
    state = location;
  }
}

final selectedLocationNotifier = NotifierProvider<SelectedLocationNotifier, Location>(() {
  return SelectedLocationNotifier();
});
