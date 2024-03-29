// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:chokchey_finance/components/maxWidthWrapper.dart';
import 'package:chokchey_finance/components/searchCO.dart';
import 'package:chokchey_finance/localizations/appLocalizations.dart';
import 'package:chokchey_finance/providers/approvalHistory/index.dart';
import 'package:chokchey_finance/providers/loanArrearProvider/loanArrearProvider.dart';
import 'package:chokchey_finance/screens/loanArrear/detail.dart';
import 'package:chokchey_finance/screens/loanArrear/widgetView.dart';
import 'package:chokchey_finance/utils/storages/colors.dart';
import 'package:chokchey_finance/utils/storages/const.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../../app/module/loan_arrear/controllers/loan_arrear_controller.dart';
import '../../app/utils/helpers/custom_drop_down.dart';
import '../../app/utils/helpers/dropdow_item.dart';
import '../../app/utils/helpers/format_convert.dart';
import '../../providers/manageService.dart';
import 'package:http/http.dart' as http;

import '../../app/module/home_new/screen/new_homescreen.dart';

class LoanArrearScreen extends StatefulWidget {
  const LoanArrearScreen({Key? key}) : super(key: key);

  @override
  _LoanArrearScreenState createState() => _LoanArrearScreenState();
}

class _LoanArrearScreenState extends State<LoanArrearScreen> {
  @override
  void initState() {
    if (mounted) {
      fetchLoanArrear();
      getListBranches();
    }

    searchAllCO('');
    super.initState();
  }

  final con = Get.put(LoanArrearController());

  var listBranch = [];
  var selected = [];
  var listHistory;
  String? selectedStatus;
  String? selectedBranch;
  String? startDateTime = "";
  String? endDateTime = "";
  String coName = "";
  String bcode = "";
  dynamic listLoanArrear = [];
  bool _isLoading = false;
  dynamic overviewmonth = 0.0;
  dynamic currencyUSD = 0.0;
  dynamic currencyKhmer = 0.0;
  var format = NumberFormat.simpleCurrency(name: 'KHM');

