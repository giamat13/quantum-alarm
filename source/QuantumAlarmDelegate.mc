using Toybox.WatchUi as Ui;

// No interaction: the alarm stays in superposition forever.
class QuantumAlarmDelegate extends Ui.BehaviorDelegate {

    function initialize(view) {
        BehaviorDelegate.initialize();
    }
}
