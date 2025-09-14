enum ServiceType { driveway, salting }

extension ServiceTypeX on ServiceType {
  String get label => switch (this) {
    ServiceType.driveway => 'Driveway',
    ServiceType.salting => 'Salting',
  };

  String get iconEmoji => switch (this) {
    ServiceType.driveway => '🛻',
    ServiceType.salting => '🧂',
  };
}
