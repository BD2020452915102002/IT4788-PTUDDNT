import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';

class HomeScreenStudent extends StatefulWidget {
  const HomeScreenStudent({super.key});

  @override
  State<HomeScreenStudent> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreenStudent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<List<dynamic>> _classListHidden = ValueNotifier([]);
  List<dynamic> _classList = [];
  List<dynamic> _classListShow = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String hoTen = '';
  String userName = '';
  String avatar = '';
  @override
  void initState() {
    super.initState();
    _initializeData();
    setState(() {
      _classList = HiveService().getData('classList') ;
    });
    _classListHidden.addListener(_updateVisibleClasses);
  }
  Future<void> _initializeData() async {
    final classList = HiveService().getData('classList') ?? [];
    if( classList.isEmpty ) {
      await fetchClassList();
    }
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
  String convertToDirectDownloadLink(String driveLink) {
    print('Khang ${driveLink}');
    final regex = RegExp(r'file/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(driveLink);

    if (match != null && match.groupCount > 0) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    } else {
      throw ArgumentError('Invalid Google Drive link format');
    }
  }
  Future<void> fetchClassList() async {
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

      final res = await ApiClass().post('/get_class_list', {
        "token": Token().get(),
        "role": "STUDENT",
        "account_id": accountId,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final classList = data['data'];
        await HiveService().saveData('classList', classList);
        setState(() {
          _isLoading = false;
        });
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
      final classList = HiveService().getData('classList') ?? [];
      if (userData != null) {
        String ho = userData['ho'] ?? '';
        String ten = userData['ten'] ?? '';
        String avatarURL = userData['avatar'] ?? '';
        String userNamekkk = userData['email'] ?? '';

        setState(() {
          _classList = classList;
          hoTen = '$ho $ten';
          avatar = avatarURL;
          userName = userNamekkk;
          _isLoading = false;
        });
        if (classList.isEmpty) {
          setState(() {
            _errorMessage = 'Không có dữ liệu lớp học.';
          });
        }
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
  Future<void> _registerClassAPI (List<String> classIds)async {
    try {
      final res = await ApiClass().post('/register_class', {
        "token": Token().get(),
        "role": HiveService().getData('userData')['role'],
        "class_ids": classIds
      });
      if ( res.statusCode == 200){
        fetchClassList();
        setState(() {
          _classList = HiveService().getData('classList') ;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công')),
        );
      }
    }catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi. Vui lòng thử lại sau.')),
      );
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
  void _registerClass() {
    List<TextEditingController> controllers = [TextEditingController()]; // Danh sách controllers cho TextField
    List<String> classIds = [];  // Mảng để lưu các ID lớp học
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng ký lớp học'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(  // Thêm SingleChildScrollView để cuộn
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hiển thị các trường nhập ID lớp học
                    ...List.generate(controllers.length, (index) {
                      return TextFormField(
                        controller: controllers[index],
                        decoration: InputDecoration(
                          labelText: 'Nhập ID lớp học ${index + 1}',
                        ),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            classIds.add(value);  // Lưu ID lớp học vào mảng
                          }
                        },
                      );
                    }),
                    // Nút để thêm trường nhập ID lớp học mới
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          controllers.add(TextEditingController()); // Thêm controller mới
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Đóng cửa sổ
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                // Lưu các ID lớp học vào mảng khi nhấn OK
                classIds.clear();  // Xóa mảng classIds cũ trước khi thêm mới
                controllers.forEach((controller) {
                  if (controller.text.isNotEmpty) {
                    classIds.add(controller.text);  // Lưu tất cả ID vào mảng
                  }
                });

                if (classIds.isNotEmpty) {
                  _registerClassAPI(classIds);  // Gọi API khi mảng classIds không rỗng
                }
                Navigator.of(context).pop();  // Đóng cửa sổ
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
                  title: const Text( 'Tham gia lớp học'),
                  onTap: _registerClass,
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
                '/class-detail-student',
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
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        backgroundImage:  avatar != ''
                            ? NetworkImage(convertToDirectDownloadLink(avatar))
                            : null,
                        child:  avatar == ''
                            ? const Icon(Icons.person, size: 30)
                            : null,
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
