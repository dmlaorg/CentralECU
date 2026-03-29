package BrakeControlSw {

    private import ScalarValues::*;
    private import Automotive::*;
    private import AUTOSAR::*;
    private import CentralEcu::*;

    comment about BrakeControlSw
    /*
     * Example AUTOSAR Classic brake control application modeled as an EmbeddedSoftware
     * deployment unit from the CentralECU domain. Demonstrates Sender/Receiver and
     * Client/Server interfaces, runnables, periodic tasks, and RTE-mediated connections.
     */

    // ─── Concrete Data Elements ──────────────────────────────────────

    item def WheelSpeedData :> DataElement {
        doc /* Wheel speed measurement data element. */
        attribute speedRpm : Real;
    }

    item def BrakeForceCommand :> DataElement {
        doc /* Brake force actuation command data element. */
        attribute forceNewton : Real;
    }

    item def DiagRequest :> ServiceRequest {
        doc /* Diagnostic service request with DTC query code. */
        attribute diagCode : Integer;
    }

    item def DiagResponse :> ServiceResponse {
        doc /* Diagnostic service response carrying a DTC value. */
        attribute dtcValue : Integer;
    }

    // ─── Concrete S/R and C/S Interfaces ─────────────────────────────

    port def WheelSpeedIF :> SenderReceiverIF {
        doc /* S/R interface carrying wheel speed data, qualified ASIL D. */
        :>> safetyLevel = ASIL::ASIL_D;
        out :>> dataElement : WheelSpeedData;
    }

    port def BrakeForceIF :> SenderReceiverIF {
        doc /* S/R interface carrying brake force commands, qualified ASIL D. */
        :>> safetyLevel = ASIL::ASIL_D;
        out :>> dataElement : BrakeForceCommand;
    }

    port def DiagServiceIF :> ClientServerIF {
        doc /* C/S interface for diagnostic services, qualified ASIL B. */
        :>> safetyLevel = ASIL::ASIL_B;
        in :>> request : DiagRequest;
        out :>> response : DiagResponse;
    }

    // ─── Concrete Runnables ──────────────────────────────────────────

    action def ReadWheelSpeedRunnable :> Runnable {
        doc /* Reads raw wheel speed from sensor hardware. */
        out item reading : WheelSpeedData;
    }

    action def BrakeControlRunnable :> Runnable {
        doc /* Computes brake force from wheel speed input. */
        in item wheelSpeed : WheelSpeedData;
        out item brakeCmd : BrakeForceCommand;
    }

    action def ApplyBrakeRunnable :> Runnable {
        doc /* Applies brake force command to actuator hardware. */
        in item cmd : BrakeForceCommand;
    }

    action def DiagServiceRunnable :> Runnable {
        doc /* Handles incoming diagnostic service requests. */
        in item req : DiagRequest;
        out item resp : DiagResponse;
    }

    // ─── Concrete SwC Definitions ────────────────────────────────────

    part def WheelSpeedSensorSwC :> SensorActuatorSwC {
        doc /* Sensor SwC providing wheel speed data via a P-Port. */
        port wheelSpeedOut : WheelSpeedIF;
        action readSpeed : ReadWheelSpeedRunnable;
    }

    part def BrakeControlSwC :> ApplicationSwC {
        doc /* Application SwC computing brake force from wheel speed. */
        port wheelSpeedIn : ~WheelSpeedIF;
        port brakeCmdOut : BrakeForceIF;
        port diagClient : ~DiagServiceIF;
        action controlCycle : BrakeControlRunnable;
    }

    part def BrakeActuatorSwC :> SensorActuatorSwC {
        doc /* Actuator SwC applying brake force commands to hardware. */
        port brakeCmdIn : ~BrakeForceIF;
        action applyBrake : ApplyBrakeRunnable;
    }

    part def BrakeDiagSwC :> ParameterSwC {
        doc /* Service SwC providing diagnostic operations via a P-Port. */
        port diagServer : DiagServiceIF;
        action diagHandler : DiagServiceRunnable;
    }

    // ─── Periodic OS Tasks with Runnable-to-Task Mapping ─────────────

    part task10ms : OsTask {
        doc /* 10 ms high-priority task for safety-critical brake runnables. */
        :>> timing { :>> periodMs = 10; }
        :>> priority = 5;
        :>> safetyLevel = ASIL::ASIL_D;
        :>> supplier.name = "OsVendor";

        action taskBody {
            action readSpeed : ReadWheelSpeedRunnable;
            action controlCycle : BrakeControlRunnable;
            action applyBrake : ApplyBrakeRunnable;
            first readSpeed then controlCycle;
            first controlCycle then applyBrake;
        }
    }

    part task100ms : OsTask {
        doc /* 100 ms lower-priority task for diagnostic runnables. */
        :>> timing { :>> periodMs = 100; }
        :>> priority = 3;
        :>> safetyLevel = ASIL::ASIL_B;
        :>> supplier.name = "OsVendor";

        action taskBody {
            action diagHandler : DiagServiceRunnable;
        }
    }

    // ─── Brake System as EmbeddedSoftware ────────────────────────────

    part brakeSystemSW : EmbeddedSoftware {
        doc /* Brake control system modeled as an EmbeddedSoftware deployment unit,
             * composed of AUTOSAR SwCs connected via RTE Sender/Receiver and
             * Client/Server interfaces.
             */
        :>> safetyLevel = ASIL::ASIL_D;
        :>> supplier.name = "BrakeSystemSupplier";

        // SwC instances
        part sensor : WheelSpeedSensorSwC {
            :>> safetyLevel = ASIL::ASIL_D;
            :>> supplier.name = "SensorSupplier";
        }

        part controller : BrakeControlSwC {
            :>> safetyLevel = ASIL::ASIL_D;
            :>> supplier.name = "ControlSupplier";
        }

        part actuator : BrakeActuatorSwC {
            :>> safetyLevel = ASIL::ASIL_D;
            :>> supplier.name = "ActuatorSupplier";
        }

        part diagComponent : BrakeDiagSwC {
            :>> safetyLevel = ASIL::ASIL_B;
            :>> supplier.name = "DiagSupplier";
        }

        // RTE instance mediating inter-SwC communication
        part rte : RTE {
            :>> safetyLevel = ASIL::ASIL_D;
            :>> supplier.name = "RTEGenerator";
        }

        // RTE-mediated S/R assembly connectors
        interface sensorToController connect
            sensor.wheelSpeedOut to controller.wheelSpeedIn;

        interface controllerToActuator connect
            controller.brakeCmdOut to actuator.brakeCmdIn;

        // RTE-mediated C/S assembly connector
        interface diagConnection connect
            controller.diagClient to diagComponent.diagServer;
    }

}
