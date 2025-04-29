class Activity {
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final double co2PerKm;
  final int points;
  final double distance;

  Activity({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.co2PerKm,
    required this.points,
    required this.distance,
  });

  // Mockado para exemplo
  static List<Activity> getMockActivities() {
    return [
      Activity(
        type: 'Viagem de carro/Gasolina',
        startTime: DateTime(2025, 3, 12, 14, 0),
        endTime: DateTime(2025, 3, 12, 16, 20),
        co2PerKm: 0.48,
        points: 33,
        distance: 5.0,
      ),
      Activity(
        type: 'Viagem de Ônibus',
        startTime: DateTime(2025, 3, 12, 14, 0),
        endTime: DateTime(2025, 3, 12, 16, 20),
        co2PerKm: 0.48,
        points: 33,
        distance: 5.0,
      ),
      Activity(
        type: 'Viagem de Bicicleta',
        startTime: DateTime(2025, 3, 12, 14, 0),
        endTime: DateTime(2025, 3, 12, 16, 20),
        co2PerKm: 0.48,
        points: 33,
        distance: 5.0,
      ),
    ];
  }
} 