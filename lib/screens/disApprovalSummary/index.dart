// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:chokchey_finance/components/header.dart';
import 'package:chokchey_finance/components/maxWidthWrapper.dart';
import 'package:chokchey_finance/localizations/appLocalizations.dart';
import 'package:chokchey_finance/providers/approvalHistory/index.dart';
import 'package:chokchey_finance/providers/approvalSummary/index.dart';
import 'package:chokchey_finance/providers/manageService.dart';
import 'package:chokchey_finance/utils/storages/colors.dart';
import 'package:chokchey_finance/utils/storages/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/module/home_new/screen/new_homescreen.dart';
import 'detailLoadRegistration.dart';

class DisApprovalSummary extends StatefulWidget {
  @override
  _DisApprovalSummaryState createState() => _DisApprovalSummaryState();
}

class _DisApprovalSummaryState extends State<DisApprovalSummary> {
  var isLoading = false;
  var listTotal;
  var listApproval;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      getReportApprovalSummary(
          _pageSize, _pageNumber, '', '', '', '', '', 'Disapprove');
      getListBranches();
      getListCO('');
    }
  }

  Future getReportApprovalSummary(_pageSize, _pageNumber, status, code, bcode,
      sdate, edate, statusRequest) async {
    setState(() {
      isLoading = true;
    });
    await ApprovalSummaryProvider()
        .getApprovalSummary(_pageSize, _pageNumber, status, code, bcode, sdate,
            edate, 'Disapprove')
        .then((value) => {
              value.forEach((v) => {
                    setState(() {
                      isLoading = false;
                      listTotal = v;
                      listApproval = v['listLoanRequests'];
                    }),
                  }),
            })
        .catchError((onError) {
      setState(() {
        isLoading = false;
      });
      return onError;
    });
    return false;
  }

  ScrollController _scrollController = ScrollController();
  StreamController _streamController = StreamController();
  StreamSink get itemsSink => _streamController.sink;

  bool onNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (_scrollController.position.maxScrollExtent >=
              _scrollController.offset &&
          _scrollController.position.maxScrollExtent -
                  _scrollController.offset <=
              1) {
        _additems();
      }
    }
    return true;
  }

  int _pageSize = 20;
  int _pageNumber = 1;

  Future _additems() async {
    setState(() {
      isLoading = true;
    });
    try {
      _pageSize += 10;
      // Fetch newItems with http
      await Provider.of<ApprovalSummaryProvider>(context, listen: false)
          .getApprovalSummary(
              _pageSize, _pageNumber, '', '', '', '', '', 'Disapprove');
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      itemsSink.addError(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  statusApproval(value) {
    switch (value) {
      case 'R':
        {
          return Text(
              AppLocalizations.of(context)!.translate('request') ?? 'Request',
              style: mainTitleBlack);
        }
      // break;

      case 'A':
        {
          return Text(
              AppLocalizations.of(context)!.translate('approved') ?? 'Approved',
              style: mainTitleBlack);
        }
      // break;

      case 'D':
        {
          return Text(
              AppLocalizations.of(context)!.translate('disapprove') ??
                  'Disapprove',
              style: mainTitleBlack);
        }
      // break;

      case 'T':
        {
          return Text(
              AppLocalizations.of(context)!.translate('return') ?? 'Return',
              style: mainTitleBlack);
        }
      // break;
      case 'O':
        {
          return Text(AppLocalizations.of(context)!.translate('open') ?? 'Open',
              style: mainTitleBlack);
        }
      // break;
      default:
        {
          return Text('', style: mainTitleBlack);
        }
      // break;
    }
  }

  final _imagesFindApproval =
      const AssetImage('assets/images/profile_create.jpg');

  onTapsDetail(value) async {
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new CardDetailLoanRegitration(
            list: value['loan']['lcode'],
            statusLoan: value['loan']['lstatus'],
          );
        },
        fullscreenDialog: true));
  }

  var status;
  var code;
  var sdate;
  var edate;
  //get branch
  var bcode;
  var bname;
  var odate;
  var procode;
  var listBranch = [];
  var listCO = [];

  TextEditingController controllerStartDate = new TextEditingController();
  TextEditingController controllerEndDate = new TextEditingController();
  Future getListBranches() async {
    await ApprovalHistoryProvider()
        .getListBranch()
        .then((value) => {
              setState(() {
                listBranch = value;
              }),
            })
        .catchError((onError) {
      return onError;
    });
  }

  Future getListCO(name) async {
    await ApprovalHistoryProvider()
        .getListCO(name)
        .then((value) => {
              setState(() {
                listCO = value;
              }),
            })
        .catchError((onError) {
      return onError;
    });
  }

  void _closeEndDrawer() {
    setState(() {
      code = null;
      bcode = null;
      controllerEndDate.text = '';
      controllerStartDate.text = '';
      isLoading = true;
    });

    getReportApprovalSummary(
            _pageSize, _pageNumber, '', '', '', '', '', 'Disapprove')
        .then((value) => {
              setState(() {
                isLoading = false;
              })
            })
        .catchError((onError) {
      setState(() {
        isLoading = false;
      });
      return onError;
    });
    getListBranches();
    Navigator.of(context).pop();
  }

  void _onClickListCO(v) {
    setState(() {
      code = v['ucode'];
    });
  }

  _onClickListBranch(v) {
    setState(() {
      bcode = v['bcode'];
    });
  }

  _applyEndDrawer() {
    setState(() {
      isLoading = true;
    });
    var startDate = sdate != null ? sdate : DateTime.now();
    var endDate = edate != null ? edate : DateTime.now();
    getReportApprovalSummary(20, 1, '', '', bcode, startDate.toString(),
            endDate.toString(), 'Disapprove')
        .then((value) => {
              setState(() {
                isLoading = false;
              })
            })
        .catchError((onError) {
      setState(() {
        isLoading = false;
      });
      return onError;
    });
    Navigator.of(context).pop();
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

  //
  loadMore(_pageSizeParam, _pageNumberParam, statusParam) async {
    try {
      var token = await storage.read(key: 'user_token');
      var userUcode = await storage.read(key: "user_ucode");
      var branch = await storage.read(key: "branch");
      var level = await storage.read(key: "level");
      var sdates = sdate != null ? sdate : '';
      var edates = edate != null ? edate : '';
      var codes = code != null ? code : '';

      statusParam != null && statusParam != "" ? statusParam : '';
      var btlcode = status != null ? status : '';
      var bcodes;
      var ucode;
      if (level == '3') {
        bcodes = bcode != null && bcode != "" ? bcode : branch;
        btlcode = '';
        ucode = codes != null && codes != "" ? codes : "";
      }

      if (level == '2') {
        bcodes = bcode != null && bcode != "" ? bcode : branch;
        btlcode = userUcode;
        ucode = code != null && code != "" ? code : '';
      }

      if (level == '1') {
        bcodes = bcode != null && bcode != "" ? bcode : branch;
        ucode = userUcode;
        btlcode = '';
      }

      if (level == '4' || level == '5' || level == '6') {
        bcodes = bcode != null && bcode != "" ? bcode : '';
        btlcode = '';
        ucode = code != null && code != "" ? code : '';
      }
      final Map<String, dynamic> bodyRow = {
        "pageSize": "$_pageSizeParam",
        "pageNumber": "$_pageNumberParam",
        "ucode": "$ucode",
        "bcode": "$bcodes",
        "btlcode": "$btlcode",
        "status": "$statusParam",
        "code": "",
        "sdate": "$sdates",
        "edate": "$edates"
      };
      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      };
      final Response response = await api().post(
          Uri.parse(baseURLInternal + 'reports/loanrequest/' + statusParam),
          headers: headers,
          body: json.encode(bodyRow));
      if (response.statusCode == 200) {
        var list = jsonDecode(response.body);
        list.forEach((v) => {
              setState(() {
                isLoading = false;
                listTotal = v;
                listApproval = v['listLoanRequests'];
              }),
            });
      }
    } catch (error) {
      logger().e('error :: $error');
    }
  }

  //
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    return WillPopScope(
      onWillPop: null,
      child: NotificationListener(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            // start loading data
            setState(() {
              _pageSize += 10;
            });
            loadMore(_pageSize, _pageNumber, "Disapproval");
          }
          return false;
        },
        child: Header(
          headerTexts: 'report_disapproval',
          actionsNotification: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            ),
          ],
          // leading: new IconButton(
          //   icon: new Icon(Icons.arrow_back),
          //   onPressed: () => Navigator.pushAndRemoveUntil(
          //       context,
          //       MaterialPageRoute(builder: (context) => Home()),
          //       ModalRoute.withName("/Home")),
          // ),
          bodys: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: logolightGreen,
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 0,
                      child: Container(
                          margin:
                              EdgeInsets.only(bottom: 10, left: 10, right: 10),
                          padding: EdgeInsets.all(4),
                          width: MediaQuery.of(context).size.width * 1,
                          color: logolightGreen,
                          child: Center(
                              child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('total_disapprove')!,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                              Text(
                                ': ${listTotal['total'].toString()}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ],
                          ))),
                    ),
                    listApproval.length > 0
                        ? Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: ListView.builder(
                                  itemCount: listApproval.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    if (listApproval.length > 0) {
                                      return Column(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                width: 1,
                                                color: logolightGreen,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: InkWell(
                                                splashColor:
                                                    Colors.blue.withAlpha(30),
                                                onTap: () {
                                                  onTapsDetail(
                                                      listApproval[index]);
                                                },
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: <Widget>[
                                                      Row(
                                                        children: <Widget>[
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      left: 5)),
                                                          Image(
                                                            image:
                                                                _imagesFindApproval,
                                                            width: 50,
                                                            height: 50,
                                                          ),
                                                          Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      right:
                                                                          15)),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: <Widget>[
                                                              SizedBox(
                                                                height: 6,
                                                              ),
                                                              Container(
                                                                  width: 150,
                                                                  child: Text(
                                                                    '${listApproval[index]['loan']['customer']}',
                                                                    style: mainTitleBlack.copyWith(
                                                                        fontSize:
                                                                            14),
                                                                  )),
                                                              Text(
                                                                  '${listApproval[index]['rcode']}'),
                                                              Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              2)),
                                                              Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              2)),
                                                              Text(
                                                                  '${listApproval[index]['loan']['currency']} ${numFormat.format(listApproval[index]['loan']['lamt'])}'),
                                                              Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              2)),
                                                              // Text(
                                                              //     '${listTotal[index]['lamt']} (${listTotal[index]['listLoanApplications']['adate']})'),
                                                              Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              2)),
                                                              // Text(
                                                              //     '${listTotal[index]['intrate']}/y'),
                                                              Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              2)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Container(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    right: 10),
                                                            child: Text(
                                                                '${getDateTimeYMD(listApproval[index]['rdate'])}'),
                                                          ),
                                                        ],
                                                      ),
                                                    ])),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Text('No list');
                                    }
                                  }),
                            ),
                          )
                        : Expanded(
                            flex: 1,
                            child: Center(
                                child: Container(
                                    child: Text(AppLocalizations.of(context)!
                                        .translate('no_data')!)))),
                  ],
                ),
          endDrawer: Drawer(
            child: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(padding: EdgeInsets.only(top: 35)),
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          // Icon(Icons.filter_list),
                          Padding(padding: EdgeInsets.only(right: 5)),
                          Text(
                            'Filter',
                            style: TextStyle(
                                fontWeight: fontWeight800, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(top: 10)),
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        AppLocalizations.of(context)!
                                .translate('list_branch') ??
                            'List Branch',
                        style: TextStyle(
                          fontWeight: fontWeight700,
                        ),
                      ),
                    ),
                    listBranch != ""
                        ? Container(
                            height: 180,
                            padding: EdgeInsets.only(left: 10, right: 10),
                            child: ListView.builder(
                                itemCount: listBranch != ""
                                    ? listBranch.length
                                    : [].length,
                                padding: const EdgeInsets.only(top: 10.0),
                                itemBuilder: (context, index) {
                                  return Card(
                                    child: InkWell(
                                      onTap: () =>
                                          _onClickListBranch(listBranch[index]),
                                      child: Center(
                                        child: Container(
                                            padding: EdgeInsets.all(5),
                                            child: Text(
                                              '${listBranch[index]['bname']}',
                                              style: TextStyle(
                                                  color: bcode ==
                                                          listBranch[index]
                                                              ['bcode']
                                                      ? logolightGreen
                                                      : Colors.black),
                                            )),
                                      ),
                                    ),
                                  );
                                }),
                          )
                        : Padding(padding: EdgeInsets.only(bottom: 1)),
                    //Pick start date
                    Container(
                      padding: EdgeInsets.only(left: 15, right: 15),
                      child: FormBuilderDateTimePicker(
                        name: 'date',
                        controller: controllerStartDate,
                        inputType: InputType.date,
                        onChanged: (v) {
                          setState(() {
                            sdate = v != null
                                ? v
                                : DateTime(now.year, now.month, 1);
                          });
                        },
                        initialValue: DateTime(now.year, now.month, 1),
                        format: DateFormat("yyyy-MM-dd"),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!
                                  .translate('start_date') ??
                              "Start date",
                        ),
                      ),
                    ),
                    //Pick date End
                    Container(
                      padding: EdgeInsets.only(left: 15, right: 15),
                      child: FormBuilderDateTimePicker(
                        name: 'date',
                        controller: controllerEndDate,
                        inputType: InputType.date,
                        onChanged: (v) {
                          setState(() {
                            edate = v != null ? v : DateTime.now();
                          });
                        },
                        initialValue: DateTime.now(),
                        format: DateFormat("yyyy-MM-dd"),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!
                                  .translate('end_date') ??
                              "End date",
                        ),
                      ),
                    ),
                    //Bottom Reset and Apply
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _closeEndDrawer,
                            child: Text(AppLocalizations.of(context)!
                                    .translate('reset') ??
                                "Reset"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: logolightGreen,
                            ),
                            onPressed: _applyEndDrawer,
                            child: Text(
                              AppLocalizations.of(context)!
                                      .translate('apply') ??
                                  "Apply",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
