import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScheduleParser(),
    );
  }
}

class ScheduleParser extends StatefulWidget {
  @override
  _ScheduleParserState createState() => _ScheduleParserState();
}

class _ScheduleParserState extends State<ScheduleParser> {
  String selectedGroup = 'ПИ21-1';
  DateTime selectedDate = DateTime.now();
  DateTime selectedDay = DateTime.now();
  List<Map<String, dynamic>> schedule = [];
  bool isLoading = false;

  // Список групп и их ID для использования в API
  final List<Map<String, String>> groups = [
    {'name': 'ПИ21-1', 'id': '137226'},
    {'name': 'ПИ21-2', 'id': '137267'},
    {'name': 'ПИ21-3', 'id': '137269'},
    {'name': 'ПИ21-4', 'id': '137270'},
    {'name': 'ПИ21-5', 'id': '137271'},
    {'name': 'ПИ21-6', 'id': '137272'},
    {'name': 'ПИ21-7', 'id': '137273'},
  ];

  Future<void> fetchSchedule() async {
    setState(() {
      isLoading = true;
    });


    String? groupId = groups.firstWhere((group) => group['name'] == selectedGroup)['id'];

    try {
      String startDateFormatted = DateFormat('yyyy.MM.dd').format(selectedDate);
      String endDateFormatted = DateFormat('yyyy.MM.dd').format(selectedDate.add(Duration(days: 6)));

      String url =
          'https://ruz.fa.ru/api/schedule/group/$groupId?start=$startDateFormatted&finish=$endDateFormatted&lng=1';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        List<Map<String, dynamic>> parsedSchedule = (data as List).map((lesson) {
          String subject = lesson['discipline'] ?? '';
          String kind = lesson['kindOfWork'] ?? 'Нет данных';
          String teacher = lesson['lecturer'] ?? 'Нет данных';
          String auditorium = lesson['auditorium'] ?? 'Нет данных';
          String building = lesson['building'] ?? 'Не указано';
          String beginLesson = lesson['beginLesson'] ?? 'Не указано';
          String endLesson = lesson['endLesson'] ?? 'Не указано';
          String dateRaw = lesson['date'] ?? 'Не указано';
          String dayOfWeek = lesson['dayOfWeekString'] ?? 'Не указано';
          String formattedDate = 'Не указано';
          try {
            DateTime dateTime = DateFormat('yyyy.MM.dd').parse(dateRaw);
            formattedDate = DateFormat('dd.MM.yy').format(dateTime);
          } catch (e) {
            print('Ошибка при преобразовании даты: $e');
          }

          String dateInfo = '$formattedDate $dayOfWeek';
          String timeInfo = '$beginLesson - $endLesson';
          String auditoriumInfo = '$auditorium ($building)';
          Color borderColor;
          Color dateTimeBackgroundColor;
          Widget? kindWidget;
          if (kind == 'Лекции') {
            borderColor = Colors.green;
            dateTimeBackgroundColor = Colors.green[100]!;
            kindWidget = Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.green,
                ),
                SizedBox(width: 5),
                Text(
                  'Лекция',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          } else if (kind == 'Практические (семинарские) занятия') {
            borderColor = Colors.orange;
            dateTimeBackgroundColor = Colors.orange[100]!;
            kindWidget = Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.orange,
                ),
                SizedBox(width: 5),
                Text(
                  'Семинар',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          } else {
            borderColor = Colors.black54;
            dateTimeBackgroundColor = Colors.black26;
            kindWidget = null;
          }

          return {
            'dateInfo': dateInfo,
            'timeInfo': timeInfo,
            'subject': subject,
            'kind': kind,
            'teacher': teacher,
            'auditorium': auditoriumInfo,
            'borderColor': borderColor,
            'dateTimeBackgroundColor': dateTimeBackgroundColor,
            'kindWidget': kindWidget,
            'lessonDate': formattedDate,
            'beginTime': beginLesson,
          };
        }).toList();

        setState(() {
          schedule = parsedSchedule;
          schedule.sort((a, b) {
            DateTime aTime = DateFormat('HH:mm').parse(a['beginTime']);
            DateTime bTime = DateFormat('HH:mm').parse(b['beginTime']);
            return aTime.compareTo(bTime);
          });
        });
      } else {
        print('Ошибка загрузки данных: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDay = selectedDate;
    fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Image.network(
                  'https://ruz.fa.ru/ruz/assets/img/logo.png?v=1.16.9',
                  width: 100,
                  height: 100,
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Расписание ПИ21',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFE3F2FD),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      String? newValue = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Выберите группу'),
                            content: Container(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: groups.map((group) {
                                  return ListTile(
                                    title: Text(group['name'] ?? 'Не указано'),
                                    onTap: () {
                                      Navigator.pop(context, group['name']);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      );

                      if (newValue != null && newValue != selectedGroup) {
                        setState(() {
                          selectedGroup = newValue;
                          fetchSchedule();
                        });
                      }
                    },
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(color: Colors.blueGrey, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedGroup,
                            style: TextStyle(fontSize: 16),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Выбор даты
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2025),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                        selectedDay = picked;
                        fetchSchedule();
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: Colors.blueGrey, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.black,
                        ),
                        SizedBox(width: 10),
                        Text(
                          DateFormat('dd.MM.yy').format(selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  DateTime day = selectedDate.add(Duration(days: index));
                  String dayName = DateFormat.E('ru_RU').format(day).toUpperCase(); // Дни недели на русском в верхнем регистре
                  String dayNumber = DateFormat('d').format(day);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 7.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: day.isAtSameMomentAs(selectedDay) ? Colors.grey[600]! : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNumber,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: day.isAtSameMomentAs(selectedDay) ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: day.isAtSameMomentAs(selectedDay) ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: schedule.where((lesson) => lesson['lessonDate'] == DateFormat('dd.MM.yy').format(selectedDay)).isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Отдыхай!',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    Text(
                      'Сегодня пар нет :)',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: schedule.length,
                itemBuilder: (context, index) {
                  final lesson = schedule[index];
                  if (lesson['lessonDate'] != DateFormat('dd.MM.yy').format(selectedDay)) {
                    return SizedBox.shrink();
                  }

                  final Color borderColor = lesson['borderColor'] ?? Colors.grey;
                  final Color dateTimeBackgroundColor =
                      lesson['dateTimeBackgroundColor'] ?? Colors.grey[200]!;
                  final Widget? kindWidget = lesson['kindWidget'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(
                        color: borderColor,
                        width: 2.0,
                      ),
                    ),
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              color: dateTimeBackgroundColor,
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lesson['dateInfo'] ?? 'Нет данных',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        lesson['timeInfo'] ?? 'Нет данных',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              lesson['subject'] ?? 'Нет данных',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            if (kindWidget != null) kindWidget,
                            SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    lesson['auditorium'] ?? 'Нет данных',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    lesson['teacher'] ?? 'Нет данных',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
