class Location {
  final double latitude;
  final double longitude;
  final String title;

  Location({required this.latitude, required this.longitude, required this.title});

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
      };

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'],
      longitude: json['longitude'],
      title: json['title'],
    );
  }

  @override
  String toString() => '$latitude,$longitude';
}