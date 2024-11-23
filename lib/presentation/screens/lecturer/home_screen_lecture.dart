import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';

class HomeScreenLec extends StatefulWidget {
  const HomeScreenLec({super.key});

  @override
  State<HomeScreenLec> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenLec> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<List<dynamic>> _classListHidden = ValueNotifier([]);
  List<dynamic> _classList = [];
  List<dynamic> _classListShow = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String hoTen = '';
  String userName = '';
  String avatar = '';
  @override
  void initState() {
    super.initState();
    _initializeData();
    _classListHidden.addListener(_updateVisibleClasses);
  }
  Future<void> _initializeData() async {
    final classList = HiveService().getData('page_content');
    if( classList == null ) {
      await fetchClassList();
    }
    setState(() {
      _classList = HiveService().getData('page_content');
      _isLoading = false;
    });
    await _loadUserData();
    _updateVisibleClasses();
  }
  void _updateVisibleClasses() {
    setState(() {
      _classListShow = _classList
          .where((item) => !_classListHidden.value.contains(item))
          .toList();
    });
  }
  Future<void> fetchClassList() async {
    try {
      final userData = HiveService().getData('userData');
      final accountId = userData?['id']?.toString() ?? '';
      if (accountId.isEmpty) {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin tài khoản.';
        });
        return;
      }

      final res = await ApiClass().post('/get_class_list', {
        "token": Token().get(),
        "role": "LECTURER",
        "account_id": accountId,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final classData = data['data'];
        await HiveService().saveData('page_content', classData['page_content'] as List<dynamic>);
        await HiveService().saveData('page_info', classData['page_info']);
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi lấy danh sách lớp học.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = HiveService().getData('userData');
      if (userData != null) {
        String ho = userData['ho'] ?? '';
        String ten = userData['ten'] ?? '';
        String avatarURL = userData['avatar'] ?? '';
        String userNamekkk = userData['name'] ?? '';

        setState(() {
          hoTen = '$ho $ten';
          avatar = avatarURL;
          userName = userNamekkk;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin người dùng.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
        _isLoading = false;
      });
    }
  }

  void _showClassManagementDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quản lý lớp học'),
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
                  title: const Text('Quản lý lớp học'),
                  onTap: _showClassManagementDialog,
                ),
                const SizedBox(height: 40),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Tạo lớp học'),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pushNamed('/create-class-lecturer');
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
      backgroundColor: Colors.white,
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
          final classData = _classListShow[index] as Map<dynamic, dynamic>;
          return GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                    '/class-detail-lecture',
                    arguments: classData
                );
              },
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classData['class_name'],
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Loại lớp: ${classData['class_type']}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Giảng viên: ${classData['lecturer_name']}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thời gian: ${classData['start_date']} - ${classData['end_date']}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )

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
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                    "/information-student",
                    arguments: HiveService().getData('userData')['id'].toString()
                );
              },
            ),
            ListTile(
              title: const Text('Đăng xuất'),
              onTap: (){
                HiveService().clearBox();
                if (!mounted) return;
                // Navigator.pushNamed(context, '/login');
                HiveService().clearBox();
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  "/login",
                      (Route<dynamic> route) => false,
                );

              },
            ),
          ],
        ),
      ),
    );
  }
}