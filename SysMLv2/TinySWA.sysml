package TinySWA
{
    private import ScalarValues::*;
    private import Automotive::*;
    private import AUTOSAR::*;
    private import CentralEcu::*;
    private import SI::*;

     comment about TinySWA
     /*
      * This package defines a tiny software architecture example in SysML v2, demonstrating key concepts of
      * software components, ports, interfaces, runnables, and tasks in a simplified context.
      *
      * Key concepts:
      *  - Two software components: SensorComponent and ActuatorComponent
      *  - Sender/Receiver interface for sensor data flow
      *  Runnable entities for reading sensor data and applying actuation commands
      *  Periodic OS tasks for scheduling runnables
      */

    interface SensorDataInterface
        connect task10ms.sr to task20ms.sr;

    part root : CompositionSwC
    {
        part SensorComponent : ApplicationSwC
        {
            part task10ms : OsTask { :>> osTaskPeriod = 10;}
        }
        part ActuatorComponent : ApplicationSwC
        {
            part task20ms : OsTask { :>> osTaskPeriod = 20;}
        }
    }
}