  var laonAccountNo;
  Future fetchLoanArrear() async {
    // branch
    String? branch = await storage.read(key: 'branch');
    String? level = await storage.read(key: 'level');
    String? user_ucode = await storage.read(key: 'user_ucode');
    setState(() {
      _isLoading = true;
    });
    var datetime = DateTime.now();
    String getDateTimeNow = DateFormat("yyyyMMdd").format(datetime);

    String mgmtBranchCode = "";
    String referenEmployeeNo = "";

    if (branch != "0100") {
      mgmtBranchCode = branch!;
    }

    if (level == '3') {
      mgmtBranchCode = branch!;
    }
    if (level == '1') {
      mgmtBranchCode = branch!;
      referenEmployeeNo = user_ucode!;
    }

    if (bcode != "") {
      mgmtBranchCode = bcode;
    }

    if (selectedEmployeeID != "") {
      referenEmployeeNo = selectedEmployeeID;
    }

    await Provider.of<LoanArrearProvider>(context, listen: false)
        .fetchLoanArrearProvider(
      baseDate: getDateTimeNow,
      currencyCode: "",
      loanAccountNo: "",
      mgmtBranchCode: mgmtBranchCode,
      referenceEmployeeNo: referenEmployeeNo,
    )
        .then((value) {
      debugPrint('loan arrear======${value.length}');
      value.map((e) {
        laonAccountNo = e['totalAmount1'];
        value['overdueInterest'];
        // debugPrint('heiiiii:$resJson');
      }).toList();

      // sqliteHelper!.insertData(
      //       sql:
      //           'INSERT INTO LaonArrear (loanAccNo, customerNo, customerName, phoneNo, overDueDays, totalRepayment, coName, coId) VALUES ("${listLoanArrear[index]['totalAmount1']}","${list['customerNo']}","${list['customerName']}","${list['cellPhoneNo']}","${list['overdueDays']}","${list['totalAmount1']}","${list['employeeName']}","${list['refereneceEmployeeNo']}")');
      if (value.length > 0) {
        var totalAcount = {"totalAcount": "${value.length}"};
        value.forEach((dynamic e) {
          if (e['currencyCode'] == "USD") {
            currencyUSD += e['totalAmount1'];
          } else {
            currencyKhmer += e['totalAmount1'];
          }
        });

        setState(() {
          value = [totalAcount, ...value];
          listLoanArrear = value;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          listLoanArrear = [];
        });
      }
    }).catchError((onError) {
      setState(() {
        _isLoading = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  _onClickListBranch(v) {
    setState(() {
      bcode = v['bcode'];
    });
  }

  Future getListBranches() async {
    await ApprovalHistoryProvider()
        .getListBranch()
        .then((value) => {
              setState(() {
                listBranch = value;
              }),
            })
        .catchError(
      (onError) {
        return onError;
      },
    );
  }

  Future<bool> _onBackPressed() async {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => NewHomeScreen()
            // Home()
            ),
        ModalRoute.withName("/Home"));
    return false;
  }

  List<ArbitrarySuggestionType> suggestions = [];
  TextEditingController searchByCOController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  GlobalKey<FormState> keySearchController = GlobalKey();
  GlobalKey<FormState> keySearchCo = GlobalKey();

  onFilter() async {
    fetchLoanArrear();
    Navigator.pop(context);
  }

  // onFilterByCO() async {
  //   fetchLoanArrear();
  //   (String? searchusername) =>
  //       searchAllCO(searchusername) as Future<List<UserModel>>;
  // }

  dynamic listCO = [];
  Future<List<UserModel>?> searchAllCO(searchusername) async {
    setState(() {
      _isLoading = true;
    });
    try {
      var headers = {'Content-Type': 'application/json'};
      var request =
          http.Request('POST', Uri.parse(baseURLInternal + 'Users/search'));
      request.body = json.encode(
        {"pageSize": 20, "pageNumber": 1, "searchusername": "$searchusername"},
      );
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        var parsed = jsonDecode(await response.stream.bytesToString());
        setState(() {
          //  _isLoading = false;
          listCO = parsed;
        });
        return UserModel.fromJsonList(parsed);
      } else {
        setState(() {
          _isLoading = false;
        });
        // print(response.reasonPhrase);
      }
    } catch (Error) {
      setState(() {
        _isLoading = false;
      });
      logger().e(Error);
    }
    return null;
  }

  String selectedEmployeeID = "";
  double fontSizeText = 21;

  TextEditingController searchControllerTextFormField = TextEditingController();
  GlobalKey<FormState> searchTextFormFieldKey = GlobalKey<FormState>();
  // final _userEditTextController = TextEditingController();
  bool leaveTypeIdColor = false;

  Widget _customPopupItemBuilderExample(
      BuildContext context, UserModel? item, bool isSelected) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: !isSelected
          ? null
          : BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(3),
              color: Colors.white,
            ),
      child: ListTile(
        selected: isSelected,
        title: Text(item!.name),
        subtitle: Text(item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: CupertinoScaffold(
        body: Builder(builder: (context) {
          return Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                AppLocalizations.of(context)!.translate('loan_arrear') ??
                    'Loan Arrear',
              ),
              backgroundColor: logolightGreen,
              leading: new IconButton(
                icon: new Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                  ),
                ),
              ],
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: logolightGreen,
                    ),
                  )
                : listLoanArrear.length < 0
                    ? Center(
                        child: Text(
                          "No Data",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: listLoanArrear.length,
                        itemBuilder: (context, index) {
                          dynamic sumItem = listLoanArrear[index];
                          if (index == 0) {
                            return Column(
                              children: [
                                Padding(padding: EdgeInsets.only(top: 10)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        // margin: EdgeInsets.only(top: 20),
                                        margin: EdgeInsets.all(10),
                                        child: Card(
                                          elevation: 5,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    EdgeInsets.only(top: 10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text("Total Account",
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                      ],
                                                    ),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons.numbers,
                                                            size: 20,
                                                            color: Colors.red),
                                                        Text(
                                                            "${sumItem['totalAcount']}",
                                                            style: TextStyle(
                                                                fontSize:
                                                                    fontSizeText,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .red)),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  //total overview amount loan arrears by USD
                                                  Container(
                                                    padding: EdgeInsets.all(10),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text("Overdue USD",
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                        SizedBox(
                                                          height: 2,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .attach_money,
                                                                size: 25,
                                                                color:
                                                                    Colors.red),
                                                            Text(
                                                                // "${currencyUSD.toStringAsFixed(2)}",
                                                                "${FormatConvert.formatCurrency(currencyUSD)}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        fontSizeText,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .red)),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  //total overview amount loan arrears by Khmer
                                                  Container(
                                                    padding: EdgeInsets.all(10),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text("Overdue KHM",
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                        SizedBox(
                                                          height: 2,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Image.asset(
                                                                "assets/images/khm.png",
                                                                width: 18,
                                                                color:
                                                                    Colors.red),
                                                            Text(
                                                              // "${currencyKhmer.toStringAsFixed(1)}",
                                                              "${FormatConvert.formatCurrency(currencyKhmer)}",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      fontSizeText,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .red),
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            );
                          } else {
                            return Container(
                              margin: EdgeInsets.all(10),
                              child: Card(
                                elevation: 5,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailLoanArrear(
                                          loanAccountNo: listLoanArrear[index]
                                                  ['loanAccountNo']
                                              .toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.only(top: 10)),
                                      WidgetViewTextLoanArrear(
                                          title: 'Loan Account No : ',
                                          // value: listLoanArrear[index]['loanAccountNo']
                                          //     .substring(3)),
                                          value: sumItem['totalAmount1']
                                              .toString()),
                                      WidgetViewTextLoanArrear(
                                          title: 'Customer No : ',
                                          value: listLoanArrear[index]
                                                  ['customerNo']
                                              .substring(5)),
                                      WidgetViewTextLoanArrear(
                                          title: "Customer Name : ",
                                          value: listLoanArrear[index]
                                              ['customerName']),
                                      WidgetViewTextLoanArrear(
                                          title: "Phone No : ",
                                          value: listLoanArrear[index]
                                              ['cellPhoneNo']),
                                      WidgetViewTextLoanArrear(
                                          title: "Over Due Days : ",
                                          value: listLoanArrear[index]
                                                  ['overdueDays']
                                              .toString()),
                                      WidgetViewTextLoanArrear(
                                          title: "Total Repayment : ",
                                          value: listLoanArrear[index]
                                                  ['totalAmount1']
                                              .toString()),
                                      WidgetViewTextLoanArrear(
                                          title: "CO Name : ",
                                          value: listLoanArrear[index]
                                                  ['employeeName']
                                              .toString()),
                                      WidgetViewTextLoanArrear(
                                          title: "CO ID : ",
                                          value: listLoanArrear[index]
                                                  ['refereneceEmployeeNo']
                                              .toString()),
                                      Padding(
                                          padding: EdgeInsets.only(bottom: 10))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
            endDrawer: Drawer(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(padding: EdgeInsets.only(top: 40)),
                      Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort,
                              color: logolightGreen,
                            ),
                            Padding(
                                padding: EdgeInsets.only(right: 5, left: 5)),
                            Text(
                              "Filter",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: logolightGreen),
                            )
                          ],
                        ),
                      ),
                      Padding(padding: EdgeInsets.only(top: 10)),
                      Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: logolightGreen,
                            ),
                            Container(
                              alignment: Alignment.topLeft,
                              padding: EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                "Search by CO",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(padding: EdgeInsets.only(top: 10)),
                      Container(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Obx(
                          () => CustomDropDown(
                            isSearchButton: false,
                            label: 'Branch Name',
                            item: con.branceList.asMap().entries.map((e) {
                              return DropDownItem(
                                itemList: {
                                  "Name": "${e.value.bname}",
                                  "title": e.value.bcode,
                                },
                              );
                            }).toList(),
                            onChange: (e) {
                              con.txtBranceName.value = e['Name'];
                              con.txtBranceCopy.value = e['title'];
                              debugPrint('lll:${con.txtBranceCopy.value}');
                            },
                            defaultValue: con.txtBranceName.value != ''
                                ? {
                                    "Name": con.txtBranceName.value,
                                    // "title": con.userModel.value.uid,
                                  }
                                : null,
                            onChangeSearch: (a) {
                              debugPrint(a);
                              setState(() {
                                con.searchAllCO(a);
                              });
                            },
                          ),
                        ),
                        // DropdownSearch<UserModel>(
                        //   asyncItems: (String? searchusername) =>
                        //       searchAllCO(searchusername)
                        //           as Future<List<UserModel>>,
                        //   popupProps: PopupPropsMultiSelection.modalBottomSheet(
                        //     showSearchBox: true,
                        //     constraints: BoxConstraints(maxHeight: 700),
                        //     modalBottomSheetProps:
                        //         ModalBottomSheetProps(useSafeArea: false),
                        //     itemBuilder: _customPopupItemBuilderExample,
                        //     searchFieldProps: TextFieldProps(
                        //       controller: _userEditTextController,
                        //       decoration: InputDecoration(
                        //         filled: true,
                        //         fillColor: Colors.white,
                        //         focusedBorder: OutlineInputBorder(
                        //           borderSide: BorderSide(
                        //             color: leaveTypeIdColor == true
                        //                 ? Colors.red
                        //                 : logolightGreen,
                        //           ),
                        //           borderRadius: BorderRadius.circular(1),
                        //         ),
                        //         enabledBorder: OutlineInputBorder(
                        //             borderSide: BorderSide(
                        //               color: leaveTypeIdColor == true
                        //                   ? Colors.red
                        //                   : logolightGreen,
                        //             ),
                        //             borderRadius: BorderRadius.circular(5)),
                        //         hintText: "Search Employee Name *",
                        //         hintStyle:
                        //             TextStyle(color: Colors.black, fontSize: 14),
                        //         labelStyle:
                        //             TextStyle(color: Colors.black, fontSize: 14),
                        //         border: OutlineInputBorder(
                        //           borderRadius: BorderRadius.circular(1),
                        //           borderSide: BorderSide(),
                        //         ),
                        //         prefixIcon: Icon(
                        //           Icons.search,
                        //           color: logolightGreen,
                        //         ),
                        //       ),
                        //     ),
                        //   ),

                        //   // mode: Mode.BOTTOM_SHEET,
                        //   // maxHeight: 700,
                        //   // isFilteredOnline: true,
                        //   // showClearButton: true,
                        //   // showSelectedItems: true,
                        //   compareFn: (item, selectedItem) => listCO == listCO,
                        //   // showSearchBox: true,
                        //   dropdownDecoratorProps: DropDownDecoratorProps(
                        //     dropdownSearchDecoration: InputDecoration(
                        //       // filled: true,
                        //       fillColor: Colors.white,
                        //       focusedBorder: OutlineInputBorder(
                        //         borderSide: BorderSide(
                        //           color: leaveTypeIdColor == true
                        //               ? Colors.red
                        //               : logolightGreen,
                        //         ),
                        //         borderRadius: BorderRadius.circular(5),
                        //       ),
                        //       enabledBorder: OutlineInputBorder(
                        //           borderSide: BorderSide(
                        //             color: leaveTypeIdColor == true
                        //                 ? Colors.red
                        //                 : logolightGreen,
                        //           ),
                        //           borderRadius: BorderRadius.circular(5)),
                        //       hintText: "Employee Name *",
                        //       hintStyle:
                        //           TextStyle(color: Colors.black, fontSize: 14),
                        //       labelStyle:
                        //           TextStyle(color: Colors.black, fontSize: 14),
                        //       border: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(5),
                        //         borderSide: BorderSide(),
                        //       ),
                        //     ),
                        //   ),

                        //   autoValidateMode: AutovalidateMode.onUserInteraction,
                        //   validator: (u) =>
                        //       u == null ? "User field is required" : null,

                        //   onChanged: (data) {
                        //     if (data == null) {
                        //     } else {
                        //       setState(() {
                        //         selectedEmployeeID = data.id;
                        //       });
                        //     }
                        //   },
                        //   onSaved: (e) {
                        //     if (e == null) {
                        //     } else {
                        //       setState(() {
                        //         selectedEmployeeID = listCO;
                        //       });
                        //     }
                        //   },

                        //   // popupSafeArea:
                        //   //     PopupSafeAreaProps(top: true, bottom: true),
                        //   // scrollbarProps: ScrollbarProps(
                        //   //   isAlwaysShown: true,
                        //   //   thickness: 7,
                        //   // ),
                        // ),
                      ),

                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                                margin:
                                    EdgeInsets.only(left: 10.0, right: 15.0),
                                child: Divider(
                                  color: Colors.black,
                                  height: 50,
                                )),
                          ),
                          Text(
                            "OR",
                            style: TextStyle(color: logolightGreen),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 15.0, right: 10.0),
                              child: Divider(
                                color: Colors.black,
                                height: 50,
                              ),
                            ),
                          ),
                        ],
                      ),

                      //Search by filter
                      // Padding(padding: EdgeInsets.only(top: 10)),
                      Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu,
                              color: logolightGreen,
                            ),
                            Container(
                              alignment: Alignment.topLeft,
                              padding: EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                "List Branch",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 500,
                        child: ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: listBranch.length,
                          padding: EdgeInsets.only(top: 15.0),
                          itemBuilder: (context, index) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                      color: logolightGreen, width: 1)),
                              child: InkWell(
                                onTap: () =>
                                    _onClickListBranch(listBranch[index]),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      '${listBranch[index]['bname']}',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color:
                                            bcode == listBranch[index]['bcode']
                                                ? logolightGreen
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            width: 120,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: logoDarkBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: () {
                                bcode = "";
                                selectedEmployeeID = "";
                                fetchLoanArrear();
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Clear",
                                style: TextStyle(fontSize: 17),
                              ),
                            ),
                          ),
                          Container(
                            width: 120,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: logolightGreen,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: () {
                                onFilter();
                                // onFilterByCO();
                              },
                              child: Text(
                                "Apply",
                                style: TextStyle(fontSize: 17),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
