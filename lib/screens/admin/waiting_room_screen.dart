import 'package:flutter/material.dart';

class WaitingRoomScreen extends StatelessWidget {
  final String sessionCode;
  final String selectedQuizTitle;
  final int questionsCount;
  final List<Map<String, dynamic>> participants;
  final Function onLaunchQuiz;

  const WaitingRoomScreen({
    Key? key,
    required this.sessionCode,
    required this.selectedQuizTitle,
    required this.questionsCount,
    required this.participants,
    required this.onLaunchQuiz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String qrCodeUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$sessionCode';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.play_circle_filled, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'QuizTime',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF0A2463),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E5CB3), Color(0xFFE6F0FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Waiting Room',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Quiz: $selectedQuizTitle',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$questionsCount questions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Session code and QR section
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code,
                                        color: Color(0xFF0A2463),
                                        size: 28
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Session Code',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A2463),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                  ),
                                  padding: EdgeInsets.all(15),
                                  child: Image.network(
                                    qrCodeUrl,
                                    width: 180,
                                    height: 180,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE6F0FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sessionCode,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0A2463),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Share this code with participants',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Participants section
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people,
                                        color: Color(0xFF0A2463),
                                        size: 28
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Participants (${participants.length})',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A2463),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: participants.isEmpty
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            Icons.hourglass_empty,
                                            size: 48,
                                            color: Colors.grey
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Waiting for participants...',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : ListView.builder(
                                    itemCount: participants.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Color(0xFF1E5CB3),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          participants[index]['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 30),

                        // Launch button
                        if (participants.isNotEmpty)
                          ElevatedButton(
                            onPressed: questionsCount > 0 ? () => onLaunchQuiz() : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow),
                                SizedBox(width: 8),
                                Text(
                                  'Launch Quiz',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}