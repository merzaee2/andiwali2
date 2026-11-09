class Member {
  int? m_id;
  String? full_name;
  String? phone;
  bool is_active;

  Member({this.m_id, this.full_name, this.phone, this.is_active = true});

  Map<String, dynamic> toMap() {
    return {
      'm_id': m_id,
      'full_name': full_name,
      'phone': phone,
      'is_active': is_active ? 1 : 0,
    };
  }

  static Member fromMap(Map<String, dynamic> map) {
    return Member(
      m_id: map['m_id'],
      full_name: map['full_name'],
      phone: map['phone'],
      is_active: map['is_active'] == 1,
    );
  }
}