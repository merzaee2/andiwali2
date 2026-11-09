class MemberSettlement {
  final int m_id;
  final String memberName;
  final double totalPaid;
  final double totalShare;

  MemberSettlement({
    required this.m_id,
    required this.memberName,
    required this.totalPaid,
    required this.totalShare,
  });

  // Positive means they get money back. Negative means they owe money.
  double get balance => totalPaid - totalShare;
}