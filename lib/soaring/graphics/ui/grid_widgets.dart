import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class ScrollableTable extends StatefulWidget {
  late final List<String> columnHeadings;
  late final double headingColumnWidth;
  late final Color headingBackgroundColor;
  late final double descriptionColumnWidth;
  late final Color descriptionBackgroundColor;
  late final List<Color> dataRowsBackgroundColors;
  late final List<List<String>> gridData;
  late final List<String> descriptions;

  ScrollableTable(
      {required this.columnHeadings,
      required this.headingColumnWidth,
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
            cellWidth: widget.headingColumnWidth,
            backgroundColor: widget.headingBackgroundColor),
        Expanded(
          child: TableBody(
              scrollController: _bodyController,
              descriptionColumnWidth: widget.descriptionColumnWidth,
              dataCellWidth: widget.headingColumnWidth,
              descriptionBackgroundColor: widget.descriptionBackgroundColor,
              dataRowBackgroundColors: widget.dataRowsBackgroundColors,
              gridData: widget.gridData,
              descriptions: widget.descriptions),
        ),
      ],
    );
  }
}

class TableHead extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> columnHeadings;
  final double cellWidth;
  final Color? backgroundColor;

  TableHead(
      {required this.scrollController,
      required this.columnHeadings,
      required this.cellWidth,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cellWidth,
      child: Row(
        children: [
          GridTableCell(
            color: backgroundColor ?? Colors.yellow.withOpacity(0.3),
            value: " ",
            cellWidth: cellWidth,
          ),
          Expanded(
            child: ListView.builder(
                controller: scrollController,
                physics: ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: columnHeadings.length,
                itemBuilder: (BuildContext context, int index) {
                  return GridTableCell(
                    color: Colors.yellow.withOpacity(0.3),
                    value: columnHeadings[index - 1],
                    cellWidth: cellWidth,
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
  final Color descriptionBackgroundColor;
  final List<Color> dataRowBackgroundColors;
  final List<List<String>> gridData;
  final List<String> descriptions;

  TableBody(
      {required this.scrollController,
      required this.descriptionColumnWidth,
      required this.dataCellWidth,
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
        SizedBox(
          width: widget.descriptionColumnWidth,
          child: ListView.builder(
              controller: _firstColumnController,
              physics: ClampingScrollPhysics(),
              itemCount: widget.descriptions.length,
              itemBuilder: (BuildContext context, int index) {
                return GridTableCell(
                  color: widget.descriptionBackgroundColor ??
                      Colors.yellow.withOpacity(0.3),
                  value: widget.descriptions[index],
                  cellWidth: widget.descriptionColumnWidth,
                );
              }),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: (widget.gridData[0].length) * widget.dataCellWidth,
              child: ListView(
                controller: _restColumnsController,
                physics: const ClampingScrollPhysics(),
                children: List.generate(widget.descriptions.length - 1, (y) {
                  return Row(
                    children: List.generate(widget.gridData.length - 1, (x) {
                      return GridTableCell(
                        value: widget.gridData[x][y],
                        color: widget.dataRowBackgroundColors[
                            y % widget.dataRowBackgroundColors.length],
                        cellWidth: widget.dataCellWidth,
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
  final double cellWidth;

  GridTableCell(
      {required this.value, required this.color, required this.cellWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cellWidth,
      height: cellWidth,
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
