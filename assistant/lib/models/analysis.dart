// lib/models/analysis.dart

class Analysis {
  final String hedef;
  final int tamamlananGorev;
  final int notSayisi;
  final String basariOrani;
  final String durum;
  final String tavsiye;

  Analysis({
    required this.hedef,
    required this.tamamlananGorev,
    required this.notSayisi,
    required this.basariOrani,
    required this.durum,
    required this.tavsiye,
  });

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      hedef: json['hedef'] ?? 'Proje yok',
      tamamlananGorev: json['tamamlanan_gorev'] ?? 0,
      notSayisi: json['not_sayisi'] ?? 0,
      basariOrani: json['basari_orani'] ?? '%0',
      durum: json['durum'] ?? 'Başlamadı',
      tavsiye: json['tavsiye'] ?? '',
    );
  }
}

class WeeklyReport {
  final List<DayData> haftaOzeti;
  final double ortalamaBasari;
  final int aktifGunSayisi;
  final String sekreterYorumu;
  final bool haftaSonuBildirimi;
  final String? bildirimMesaji;

  WeeklyReport({
    required this.haftaOzeti,
    required this.ortalamaBasari,
    required this.aktifGunSayisi,
    required this.sekreterYorumu,
    required this.haftaSonuBildirimi,
    this.bildirimMesaji,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      haftaOzeti: (json['hafta_ozeti'] as List)
          .map((e) => DayData.fromJson(e))
          .toList(),
      ortalamaBasari: (json['ortalama_basari'] ?? 0).toDouble(),
      aktifGunSayisi: json['aktif_gun_sayisi'] ?? 0,
      sekreterYorumu: json['sekreter_yorumu'] ?? '',
      haftaSonuBildirimi: json['hafta_sonu_bildirimi'] ?? false,
      bildirimMesaji: json['bildirim_mesaji'],
    );
  }
}

class DayData {
  final String tarih;
  final String gun;
  final int tamamlanan;
  final int notSayisi;
  final int basariOrani;

  DayData({
    required this.tarih,
    required this.gun,
    required this.tamamlanan,
    required this.notSayisi,
    required this.basariOrani,
  });

  factory DayData.fromJson(Map<String, dynamic> json) {
    return DayData(
      tarih: json['tarih'] ?? '',
      gun: json['gun'] ?? '',
      tamamlanan: json['tamamlanan'] ?? 0,
      notSayisi: json['not_sayisi'] ?? 0,
      basariOrani: json['basari_orani'] ?? 0,
    );
  }
}

class MonthlyReport {
  final String ay;
  final int aktifGun;
  final int toplamTamamlanan;
  final int toplamNot;
  final double ortalamaBasari;
  final String sekreterYorumu;
  final bool aySonuBildirimi;
  final String? bildirimMesaji;

  MonthlyReport({
    required this.ay,
    required this.aktifGun,
    required this.toplamTamamlanan,
    required this.toplamNot,
    required this.ortalamaBasari,
    required this.sekreterYorumu,
    required this.aySonuBildirimi,
    this.bildirimMesaji,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      ay: json['ay'] ?? '',
      aktifGun: json['aktif_gun'] ?? 0,
      toplamTamamlanan: json['toplam_tamamlanan_gorev'] ?? 0,
      toplamNot: json['toplam_not'] ?? 0,
      ortalamaBasari: (json['ortalama_basari'] ?? 0).toDouble(),
      sekreterYorumu: json['sekreter_yorumu'] ?? '',
      aySonuBildirimi: json['ay_sonu_bildirimi'] ?? false,
      bildirimMesaji: json['bildirim_mesaji'],
    );
  }
}

class Notification {
  final String tip;
  final String baslik;
  final String mesaj;
  final String detay;

  Notification({
    required this.tip,
    required this.baslik,
    required this.mesaj,
    required this.detay,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      tip: json['tip'] ?? '',
      baslik: json['baslik'] ?? '',
      mesaj: json['mesaj'] ?? '',
      detay: json['detay'] ?? '',
    );
  }
}