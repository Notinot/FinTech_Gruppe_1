import 'package:flutter/material.dart';

class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactions({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          'Recent Transactions:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return TransactionItem(transaction: transactions[index]);
          },
        ),
      ],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: ListTile(
        title: Text(transaction.type),
        subtitle: Text(
          'Amount: \$${transaction.amount.toStringAsFixed(2)}\n${transaction.name}',
        ),
      ),
    );
  }
}

class Transaction {
  final String type;
  final String name;
  final double amount;

  Transaction(
      {required this.type,
      required this.name,
      required this.amount,
      required DateTime date});
}
