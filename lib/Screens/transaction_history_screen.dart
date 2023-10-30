import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace with actual transaction data
    List<Transaction> transactions = fetchTransactions();

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return TransactionItem(transaction: transactions[index]);
        },
      ),
    );
  }
}

class Transaction {
  final String type;
  final String name;
  final double amount;
  final DateTime date;

  Transaction({
    required this.type,
    required this.name,
    required this.amount,
    required this.date,
  });
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        transaction.type == 'Payment' ? Icons.payment : Icons.attach_money,
        color: transaction.type == 'Payment' ? Colors.red : Colors.green,
      ),
      title: Text(transaction.type),
      subtitle: Text(
        'Amount: \$${transaction.amount.toStringAsFixed(2)}\n${transaction.name}',
      ),
      trailing: Text(
        DateFormat('dd/MM/yyyy').format(transaction.date),
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}

// for testing, replace this with actual data fetching logic
List<Transaction> fetchTransactions() {
  return [
    Transaction(
        type: 'Payment',
        name: 'Dennis Kammos',
        amount: 50.0,
        date: DateTime.now()),
    Transaction(
        type: 'Received',
        name: 'Max Mustermann',
        amount: 200.0,
        date: DateTime.now()),
    Transaction(
        type: 'Received',
        name: 'Peter Meyer',
        amount: 10.0,
        date: DateTime.now()),
    Transaction(
        type: 'Payment',
        name: 'Max Mustermann',
        amount: 100.0,
        date: DateTime.now()),
    // Add more transactions here
  ];
}
