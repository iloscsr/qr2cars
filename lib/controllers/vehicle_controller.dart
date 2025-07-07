import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_model.dart';

class VehicleController {
  static const String _key = 'vehicles';
  
  Future<List<VehicleModel>> getVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehiclesJson = prefs.getStringList(_key) ?? [];
      print('🗂️ SharedPreferences\'ten ${vehiclesJson.length} araç JSON\'ı yüklendi');
      
      final vehicles = vehiclesJson
          .map((json) => VehicleModel.fromJson(jsonDecode(json)))
          .toList();
      
      print('🚙 VehicleController.getVehicles() sonucu: ${vehicles.length} araç');
      for (int i = 0; i < vehicles.length; i++) {
        print('  Araç ${i + 1}: ${vehicles[i].name} (${vehicles[i].licensePlate})');
      }
      
      return vehicles;
    } catch (e) {
      print('❌ Araç yükleme hatası: $e');
      return [];
    }
  }

  Future<bool> addVehicle(VehicleModel vehicle) async {
    try {
      print('➕ Araç ekleme başlatıldı: ${vehicle.name} (${vehicle.licensePlate})');
      final vehicles = await getVehicles();
      print('📋 Mevcut araç sayısı: ${vehicles.length}');
      vehicles.add(vehicle);
      print('📋 Yeni araç sayısı: ${vehicles.length}');
      final result = await _saveVehicles(vehicles);
      print('💾 Kaydetme sonucu: $result');
      return result;
    } catch (e) {
      print('❌ Araç ekleme hatası: $e');
      return false;
    }
  }

  Future<bool> updateVehicle(VehicleModel vehicle) async {
    try {
      final vehicles = await getVehicles();
      final index = vehicles.indexWhere((v) => v.id == vehicle.id);
      
      if (index != -1) {
        vehicles[index] = vehicle;
        return await _saveVehicles(vehicles);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      final vehicles = await getVehicles();
      vehicles.removeWhere((v) => v.id == vehicleId);
      return await _saveVehicles(vehicles);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveVehicles(List<VehicleModel> vehicles) async {
    try {
      print('💾 _saveVehicles çağrıldı - ${vehicles.length} araç kaydedilecek');
      final prefs = await SharedPreferences.getInstance();
      final vehiclesJson = vehicles
          .map((vehicle) => jsonEncode(vehicle.toJson()))
          .toList();
      
      print('📝 JSON olarak kaydedilecek: ${vehiclesJson.length} araç');
      final result = await prefs.setStringList(_key, vehiclesJson);
      print('✅ SharedPreferences kaydetme sonucu: $result');
      
      // Doğrulama için tekrar oku
      final saved = prefs.getStringList(_key) ?? [];
      print('🔍 Doğrulama: Kaydedilen araç sayısı: ${saved.length}');
      
      return result;
    } catch (e) {
      print('❌ Araç kaydetme hatası: $e');
      return false;
    }
  }

  String generateVehicleId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
} 