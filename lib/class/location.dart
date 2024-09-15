
import 'dart:ffi';

class Location {
  Location({
    required this.id,
    required this.name,
    this.description = "No description provided",
    required this.x,
    required this.y
  });

  double x;
  double y;
  String id;
  String name;
  String description;
}