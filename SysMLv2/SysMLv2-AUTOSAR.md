# AUTOSAR Classic Concepts in SysML v2 - a subset for SW architecture

| Concept | SysML v2 Construct | Notes |
|---|---|---|
| `DataElement` | `item def` | Base for S/R data exchange |
| `ServiceRequest` / `ServiceResponse` | `item def :> DataElement` | C/S payloads |
| `SenderReceiverIF` | `port def` with `out item` + `safetyLevel : ASIL` | P-Port un-conjugated, R-Port conjugated (`~`) |
| `ClientServerIF` | `port def` with `in item` request + `out item` response + `safetyLevel` | Server un-conjugated, Client conjugated |
| `PeriodicTiming` / `EventTiming` | `attribute def` | Runnable activation triggers |
| `Runnable` | `action def` with `wcet : Integer` | Smallest schedulable code unit with worst-case execution time |
| `OsTask` | `part def :> AutomotiveElement` | Periodic task with timing, priority, safetyLevel |
| `SoftwareComponent` hierarchy | `abstract part def :> AutomotiveElement` | `AtomicSWC`, `CompositionSWC`, `ApplicationSWC`, `SensorActuatorSWC`, `ServiceSWC` |
| `RTE` | `part def :> AutomotiveElement` | Runtime Environment mediator |
