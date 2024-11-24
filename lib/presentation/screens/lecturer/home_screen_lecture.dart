import 'dart:convert';
import 'package:easy_refresh/easy_refresh.dart';
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
  List<dynamic> _classList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String hoTen = '';
  String userName = '';
  String avatar = '';
  int page = 0;
  int pageSize = 1;
  @override
  void initState() {
    super.initState();
    _initializeData();
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
      print('Khang ${Token().get()}');
      final res = await ApiClass().post('/get_class_list', {
        "token": Token().get(),
        "role": "LECTURER",
        "account_id": accountId,
        "pageable_request": {"page": page, "page_size": pageSize}
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
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
  Future<void> loadMoreClassList() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userData = HiveService().getData('userData');
      final accountId = userData?['id']?.toString() ?? '';
      if (accountId.isEmpty) {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin tài khoản.';
        });
        return;
      }
      await HiveService().deleteData('page_info');
      final res = await ApiClass().post('/get_class_list', {
        "token": Token().get(),
        "role": "STUDENT",
        "account_id": accountId,
        "pageable_request": {"page": page, "page_size": pageSize}
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final classData = data['data'];
        await HiveService().addToList('page_content', classData['page_content'] as List<dynamic>);
        await HiveService().saveData('page_info', classData['page_info']);
        setState(() {
          _isLoading = false;
        });
        print('Hive ${HiveService().getData('page_content')}');
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
  Future<void> onRefresh ()async{
    HiveService().deleteData('page_content');
    setState(() {
      page = 0;
    });
    await fetchClassList();
    setState(() {
      _classList = HiveService().getData('page_content');
    });
  }
  Future<void> onLoad ()async{
    final pageInfor =   HiveService().getData('page_info');
    if(pageInfor['next_page'] == null){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã hết lớp học')));
    } else {
      setState(() {
        page ++ ;
      });
      await loadMoreClassList();
      setState(() {
        _classList = HiveService().getData('page_content');
      });
    }
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
          : _classList.isEmpty
          ? Center(child: Text('Bạn chưa có lớp nào'))
          : EasyRefresh(
          onRefresh: onRefresh,
          onLoad: onLoad,
          child: ListView.builder(
            itemCount: _classList.length,
            itemBuilder: (context, index) {
              final classData = _classList[index] as Map<dynamic, dynamic>;
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
          ), ),
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