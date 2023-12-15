import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/Money/TransactionHistoryScreen.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreenTEMP extends StatelessWidget {
  final Transaction transaction;
  final int userId;
  final String username;

  const TransactionDetailScreenTEMP({
    Key? key,
    required this.transaction,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
        //backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TransactionDateSection(transaction: transaction),
              TransactionTimeSection(transaction: transaction),
              TransactionTypeSection(transaction: transaction),
              UserNameSection(
                transaction: transaction,
                currentUsername: username,
                onTap: (username) => _handleUserTap(context, username),
              ),
              TransactionAmountSection(transaction: transaction),
              if (transaction.eventId != null)
                EventDetailsSection(transaction: transaction),
              if (transaction.message.isNotEmpty)
                MessageSection(transaction: transaction),
              if (isRequestRelevant(transaction, userId))
                RequestActionButtons(transaction: transaction),
              if (transaction.eventId != null) EventDetailsButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TransactionActionsNavBar(),
      floatingActionButton:
          UserOptionsFAB(transaction: transaction, currentUsername: username),
    );
  }

  void _handleUserTap(BuildContext context, String username) {
    // Implementation of user tap action
  }

  bool isRequestRelevant(Transaction transaction, int userId) {
    // Your logic to determine if the request is relevant to the current user
    return transaction.receiverId == userId;
  }
}

//widget for the transaction date
class TransactionDateSection extends StatelessWidget {
  final Transaction transaction;

  const TransactionDateSection({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      //Display the date of the transaction
      children: [
        Icon(Icons.date_range),
        SizedBox(width: 8),
        Text(
          DateFormat('dd.MM.yyyy').format(transaction.createdAt),
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}

//widget for time of transaction
class TransactionTimeSection extends StatelessWidget {
  final Transaction transaction;

  const TransactionTimeSection({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      //Display the time of the transaction
      children: [
        Icon(Icons.watch_rounded),
        SizedBox(width: 8),
        Text(
          DateFormat('HH:mm').format(transaction.createdAt),
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}

class TransactionTypeSection extends StatelessWidget {
  final Transaction transaction;

  const TransactionTypeSection({Key? key, required this.transaction})
      : super(key: key);
  //Display icon according to transaction type and whether the user is the sender or receiver. And the color based on the status of the transaction.
  @override
  Widget build(BuildContext context) {
    Icon icon = transaction.transactionType == 'Request' &&
            transaction.processed == 0
        ? Icon(Icons.request_page_outlined)
        : transaction.transactionType == 'Request' && transaction.processed == 1
            ? Icon(Icons.request_page)
            : transaction.transactionType == 'Send'
                ? Icon(Icons.send)
                : Icon(Icons.send_outlined);
    return Row(
      children: [
        icon,
        SizedBox(width: 8),
        Text(
          transaction.transactionType,
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}

class UserNameSection extends StatelessWidget {
  final Transaction transaction;
  final String currentUsername;
  final Function(String) onTap;

  const UserNameSection({
    Key? key,
    required this.transaction,
    required this.currentUsername,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String usernameToDisplay =
        getUsernameToDisplay(); // Implement this method based on your transaction logic
    bool isCurrentUser = usernameToDisplay == currentUsername;

    Icon icon =
        isCurrentUser ? Icon(Icons.person) : Icon(Icons.person_add); // Example

    // You can also use a different icon for the current user
    return GestureDetector(
      onTap: () => onTap(usernameToDisplay),
      child: Row(
        children: [
          icon,
          SizedBox(width: 8),
          Text(
            usernameToDisplay,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  String getUsernameToDisplay() {
    // Your logic to determine which username to display
    return transaction.senderUsername; // Example
  }
}

class TransactionAmountSection extends StatelessWidget {
  final Transaction transaction;

  const TransactionAmountSection({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: determineBackgroundColor(),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        formatAmount(),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color determineBackgroundColor() {
    // Your logic to determine the background color
    return Colors.green[300]!; // Example
  }

  String formatAmount() {
    // Your logic to format the amount
    return '+${NumberFormat("#,##0.00", "de_DE").format(transaction.amount)} €'; // Example
  }
}

class EventDetailsSection extends StatelessWidget {
  final Transaction transaction;

  const EventDetailsSection({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(Icons.event),
          SizedBox(width: 8),
          Text(
            'Event: //',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class MessageSection extends StatelessWidget {
  final Transaction transaction;

  const MessageSection({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(Icons.message),
          SizedBox(width: 8),
          Text(
            transaction.message,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class RequestActionButtons extends StatelessWidget {
  final Transaction transaction;

  const RequestActionButtons({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return transaction.transactionType == 'Request' &&
            transaction.processed == 0
        ? Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green),
                onPressed: () => acceptRequest(context, transaction),
                child: Text('Accept'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red),
                onPressed: () => denyRequest(context, transaction),
                child: Text('Deny'),
              ),
            ],
          )
        : SizedBox.shrink();
  }

  void acceptRequest(BuildContext context, Transaction transaction) {
    // Implementation for accepting the request
  }

  void denyRequest(BuildContext context, Transaction transaction) {
    // Implementation for denying the request
  }
}

class EventDetailsButton extends StatelessWidget {
  const EventDetailsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to event details
      },
      child: Row(
        children: [
          Icon(Icons.event),
          SizedBox(width: 8),
          Text('Event Details'),
        ],
      ),
    );
  }
}

class TransactionActionsNavBar extends StatelessWidget {
  const TransactionActionsNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.blue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          // Replace these with your actual action implementations
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.request_page),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class UserOptionsFAB extends StatelessWidget {
  final Transaction transaction;
  final String currentUsername;

  const UserOptionsFAB(
      {Key? key, required this.transaction, required this.currentUsername})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Your implementation for showing user options
      },
      child: Icon(Icons.more_vert),
    );
  }
}
