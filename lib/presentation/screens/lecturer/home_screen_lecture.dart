import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreenLec extends StatefulWidget {
  const HomeScreenLec({super.key});

  @override
  State<HomeScreenLec> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenLec> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Khai báo key
  List<dynamic> _classList = [];
  final ValueNotifier<List<dynamic>> _classListHidden = ValueNotifier([]);
  List<dynamic> _classListShow = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String hoTen = '';
  String userName = '';
  late String avata;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _classListHidden.addListener(() {
      _updateVisibleClasses();
    });
  }

  void _updateVisibleClasses() {
    setState(() {
      _classListShow = _classList
          .where((item) => !_classListHidden.value.contains(item))
          .toList();
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');

    if (!mounted) return;
    Navigator.pushNamed(context, '/login');
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userDataString = prefs.getString('userData');

      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        List<dynamic> classList = userData['class_list'] ?? [];
        String ho = userData['ho'] ?? '';
        String ten = userData['ten'] ?? '';
        String avatarURL = userData['avatar'] ?? '';
        String userNamekkk = userData['user_name'] ?? '';

        setState(() {
          _classList = classList;
          _isLoading = false;
          hoTen = '$ho $ten';
          avata = avatarURL;
          userName = userNamekkk;
        });
        _updateVisibleClasses();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không có dữ liệu lớp học';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi: $e';
      });
    }
  }

  void _showClassManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quản lý lớp giảng dạy'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: _classList.isNotEmpty ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: _classList.length,
                  itemBuilder: (context, index) {
                    final classData = _classList[index];
                    final isHidden = _classListHidden.value.any(
                        (item) => item['class_id'] == classData['class_id']);

                    return CheckboxListTile(
                      title: Text(classData['class_name']),
                      value: !isHidden,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _classListHidden.value =
                                List.from(_classListHidden.value)
                                  ..remove(classData);
                          } else {
                            _classListHidden.value =
                                List.from(_classListHidden.value)
                                  ..add(classData);
                          }
                        });
                      },
                    );
                  },
                ): const Text('Oh no!')
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                _updateVisibleClasses();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Center(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Quản lý lớp giảng dạy'),
                  onTap: _showClassManagementDialog,
                ),
                const SizedBox(height: 40),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Tạo lớp học mới'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState
                ?.openDrawer(); // Mở Drawer khi nhấn vào menu
          },
        ),
        centerTitle: true,
        title: const Text(
          'Danh sách lớp',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showMoreOptions,
          ),
        ],
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
        itemCount: _classListShow.length,
        itemBuilder: (context, index) {
          final classData = _classListShow[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/class-detail',
                arguments: classData,
              );
            },
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData['class_name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loại lớp: ${classData['class_type']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giảng viên: ${classData['lecturer_name']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thời gian: ${classData['start_date']} - ${classData['end_date']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                accountEmail: const Text(''),
                // keep blank text because email is required
                accountName: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                    ),
                     Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(hoTen, style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        ),),
                        Text(userName),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text('Thông tin cá nhân'),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Đăng xuất'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
