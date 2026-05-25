import 'dart:convert';
import 'config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Job Search',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        primaryColor: const Color(0xFF2563EB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const JobSearchPage(),
    );
  }
}

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key});

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  final TextEditingController skillsController = TextEditingController();

  bool isLoading = false;
  List<Map<String, dynamic>> jobs = [];
  int currentPage = 1;
  bool hasMore = true;

  String selectedCountry = "us";

  final Map<String, String> countries = {
    "us": "United States",
    "in": "India",
    "uk": "United Kingdom",
    "ca": "Canada",
    "au": "Australia",
    "de": "Germany",
    "sg": "Singapore",
  };

  Future<void> openApplyLink(String url) async {
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  Future<void> searchJobs({bool loadMore = false}) async {
    if (!loadMore) {
      currentPage = 1;
      jobs = [];
      hasMore = true;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/jobs"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "skills": skillsController.text,
          "country": selectedCountry,
          "page": currentPage,
          "limit": 10,
        }),
      );

      print("================================");
      print(response.body);
      print("================================");

      final data = jsonDecode(response.body);

      print(data);
      print("================================");

      final List<Map<String, dynamic>> newJobs =
          List<Map<String, dynamic>>.from(data["jobs"] ?? []);

      setState(() {
        if (loadMore) {
          jobs.addAll(newJobs);
        } else {
          jobs = newJobs;
        }

        hasMore = newJobs.length == 10;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "AI Job Search                                                           - by Ramesh Kandukuri",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ✅ HEADER (FIXED)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // LEFT TEXT
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "VigilantCorp Inc \n\nAI Job Searcher",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Find AI-ranked jobs instantly",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // RIGHT LOGO
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // SKILLS INPUT
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: "Enter Skills",
                  hintText: "Python, FastAPI, SQL",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              // COUNTRY DROPDOWN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<String>(
                  value: selectedCountry,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: countries.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCountry = value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              // SEARCH BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => searchJobs(),
                  child: const Text("Find Jobs"),
                ),
              ),

              const SizedBox(height: 8),

              if (isLoading)
                const CircularProgressIndicator(),

              const SizedBox(height: 10),

              // JOB LIST
              Expanded(
                child: jobs.isEmpty
                    ? const Center(
                        child: Text("No jobs found"),
                      )
                    : ListView.builder(
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          final job = jobs[index];

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job["title"] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(job["company"] ?? ""),
                                  Text(job["location"] ?? ""),

                                  const SizedBox(height: 10),

                                  Text(job["description"] ?? ""),                       

                                  const SizedBox(height: 10),

                                  ElevatedButton(
                                    onPressed: () =>
                                        openApplyLink(job["apply_link"] ?? ""),
                                    child: const Text("  Apply Now  "),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (hasMore && jobs.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    currentPage++;
                    searchJobs(loadMore: true);
                  },
                  child: const Text("Load More"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}