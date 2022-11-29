import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

// from https://medium.com/nerd-for-tech/flutter-creating-a-two-direction-scrolling-table-with-fixed-head-and-column-4a34fc01378f
// https://github.com/crizant/flutter_multiplication_table/blob/master/lib/table_body.dart
// and modified as needed
class ScrollableTable extends StatefulWidget {
  late final List<String> columnHeadings;
  late final double dataCellWidth;
  late final Color headingBackgroundColor;
  late final double descriptionColumnWidth;
  late final double dataCellHeight;
  late final Color descriptionBackgroundColor;
  late final List<Color> dataRowsBackgroundColors;
  late final List<List<String>> gridData;
  late final List<RowDescription> descriptions;

  ScrollableTable(
      {required this.columnHeadings,
      required this.dataCellWidth,
      required this.dataCellHeight,
      required this.headingBackgroundColor,
      required this.descriptionColumnWidth,
      required this.descriptionBackgroundColor,
      required this.dataRowsBackgroundColors,
      required this.gridData,
      required this.descriptions});

  @override
  _ScrollableTableState createState() => _ScrollableTableState();
}

class _ScrollableTableState extends State<ScrollableTable> {
  late final LinkedScrollControllerGroup _controllers;
  late final ScrollController _headController;
  late final ScrollController _bodyController;

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    _headController = _controllers.addAndGet();
    _bodyController = _controllers.addAndGet();
  }

  @override
  void dispose() {
    _headController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableHead(
            scrollController: _headController,
            columnHeadings: widget.columnHeadings,
            descriptionColumnWidth: widget.descriptionColumnWidth,
            cellWidth: widget.dataCellWidth,
            cellHeight: widget.dataCellHeight,
            backgroundColor: widget.headingBackgroundColor),
        TableBody(
            scrollController: _bodyController,
            descriptionColumnWidth: widget.descriptionColumnWidth,
            dataCellWidth: widget.dataCellWidth,
            dataCellHeight: widget.dataCellHeight,
            descriptionBackgroundColor: widget.descriptionBackgroundColor,
            dataRowBackgroundColors: widget.dataRowsBackgroundColors,
            gridData: widget.gridData,
            descriptions: widget.descriptions),
      ],
    );
  }
}

class TableHead extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> columnHeadings;
  final double cellWidth;
  final double cellHeight;
  final Color? backgroundColor;
  final double descriptionColumnWidth;

  TableHead(
      {required this.scrollController,
      required this.columnHeadings,
      required this.cellWidth,
      required this.cellHeight,
      this.backgroundColor,
      required this.descriptionColumnWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cellWidth,
      width: descriptionColumnWidth + columnHeadings.length * cellWidth,
      child: Row(
        children: [
          // The first column must match description(leftmost) column width
          SizedBox(
            width: descriptionColumnWidth,
            child: GridTableCell(
              color: backgroundColor ?? Colors.yellow.withOpacity(0.3),
              value: " ",
            ),
          ),
          Expanded(
            child: ListView.builder(
                controller: scrollController,
                physics: ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: columnHeadings.length,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    width: cellWidth,
                    child: GridTableCell(
                      color: Colors.yellow.withOpacity(0.3),
                      value: columnHeadings[index],
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}

class TableBody extends StatefulWidget {
  final ScrollController scrollController;
  final double descriptionColumnWidth;
  final double dataCellWidth;
  final double dataCellHeight;
  final Color descriptionBackgroundColor;
  final List<Color> dataRowBackgroundColors;
  final List<List<String>> gridData;
  final List<RowDescription> descriptions;

  TableBody(
      {required this.scrollController,
      required this.descriptionColumnWidth,
      required this.dataCellWidth,
      required this.dataCellHeight,
      required this.descriptionBackgroundColor,
      required this.dataRowBackgroundColors,
      required this.gridData,
      required this.descriptions});

  @override
  _TableBodyState createState() => _TableBodyState();
}

class _TableBodyState extends State<TableBody> {
  late final LinkedScrollControllerGroup _controllers;
  late final ScrollController _firstColumnController;
  late final ScrollController _restColumnsController;

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup();
    _firstColumnController = _controllers.addAndGet();
    _restColumnsController = _controllers.addAndGet();
  }

  @override
  void dispose() {
    _firstColumnController.dispose();
    _restColumnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // First widget in row is the description
        SizedBox(
          width: widget.descriptionColumnWidth,
          child: ListView.builder(
              controller: _firstColumnController,
              physics: ClampingScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.descriptions.length,
              itemBuilder: (BuildContext context, int index) {
                return GridDescriptionCell(
                  color: widget.descriptionBackgroundColor,
                  rowDescription: widget.descriptions[index],
                  cellWidth: widget.descriptionColumnWidth,
                  cellHeight: widget.dataCellHeight,
                );
              }),
        ),
        // remaining elements in row is the data
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: (widget.gridData[0].length) * widget.dataCellWidth,
              height: (widget.descriptions.length * widget.dataCellHeight),
              child: ListView(
                controller: _restColumnsController,
                physics: const ClampingScrollPhysics(),
                // We build row by row, so each row contains all the hourly
                // data for each forecast.
                children: List.generate(widget.descriptions.length, (y) {
                  return Row(
                    children: List.generate(widget.gridData[0].length, (x) {
                      // remaining widgets in row are the data for that particular forecast
                      return SizedBox(
                        width: widget.dataCellWidth,
                        height: widget.dataCellHeight,
                        child: GridTableCell(
                          value: widget.gridData[y][x],
                          color: widget.dataRowBackgroundColors[
                              y % widget.dataRowBackgroundColors.length],
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GridTableCell extends StatelessWidget {
  final String value;
  final Color color;

  GridTableCell({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black12,
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${value ?? ''}',
        style: TextStyle(fontSize: 16.0),
      ),
    );
  }
}

class GridDescriptionCell extends StatelessWidget {
  final RowDescription rowDescription;
  final Color color;
  final double cellWidth;
  final double cellHeight;

  GridDescriptionCell({
    required this.rowDescription,
    required this.color,
    required this.cellWidth,
    required this.cellHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: cellWidth,
        height: cellHeight,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: Colors.black12,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: TextButton(
            child: Text(rowDescription.description),
            onPressed: (() {
              if (rowDescription.helpDescription != null) {
                CommonWidgets.showInfoDialog(
                    context: context,
                    title: rowDescription.description,
                    msg: rowDescription.helpDescription!,
                    button1Text: StandardLiterals.OK,
                    button1Function: (() => Navigator.of(context).pop()));
              }
            }),
            //_getRowDescriptionWidget(context, rowDescription),
          ),
        ));
  }
}

class RowDescription {
  final String description;
  final String? helpDescription;

  RowDescription({required this.description, this.helpDescription});
}
