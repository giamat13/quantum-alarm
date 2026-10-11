using Toybox.Application as App;
using Toybox.WatchUi as Ui;

// Only API 1.x features are used here, so the same code runs on old watches.
class QuantumAlarmApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new QuantumAlarmView();
        return [view, new QuantumAlarmDelegate(view)];
    }
}
