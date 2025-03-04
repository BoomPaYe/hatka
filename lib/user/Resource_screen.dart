import 'package:flutter/material.dart';



class CareerResourceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Learning Resource',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Learning Resource'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'CV and Cover Letter'),
              Tab(text: 'Interview Tips'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CVAndCoverLetterScreen(),
            InterviewTipsScreen(),
          ],
        ),
      ),
    );
  }
}

class CVAndCoverLetterScreen extends StatelessWidget {
  final List<Map<String, String>> topics = [
    {
      'title': 'How to write CV with no experience',
      'content': 'If you have no experience, start with your resume, highlight your education, include relevant non-work experiences, list your skills, and include a summary.\n\nFocus on transferable skills from school projects, volunteer work, or extracurricular activities. Emphasize your education section with relevant coursework, academic achievements, and projects.\n\nInclude any internships, volunteer positions, or part-time jobs, highlighting the skills you developed that could be valuable in your target position.'
    },
    {
      'title': 'What should you include in a CV?',
      'content': 'A standard CV should include:\n\n• Contact information\n• Professional summary or objective statement\n• Work experience (in reverse chronological order)\n• Education\n• Skills relevant to the position\n• Achievements and certifications\n• References (or "References available upon request")\n\nCustomize your CV for each application, highlighting the most relevant experience and skills for the specific job. Keep your CV concise, typically 1-2 pages unless you\'re in a field that requires a more comprehensive CV.'
    },
    {
      'title': 'The way that make your CV stand out',
      'content': 'To make your CV stand out:\n\n• Tailor it specifically to each job application\n• Use a clean, professional design with consistent formatting\n• Quantify your achievements with specific numbers and metrics\n• Include relevant keywords from the job description\n• Highlight your unique selling points and accomplishments\n• Use action verbs to describe your experience\n• Ensure perfect grammar and spelling\n• Include a compelling professional summary\n• Focus on results and impact, not just responsibilities\n\nRemember that recruiters often spend just 6-7 seconds scanning a CV initially, so make your most impressive qualifications easy to spot.'
    },
    {
      'title': 'How to Write an Email Asking for an Internship',
      'content': 'When writing an email to request an internship:\n\n• Use a professional subject line (e.g., "Internship Application - [Your Name] - [Position]")\n• Address the recipient by name when possible\n• Introduce yourself concisely, mentioning your education and career goals\n• Explain why you\'re interested in their company specifically\n• Highlight relevant skills and experience\n• Request an opportunity to discuss internship possibilities\n• Mention your attached resume/CV\n• Thank them for their time and consideration\n• Include your contact information\n• End with a professional sign-off\n\nKeep your email concise (3-4 short paragraphs), proofread carefully, and follow up politely if you don\'t receive a response within 1-2 weeks.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: topics.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            topics[index]['title']!,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  title: topics[index]['title']!,
                  content: topics[index]['content']!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class InterviewTipsScreen extends StatelessWidget {
  final List<Map<String, String>> topics = [
    {
      'title': 'How to face an interview',
      'content': 'Preparing for an interview:\n\n• Research the company thoroughly (mission, values, recent news, products/services)\n• Practice common interview questions for your industry\n• Prepare concise stories using the STAR method (Situation, Task, Action, Result)\n• Dress professionally and appropriately for the company culture\n• Arrive 10-15 minutes early\n• Bring copies of your resume, a notepad, and pen\n• Prepare thoughtful questions to ask the interviewer\n• Practice good body language: firm handshake, eye contact, good posture\n• Follow up with a thank-you email within 24 hours\n\nRemember to be authentic while showcasing your relevant skills and experience. View each interview as a learning opportunity regardless of the outcome.'
    },
    {
      'title': 'How to handle age issues on an internship interview',
      'content': 'When dealing with age-related concerns in internship interviews:\n\n• Focus on your skills and what you can bring to the role rather than your age\n• Highlight your adaptability, willingness to learn, and fresh perspective\n• Emphasize relevant experience, whether from education, prior work, or personal projects\n• Address potential concerns proactively (e.g., if you\'re older, emphasize your transferable skills and commitment)\n• Demonstrate your knowledge of current industry trends and technologies\n• Show enthusiasm and curiosity about the company and role\n• If directly questioned about age in an inappropriate way, politely redirect to your qualifications\n\nRemember that age discrimination is illegal, but you can still prepare to emphasize how your specific background—regardless of age—makes you an excellent candidate.'
    },
    {
      'title': 'How to answer what interests you about this job',
      'content': 'When answering "What interests you about this job?":\n\n• Connect the role to your career goals and personal interests\n• Demonstrate knowledge about the company and its mission\n• Highlight specific aspects of the job description that align with your skills\n• Show enthusiasm for the company\'s products, services, or industry position\n• Explain how your background has prepared you for this specific opportunity\n• Mention aspects of the company culture that appeal to you\n• Be authentic about what genuinely excites you\n\nThis question assesses your research, enthusiasm, and fit with the company. Prepare a thoughtful, specific answer that shows you\'ve done your homework and have genuine interest in the role, not just any job.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: topics.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            topics[index]['title']!,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  title: topics[index]['title']!,
                  content: topics[index]['content']!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String title;
  final String content;

  DetailScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}