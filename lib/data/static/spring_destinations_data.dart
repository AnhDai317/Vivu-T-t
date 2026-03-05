import 'package:vivu_tet/domain/entities/spring_destination.dart';

class SpringDestinationsData {
  static const List<SpringDestination> all = [
    SpringDestination(
      id: 'd1', name: 'Vườn Đào Nhật Tân',
      location: 'Tây Hồ, Hà Nội',
      category: 'flower', emoji: '🌸',
      description: 'Vườn đào lớn nhất Hà Nội, rực rỡ mỗi dịp Tết đến xuân về.',
      rating: 4.8, checkins: 12400,
      lat: 21.0799, lng: 105.8412, isHot: true,
      imagePath: 'assets/images/vuon_dao_nhat_tan.jpg',
    ),
    SpringDestination(
      id: 'd2', name: 'Chợ Hoa Quảng An',
      location: 'Tây Hồ, Hà Nội',
      category: 'flower', emoji: '🌺',
      description: 'Chợ hoa lớn nhất Hà Nội, họp từ đêm đến sáng sớm ngày Tết.',
      rating: 4.7, checkins: 8900,
      lat: 21.0688, lng: 105.8260, isHot: true,
      imagePath: 'assets/images/cho_hoa_quang_an.jpg',
    ),
    SpringDestination(
      id: 'd3', name: 'Chùa Trấn Quốc',
      location: 'Tây Hồ, Hà Nội',
      category: 'temple', emoji: '🛕',
      description: 'Ngôi chùa cổ nhất Hà Nội, linh thiêng bên Hồ Tây.',
      rating: 4.9, checkins: 21000,
      lat: 21.0456, lng: 105.8360, isHot: true,
      imagePath: 'assets/images/chua_tran_quoc.jpg',
    ),
    SpringDestination(
      id: 'd4', name: 'Chùa Hương',
      location: 'Mỹ Đức, Hà Nội',
      category: 'temple', emoji: '⛩️',
      description: 'Lễ hội chùa Hương lớn nhất cả nước, kéo dài 3 tháng xuân.',
      rating: 4.9, checkins: 35000,
      lat: 20.6167, lng: 105.7333, isHot: true,
      imagePath: 'assets/images/chua_huong.jpg',
    ),
    SpringDestination(
      id: 'd5', name: 'Văn Miếu Quốc Tử Giám',
      location: 'Đống Đa, Hà Nội',
      category: 'heritage', emoji: '🏛️',
      description: 'Trường đại học đầu tiên của Việt Nam, địa điểm xin chữ đầu năm.',
      rating: 4.8, checkins: 23000,
      lat: 21.0275, lng: 105.8355, isHot: true,
      imagePath: 'assets/images/van_mieu.jpg',
    ),
    SpringDestination(
      id: 'd6', name: 'Hồ Hoàn Kiếm',
      location: 'Hoàn Kiếm, Hà Nội',
      category: 'heritage', emoji: '🌊',
      description: 'Trái tim của Hà Nội, lung linh trong không khí đón xuân.',
      rating: 4.7, checkins: 45000,
      lat: 21.0285, lng: 105.8542, isHot: false,
      imagePath: 'assets/images/ho_hoan_kiem.jpg',
    ),
    SpringDestination(
      id: 'd7', name: 'Phố đi bộ Hồ Gươm',
      location: 'Hoàn Kiếm, Hà Nội',
      category: 'festival', emoji: '🎉',
      description: 'Không gian lễ hội đường phố sôi động nhất dịp Tết Nguyên Đán.',
      rating: 4.7, checkins: 38000,
      lat: 21.0285, lng: 105.8520, isHot: true,
      imagePath: 'assets/images/pho_di_bo.jpg',
    ),
    SpringDestination(
      id: 'd8', name: 'Hoàng Thành Thăng Long',
      location: 'Ba Đình, Hà Nội',
      category: 'heritage', emoji: '🏯',
      description: 'Di sản thế giới UNESCO, nơi lưu giữ lịch sử ngàn năm Thăng Long.',
      rating: 4.8, checkins: 16500,
      lat: 21.0360, lng: 105.8352, isHot: false,
      imagePath: 'assets/images/hoang_thanh.jpg',
    ),
    SpringDestination(
      id: 'd9', name: 'Đền Ngọc Sơn',
      location: 'Hoàn Kiếm, Hà Nội',
      category: 'temple', emoji: '⛩️',
      description: 'Ngôi đền linh thiêng trên đảo nhỏ giữa Hồ Hoàn Kiếm.',
      rating: 4.7, checkins: 22000,
      lat: 21.0302, lng: 105.8522, isHot: false,
      imagePath: 'assets/images/den_ngoc_son.jpg',
    ),
    SpringDestination(
      id: 'd10', name: 'Làng cổ Đường Lâm',
      location: 'Sơn Tây, Hà Nội',
      category: 'heritage', emoji: '🏡',
      description: 'Làng Việt cổ còn nguyên vẹn nhất, trải nghiệm Tết xưa.',
      rating: 4.6, checkins: 8500,
      lat: 21.1456, lng: 105.4178, isHot: false,
      imagePath: 'assets/images/lang_co_duong_lam.jpg',
    ),
  ];

  static List<SpringDestination> get featured =>
      all.where((d) => d.isHot).take(5).toList();
}