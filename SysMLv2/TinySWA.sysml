package TinySWA
{
    private import ScalarValues::*;
    private import Automotive::*;
    private import AUTOSAR::*;
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

    part root : CompositionSwC
    {
        part aswc1 : ApplicationSwC
        {
            action task10ms : OsTask 
            { 
                :>> osTaskPeriod = 10;
            }
        }
        part aswc2 : ApplicationSwC
        {
            action task20ms : OsTask 
            { 
                :>> osTaskPeriod = 20;
            }
        }
    }
    
    interface SensorDataInterface
        connect root.aswc1.task10ms.sr to root.aswc2.task20ms.sr;
}