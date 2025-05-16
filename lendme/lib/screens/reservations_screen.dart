import 'package:flutter/material.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomingReservationsTab(),
          _OutgoingReservationsTab(),
        ],
      ),
    );
  }
}

class _IncomingReservationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy data for UI
    final reservations = [
      {
        'itemTitle': 'Drill',
        'status': 'pending',
        'startDate': '20/03/2024',
        'endDate': '25/03/2024',
        'itemImageUrl': 'https://example.com/drill.jpg',
      },
      {
        'itemTitle': 'Ladder',
        'status': 'accepted',
        'startDate': '15/03/2024',
        'endDate': '20/03/2024',
        'itemImageUrl': 'https://example.com/ladder.jpg',
      },
    ];

    if (reservations.isEmpty) {
      return const Center(
        child: Text('No incoming reservations yet'),
      );
    }

    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        return _ReservationCard(
          reservation: reservations[index],
          isIncoming: true,
        );
      },
    );
  }
}

class _OutgoingReservationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy data for UI
    final reservations = [
      {
        'itemTitle': 'Hammer',
        'status': 'pending',
        'startDate': '22/03/2024',
        'endDate': '24/03/2024',
        'itemImageUrl': 'https://example.com/hammer.jpg',
      },
      {
        'itemTitle': 'Screwdriver Set',
        'status': 'accepted',
        'startDate': '18/03/2024',
        'endDate': '21/03/2024',
        'itemImageUrl': 'https://example.com/screwdriver.jpg',
      },
    ];

    if (reservations.isEmpty) {
      return const Center(
        child: Text('No outgoing reservations yet'),
      );
    }

    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        return _ReservationCard(
          reservation: reservations[index],
          isIncoming: false,
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final bool isIncoming;

  const _ReservationCard({
    required this.reservation,
    required this.isIncoming,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (reservation['itemImageUrl'] != null)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation['itemTitle'] ?? 'Unknown Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${reservation['status']}',
                        style: TextStyle(
                          color: _getStatusColor(reservation['status']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${reservation['startDate']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'To: ${reservation['endDate']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isIncoming && reservation['status'] == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Accept'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 