import 'settlement.dart';

class Transaction {
  final String fromName; // Person paying
  final String toName;   // Person receiving
  final double amount;

  Transaction({required this.fromName, required this.toName, required this.amount});
}

class SettlementEngine {
  /// Takes a list of settlements and returns the minimum number of transactions
  /// required to settle all debts.
  static List<Transaction> calculateTransactions(List<MemberSettlement> settlements) {
    List<Transaction> transactions = [];

    // 1. Separate into debtors (owe money) and creditors (get money back)
    // We ignore anyone with a balance of exactly 0.
    List<MemberSettlement> debtors = [];
    List<MemberSettlement> creditors = [];

    for (var s in settlements) {
      // Using a small epsilon to avoid floating point precision issues (e.g., 0.00000001)
      if (s.balance < -0.01) {
        debtors.add(s);
      } else if (s.balance > 0.01) {
        creditors.add(s);
      }
    }

    // Sort them by amount descending (largest debt/credit settled first)
    debtors.sort((a, b) => a.balance.compareTo(b.balance)); // Most negative first
    creditors.sort((a, b) => b.balance.compareTo(a.balance)); // Most positive first

    // 2. Match them up
    int d = 0; // debtor index
    int c = 0; // creditor index

    while (d < debtors.length && c < creditors.length) {
      final debtor = debtors[d];
      final creditor = creditors[c];

      // The debtor owes Math.abs(debtor.balance)
      // The creditor needs creditor.balance

      // How much can we settle in this transaction?
      final amountToSettle = (debtor.balance.abs() < creditor.balance)
          ? debtor.balance.abs()
          : creditor.balance;

      transactions.add(Transaction(
        fromName: debtor.memberName,
        toName: creditor.memberName,
        amount: amountToSettle,
      ));

      // Adjust their balances.
      // Since MemberSettlement doesn't allow changing 'balance' directly,
      // we can just keep track of remaining amounts in temporary variables.
      // For simplicity, let's just mutate the list items if they were mutable,
      // but since they are immutable, we update the array items.

      final newDebtorBalance = debtor.balance + amountToSettle;
      final newCreditorBalance = creditor.balance - amountToSettle;

      debtors[d] = MemberSettlement(
          m_id: debtor.m_id,
          memberName: debtor.memberName,
          totalPaid: debtor.totalPaid,
          totalShare: debtor.totalShare + amountToSettle // Hack to adjust balance
      );

      creditors[c] = MemberSettlement(
          m_id: creditor.m_id,
          memberName: creditor.memberName,
          totalPaid: creditor.totalPaid,
          totalShare: creditor.totalShare + amountToSettle // Hack to adjust balance
      );

      // Move to next if settled
      if (newDebtorBalance >= -0.01) d++;
      if (newCreditorBalance <= 0.01) c++;
    }

    return transactions;
  }
}