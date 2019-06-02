import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:remote_ui/src/parsers/center.dart';
import 'package:remote_ui/src/parsers/column.dart';
import 'package:remote_ui/src/parsers/container.dart';
import 'package:remote_ui/src/parsers/expanded.dart';
import 'package:remote_ui/src/parsers/flat_button.dart';
import 'package:remote_ui/src/parsers/padding.dart';
import 'package:remote_ui/src/parsers/raised_button.dart';
import 'package:remote_ui/src/parsers/row.dart';
import 'package:remote_ui/src/parsers/slider.dart';
import 'package:remote_ui/src/parsers/spacer.dart';
import 'package:remote_ui/src/parsers/stack.dart';
import 'package:remote_ui/src/parsers/text.dart';

abstract class RemoteFactory {
  Widget fromJson(BuildContext context, Map<String, dynamic> definition, Map<String, dynamic> data, RemoteWidgetFactory factory);
}

class RemoteWidgetFactory {
  final List<RemoteFactory> _customParsers;
  final ColumnParser _columnParser = ColumnParser();
  final RowParser _rowParser = RowParser();
  final StackParser _stackParser = StackParser();
  final PaddingParser _paddingParser = PaddingParser();
  final ExpandedParser _expandedParser = ExpandedParser();
  final ContainerParser _containerParser = ContainerParser();
  final SliderParser _sliderParser;
  final TextParser _textParser = TextParser();
  final FlatButtonParser _flatButtonParser;
  final RaisedButtonParser _raisedButtonParser;
  final SpacerParser _spacerParser = SpacerParser();
  final CenterParser _centerParser = CenterParser();

  RemoteWidgetFactory(this._customParsers)
      : _raisedButtonParser = RaisedButtonParser(),
        _sliderParser = SliderParser(),
        _flatButtonParser = FlatButtonParser();

  dynamic getData(Map<String, dynamic> definition, Map<String, dynamic> data, String key, {defaultValue}) {
    final definitionData = definition[key];
    if (definitionData is String && definitionData.startsWith('\$') && definitionData.endsWith('\$')) {
      return _getSubData(data, definitionData, defaultValue: defaultValue);
    }
    return definitionData ?? defaultValue;
  }

  dynamic _getSubData(Map<String, dynamic> data, String dataKey, {defaultValue}) {
    if (data == null || data.isEmpty) {
      return defaultValue;
    }

    final parsedKey = dataKey.replaceAll('\$', '');

    if (parsedKey.contains('.')) {
      final parts = parsedKey.split('.');
      return _getSubData(data[parts.first], parts.sublist(1).join('.'));
    }

    return data[parsedKey] ?? defaultValue;
  }

  EdgeInsets getEdgeInsets(definition) {
    if (definition == null) {
      return null;
    }
    if (definition is Map) {
      return EdgeInsets.fromLTRB(
        definition['left']?.toDouble() ?? .0,
        definition['top']?.toDouble() ?? .0,
        definition['right']?.toDouble() ?? .0,
        definition['bottom']?.toDouble() ?? .0,
      );
    }
    return EdgeInsets.all(definition.toDouble());
  }

  Widget fromJson(BuildContext context, Map<String, dynamic> definition, Map<String, dynamic> data) {
    if (definition == null) {
      return null;
    }

    if (definition.containsKey('flex') && definition['type'] != 'expanded' && definition['type'] != 'spacer') {
      final flex = definition['flex'];

      return Expanded(
        flex: flex,
        child: fromJson(context, Map.from(definition)..remove('flex'), data),
      );
    }

    for (var parser in _customParsers) {
      final item = parser.fromJson(context, definition, data, this);
      if (item != null) {
        return item;
      }
    }

    switch (definition['type']) {
      case 'center':
        return _centerParser.parse(context, definition, data, this);
      case 'column':
        return _columnParser.parse(context, definition, data, this);
      case 'row':
        return _rowParser.parse(context, definition, data, this);
      case 'stack':
        return _stackParser.parse(context, definition, data, this);
      case 'expanded':
        return _expandedParser.parse(context, definition, data, this);
      case 'padding':
        return _paddingParser.parse(context, definition, data, this);
      case 'container':
        return _containerParser.parse(context, definition, data, this);
      case 'slider':
        return _sliderParser.parse(context, definition, data, this);
      case 'text':
        return _textParser.parse(context, definition, data, this);
      case 'spacer':
        return _spacerParser.parse(context, definition, data, this);
      case 'flat_button':
        return _flatButtonParser.parse(context, definition, data, this);
      case 'raised_button':
        return _raisedButtonParser.parse(context, definition, data, this);
    }
    return Placeholder();
  }
}

class RemoteWidgetData extends InheritedWidget {
  final data;

  RemoteWidgetData({this.data, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(RemoteWidgetData oldWidget) {
    return oldWidget.data != data;
  }

  static RemoteWidgetData of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(RemoteWidgetData) as RemoteWidgetData;
  }
}

class RemoteWidget extends StatelessWidget {
  final associatedData;
  final Map<String, dynamic> data;
  final Map<String, dynamic> definition;

  const RemoteWidget({Key key, @required this.definition, this.associatedData, this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final factory = RemoteWidgetFactory(RemoteManagerWidget.of(context).parsers);
    return RemoteWidgetData(
      child: factory.fromJson(context, definition, data),
      data: associatedData,
    );
  }
}

class RemoteManagerWidget extends InheritedWidget {
  final Function(String key, dynamic value, {dynamic associatedData}) onChanges;
  final List<RemoteFactory> parsers;

  RemoteManagerWidget({Key key, this.onChanges, Widget child, this.parsers = const []}) : super(key: key, child: child);

  @override
  bool updateShouldNotify(RemoteManagerWidget oldWidget) {
    return oldWidget.onChanges != onChanges;
  }

  static RemoteManagerWidget of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(RemoteManagerWidget) as RemoteManagerWidget;
  }
}
