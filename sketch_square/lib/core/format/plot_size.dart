import '../../features/drawings/domain/plot_size.dart';

/// `30×40 ft` label for a plot given in feet.
String formatPlotSize(double lengthFt, double breadthFt) =>
    '${formatDimension(lengthFt)}×${formatDimension(breadthFt)} ft';
