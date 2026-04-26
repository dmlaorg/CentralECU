package AUTOSAR {

    private import ScalarValues::*;
    private import Automotive::*;
    private import Collections::*;

    comment about AUTOSAR
    /*
     * This package defines AUTOSAR Classic Platform software architecture concepts
     * modeled in SysML v2, building on the Automotive domain types for safety
     * and supplier traceability.
     *
     * Key concepts:
     *  - Sender/Receiver and Client/Server communication interfaces with safety qualification
     *  - Software Component (SwC) hierarchy: Atomic, Composition, Application, SensorActuator, Service
     *  - Runnable entities as the smallest schedulable code units
     *  - Periodic OS tasks with explicit timing and priority
     *  - Runtime Environment (RTE) as the communication mediator
     */

    // ─── Data types for inter-component communication ────────────────

    attribute def DataElement {
        doc /* Base type for data elements exchanged via Sender/Receiver interfaces. */
    }

    item def ServiceRequest {
        doc /* Request payload for Client/Server communication. */
        attribute operationId[0..1] : String;
        attribute dataElement[0..*] : DataElement;
    }

    item def ServiceResponse {
        doc /* Response payload for Client/Server communication. */
        attribute returnCode[0..1] : Integer;
    }

    // ─── Communication Interfaces ────────────────────────────────────

    port def SenderReceiverIF {
        doc /* AUTOSAR Sender/Receiver communication interface.
             * Provider (P-Port) uses the un-conjugated form — data flows out.
             * Consumer (R-Port) uses the conjugated (~) form — data flows in.
             */
        out attribute dataElement[0..*] : DataElement;
    }

    port def ClientServerIF {
        doc /* AUTOSAR Client/Server communication interface.
             * Server (P-Port) uses the un-conjugated form — receives requests, sends responses.
             * Client (R-Port) uses the conjugated (~) form — sends requests, receives responses.
             */
        in item request : ServiceRequest;
        out item response : ServiceResponse;
    }

    // ─── Timing and Scheduling ───────────────────────────────────────

    attribute def Event {
        doc /* Event-driven trigger for on-demand runnable activation. */
        attribute eventID : Integer;
    }

    // ─── Runnable Entity ─────────────────────────────────────────────

    action def Runnable {
        doc /* An AUTOSAR Runnable Entity — the smallest schedulable code unit.
             * Runnables reside in atomic SwCs and are activated by timing or event triggers.
             */

        attribute wcet : Integer; // Worst-case execution time here, dimensionless
    }

    // ─── OS Task ─────────────────────────────────────────────────────

    part def OsTask :> AutomotiveElement {
        doc /* An AUTOSAR OS periodic task that activates runnables on a fixed schedule.
             * Inherits safetyLevel and supplier from AutomotiveElement.
             */
        attribute osTaskPeriod[0..1] : Real; // Period in seconds, optional for non-periodic tasks
        attribute osTaskEventRef[0..*] : Event;
        attribute osTaskPriority[1..1] : Integer;
        port sr : SenderReceiverIF[0..*];
        port op : ClientServerIF[0..*];
    }

    // ─── OS container ───────────────────────────────────────────────

    item def EcucPartition :> AutomotiveElement {
        doc /* ECU Configuration Partition reference for OS application partitioning. */
    }

    abstract part def OsApplication {
        doc /* An AUTOSAR OS Application — a container for software components and tasks.
             * Inherits safetyLevel and supplier for traceability.
             */
        attribute osAppEcucPartitionRef : EcucPartition;
        attribute osTrusted : Boolean; // Indicates if the application is trusted (e.g., for safety-critical functions)
        part osAppTaskRef : OsTask[0..*];
    }

    // ─── Software Component Hierarchy ────────────────────────────────

    abstract part def SoftwareComponent :> AutomotiveElement {
        doc /* AUTOSAR Software Component (SwC) base type.
             * Inherits safetyLevel and supplier for safety and procurement traceability.
             */
    }

    part def AtomicSwC :> SoftwareComponent {
        doc /* Leaf-level AUTOSAR SwC containing runnables. Cannot be decomposed further. */
    }

    part def CompositionSwC :> SoftwareComponent {
        doc /* Composite AUTOSAR SwC containing sub-SwCs connected via the RTE. */
        part subcomponents : SoftwareComponent[0..*];
    }

    part def ApplicationSwC :> AtomicSwC {
        doc /* Application-layer SwC implementing functional behavior. */
    }

    part def SensorActuatorSwC :> AtomicSwC {
        doc /* Sensor/Actuator SwC bridging the application layer to ECU hardware I/O. */
    }

    part def ParameterSwC :> AtomicSwC {
        doc /* Service SwC providing BSW service abstractions (diagnostics, NvM, etc.). */
    }
}
