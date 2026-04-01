import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMealMenuPage extends StatefulWidget {
  final String pgId;

  const AdminMealMenuPage({Key? key, required this.pgId}) : super(key: key);

  @override
  _AdminMealMenuPageState createState() => _AdminMealMenuPageState();
}

class _AdminMealMenuPageState extends State<AdminMealMenuPage> {
  final List<String> weekDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  Map<String, Map<String, String>> mealMenu = {};
  bool isEditing = false;
  bool isLoading = true;

  Future<void> _fetchMealMenu() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('mealmenu')
          .doc(widget.pgId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          mealMenu = data.map((key, value) => MapEntry(
              key,
              (value as Map<String, dynamic>)
                  .map((k, v) => MapEntry(k, v.toString()))));
          isEditing = false;
        });
      } else {
        setState(() {
          mealMenu = {
            for (var day in weekDays)
              day: {"Breakfast": "", "Lunch": "", "Dinner": ""}
          };
          isEditing = true;
        });
      }
    } catch (e) {
      print('Error fetching meal menu: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveMealMenu() async {
    try {
      final updatedMenu = mealMenu.map(
          (key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v))));

      await FirebaseFirestore.instance
          .collection('mealmenu')
          .doc(widget.pgId)
          .set(updatedMenu);

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal menu updated successfully!')),
      );
    } catch (e) {
      print('Error saving meal menu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving meal menu: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMealMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: const Text('Weekly Meal Menu'),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMealMenu,
            ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: weekDays.map((day) {
                  final meals = mealMenu[day] ??
                      {"Breakfast": "", "Lunch": "", "Dinner": ""};

                  return Card(
                    color: Colors.grey[200],
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...["Breakfast", "Lunch", "Dinner"].map((mealType) {
                            return isEditing
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: TextFormField(
                                      initialValue: meals[mealType] ?? "",
                                      decoration: InputDecoration(
                                        labelText: mealType,
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          mealMenu[day]![mealType] = value;
                                        });
                                      },
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$mealType: ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            meals[mealType] ?? "Not Available",
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
