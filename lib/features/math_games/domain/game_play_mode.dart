/// Chế độ chơi theo đề xuất khách: đơn / đấu / song hành.
enum GamePlayMode {
  solo,
  versus,
  coop,
}

extension GamePlayModeX on GamePlayMode {
  String get query => name;

  static GamePlayMode fromQuery(String? raw) {
    return switch (raw) {
      'versus' => GamePlayMode.versus,
      'coop' => GamePlayMode.coop,
      _ => GamePlayMode.solo,
    };
  }

  String get labelVi => switch (this) {
        GamePlayMode.solo => 'Chơi 1 mình',
        GamePlayMode.versus => 'Chơi đấu vs Bạn',
        GamePlayMode.coop => 'Song hành cùng bạn',
      };
}
