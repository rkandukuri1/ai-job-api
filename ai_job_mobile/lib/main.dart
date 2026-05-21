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
        primarySwatch: Colors.blue,
      ),

      home: const JobSearchPage(),
    );
  }
}

class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key});

  @override
  State<JobSearchPage> createState() =>
      _JobSearchPageState();
}

class _JobSearchPageState
    extends State<JobSearchPage> {

  final TextEditingController skillsController =
      TextEditingController();

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

  // -----------------------------------
  // OPEN APPLY LINK
  // -----------------------------------
  Future<void> openApplyLink(
    String url,
  ) async {

    if (url.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "No apply link available",
          ),
        ),
      );

      return;
    }

    final Uri uri = Uri.parse(url);

    try {

      await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Could not open link",
          ),
        ),
      );
    }
  }

  // -----------------------------------
  // SEARCH JOBS
  // -----------------------------------
  Future<void> searchJobs({
    bool loadMore = false,
  }) async {

    if (!loadMore) {

      currentPage = 1;

      setState(() {

        jobs = [];

        hasMore = true;
      });
    }

    setState(() {
      isLoading = true;
    });

    try {

      final response = await http.post(

         Uri.parse(
              "${AppConfig.apiBaseUrl}/jobs",
            ),
        headers: {
          "Content-Type":
              "application/json"
        },

        body: jsonEncode({

          "skills":
              skillsController.text,

          "country":
              selectedCountry,

          "page":
              currentPage,

          "limit": 10
        }),
      );

      print(response.body);

      final data =
          jsonDecode(response.body);

      final List<
          Map<String, dynamic>> newJobs =

          List<Map<String, dynamic>>
              .from(
        data["jobs"] ?? [],
      );

      print(
        "TOTAL JOBS: ${newJobs.length}",
      );

      setState(() {

        if (loadMore) {

          jobs.addAll(newJobs);

        } else {

          jobs = newJobs;
        }

        hasMore =
            newJobs.length == 10;
      });

    } catch (e) {

      print("ERROR: $e");

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
              Text("Error: $e"),
        ),
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  // -----------------------------------
  // SCORE COLOR
  // -----------------------------------
  Color scoreColor(int score) {

    if (score >= 80) {
      return Colors.green;
    }

    if (score >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text("AI Job Search"),
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          children: [

            // -----------------------
            // SKILLS INPUT
            // -----------------------
            TextField(

              controller:
                  skillsController,

              decoration:
                  const InputDecoration(

                labelText:
                    "Enter Skills",

                hintText:
                    "Python, FastAPI, SQL",

                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // -----------------------
            // COUNTRY DROPDOWN
            // -----------------------
            Container(

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),

              decoration: BoxDecoration(

                border: Border.all(
                  color: Colors.grey,
                ),

                borderRadius:
                    BorderRadius.circular(4),
              ),

              child:
                  DropdownButton<String>(

                value:
                    selectedCountry,

                isExpanded: true,

                underline:
                    const SizedBox(),

                items:
                    countries.entries.map(
                  (entry) {

                    return DropdownMenuItem<
                        String>(

                      value: entry.key,

                      child:
                          Text(entry.value),
                    );
                  },
                ).toList(),

                onChanged: (value) {

                  if (value != null) {

                    setState(() {

                      selectedCountry =
                          value;
                    });
                  }
                },
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // -----------------------
            // FIND JOBS BUTTON
            // -----------------------
            SizedBox(

              width:
                  double.infinity,

              child:
                  ElevatedButton(

                onPressed:
                    isLoading
                        ? null
                        : () async {

                            await searchJobs();
                          },

                child: const Text(
                  "Find Jobs",
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // -----------------------
            // LOADING
            // -----------------------
            if (isLoading)

              const Padding(

                padding:
                    EdgeInsets.all(10),

                child:
                    CircularProgressIndicator(),
              ),

            const SizedBox(
              height: 10,
            ),

            // -----------------------
            // JOB LIST
            // -----------------------
            Expanded(

              child: jobs.isEmpty

                  ? const Center(
                      child: Text(
                        "No jobs found",
                      ),
                    )

                  : ListView.builder(

                      itemCount:
                          jobs.length,

                      itemBuilder:
                          (context, index) {

                        final job =
                            jobs[index];

                        return Card(

                          elevation: 4,

                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),

                          child: Padding(

                            padding:
                                const EdgeInsets.all(
                              16,
                            ),

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Text(

                                  job["title"] ??
                                      "",

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(

                                  job["company"] ??
                                      "",

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        16,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  job["location"] ??
                                      "",
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                Container(

                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal:
                                        12,

                                    vertical:
                                        6,
                                  ),

                                  decoration:
                                      BoxDecoration(

                                    color:
                                        scoreColor(
                                      job["score"] ??
                                          0,
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),

                                  child: Text(

                                    "Match Score: ${job["score"]}",

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,

                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                Text(
                                  job["why_match"] ??
                                      "",
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                SizedBox(

                                  width:
                                      double.infinity,

                                  child:
                                      ElevatedButton.icon(

                                    onPressed:
                                        () {

                                      openApplyLink(
                                        job["apply_link"] ??
                                            "",
                                      );
                                    },

                                    icon:
                                        const Icon(
                                      Icons
                                          .open_in_new,
                                    ),

                                    label:
                                        const Text(
                                      "Apply Now",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // -----------------------
            // LOAD MORE
            // -----------------------
            if (hasMore &&
                jobs.isNotEmpty)

              SizedBox(

                width:
                    double.infinity,

                child:
                    ElevatedButton(

                  onPressed:
                      () async {

                    setState(() {

                      currentPage++;
                    });

                    await searchJobs(
                      loadMore: true,
                    );
                  },

                  child: const Text(
                    "Load More Jobs",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}