import 'package:flutter/material.dart';
import 'package:todo_list/database/database.dart';
import 'package:todo_list/i10n/localization_intl.dart';
import 'package:todo_list/json/task_bean.dart';
import 'package:todo_list/json/task_icon_bean.dart';
import 'package:todo_list/model/all_model.dart';
import 'package:todo_list/utils/shared_util.dart';
import 'package:todo_list/utils/theme_util.dart';

class EditTaskPageLogic {
  final EditTaskPageModel _model;

  EditTaskPageLogic(this._model);

  Widget getIconText({Icon icon, String text, VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 4, 10, 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: Colors.grey.withOpacity(0.2)),
        child: Row(
          children: <Widget>[
            icon,
            SizedBox(
              width: 4,
            ),
            Text(text),
          ],
        ),
      ),
    );
  }

  //当为夜间模式时候，白色背景替换为特定灰色
  void getBgInDark() async {
    String currentThemeType =
        await SharedUtil.instance.getString(Keys.currentThemeType) ??
            MyTheme.defaultTheme;
    Color color =
        currentThemeType == MyTheme.darkTheme ? Colors.grey[800] : Colors.white;
    _model.bgColor = color;
    _model.refresh();
  }

  //提交一项任务
  void submitOneItem() {
    String text = _model.textEditingController.text;
    _model.taskDetails.add(TaskDetailBean(taskDetailName: text));
    _model.textEditingController.clear();
    _model.refresh();
  }

  //监听文字，提交按钮是否可以点击
  void editListener() {
    final text = _model.textEditingController.text;
    if (text.isEmpty && _model.canAddTaskDetail == true) {
      _model.canAddTaskDetail = false;
      _model.refresh();
    } else if (text.isNotEmpty && _model.canAddTaskDetail == false) {
      _model.canAddTaskDetail = true;
      _model.refresh();
    }
  }

  //删除一项任务
  void removeItem(int index) {
    _model.taskDetails.removeAt(index);
    _model.refresh();
  }

  //选择任务结束时间
  void pickEndTime() {
    DateTime initialDate =_model.startDate ?? DateTime.now();
    initialDate = initialDate.add(Duration(days: 1));
    DateTime firstDate = initialDate;
    DateTime lastDate = initialDate.add(Duration(days: 365));
    showDP(firstDate, initialDate, lastDate).then(
      (day) {
        if(day == null) return;
        if (_model.startDate != null) {
          if (day.isBefore(_model.startDate)) {
            showDialog(
                context: _model.context,
                builder: (ctx) {
                  return AlertDialog(
                    content: Text(DemoLocalizations.of(_model.context).endBeforeStart),
                  );
                });
            return;
          }
        }
        _model.deadLine = day;
        _model.refresh();
      },
    );
  }

  void pickStartTime(){
    DateTime initialDate = DateTime.now();
    DateTime firstDate = initialDate.add(Duration(days: 1));
    DateTime lastDate = initialDate.add(Duration(days: 365));
    showDP(firstDate, initialDate, lastDate).then(
          (day) {
            if(day == null) return;
        if (_model.deadLine != null) {
          if (day.isAfter(_model.deadLine)) {
            showDialog(
                context: _model.context,
                builder: (ctx) {
                  return AlertDialog(
                    content: Text(DemoLocalizations.of(_model.context).startAfterEnd),
                  );
                });
            return;
          }
        }
        _model.startDate = day;
        _model.refresh();
      },
    );
  }

  Future<DateTime> showDP(
      DateTime firstDate, DateTime initialDate, DateTime lastDate) {
    return showDatePicker(
      context: _model.context,
      initialDate: firstDate,
      firstDate: initialDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget child) {
        final color = ColorBean.fromBean(_model.taskIcon.colorBean);
        return FittedBox(
          child: Theme(
            child: child,
            data: ThemeData(
              primaryColor: color,
              accentColor: color,
              buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.accent),
            ),
          ),
        );
      },
    );
  }

  //将结束时间做个转换
  String getEndTimeText() {
    if (_model.deadLine != null) {
      final time = _model.deadLine;
      return "${time.year}-${time.month}-${time.day}";
    }
    return DemoLocalizations.of(_model.context).deadline;
  }

  //将开始时间做转换
  String getStartTimeText() {
    if (_model.startDate != null) {
      final time = _model.startDate;
      return "${time.year}-${time.month}-${time.day}";
    }
    return DemoLocalizations.of(_model.context).startDate;
  }

  //将DateTime转换为String
  String transformDateToString(DateTime date){
    return date.toIso8601String();
  }

  //将String转换为DateTime
  DateTime transformStringToDate(String date){
    return DateTime.parse(date);
  }

  //创建新的任务
  void submitNewTask() async{
    if(_model.taskDetails.length == 0){
      showDialog(context: _model.context,builder: (ctx){
        return AlertDialog(
          content: Text("请至少写下一项任务哦"),
        );
      });
      return;
    }

    final taskName = _model.currentTaskName.isEmpty ? _model.taskIcon.taskName : _model.currentTaskName;
    TaskBean taskBean = TaskBean(
      taskName: taskName,
      taskType: _model.taskIcon.taskName,
      taskDetailNum: _model.taskDetails.length,
      createDate: DateTime.now().toIso8601String(),
      startDate: _model.startDate?.toIso8601String(),
      deadLine: _model.deadLine?.toIso8601String(),
      detailList: _model.taskDetails,
      taskIconBean: _model.taskIcon,
    );
    await DBProvider.db.createTask(taskBean);
    _model.mainPageModel.logic.getTasks();
    Navigator.of(_model.context).pop();
  }


}
