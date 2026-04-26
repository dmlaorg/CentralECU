private import PlatformTypes::*;
private import Automotive::*;
private import AUTOSAR::*;

attribute partition1 : EcucPartition { :>> safetyLevel = ASIL::ASIL_D; }
attribute partition2: EcucPartition { :>> safetyLevel = ASIL::QM; }
attribute def var {attribute elem1 : Rational; attribute elem2 : String; }
attribute backgroundEvent : Event { :>> eventID = 1;}

part root : CompositionSwC // root composition
{
    doc /* Composition SWC */
    part cswc1 : CompositionSwC {
        part cswc3 : CompositionSwC { doc  /* Composition SWC */
            part aswc1 : ApplicationSwC { doc /* Application SWC */
                part task1 : OsTask { :>> osTaskPeriod = 10 [ms];} // timer task
                part task2 : OsTask { :>> osTaskPeriod = (); :>> osTaskEventRef = backgroundEvent; } // background task
                out op : ClientServerIF { out :> response.returnCode : uint8; in :> param : sint16; } // server function
            }
            part cswc4 : CompositionSwC {
                part aswc3 : ApplicationSwC { doc /* Application SWC */
                    part task4 : OsTask { :>> osTaskPeriod = 10 [ms];} // timer task
                }
            }
        }
    }

    comment about cswc2 /* Composition of a different partition */
    part cswc2 : CompositionSwC {
        part aswc2 : ApplicationSwC 
        {
            part task3 : OsTask { :>> osTaskPeriod = 10 [ms];}
        }
    }
}

part osApplciationD : OsApplication {
    doc /* OS application for safety-critical software. */
    :>> osAppEcucPartitionRef = partition1; // partition reference for OS application
    :>> osTrusted = true; 
    :>> osAppTaskRef = (root.cswc1.cswc3.aswc1.task1, root.cswc1.cswc3.aswc1.task2); // reference to OS task(s) contained in this application
}

part osApplciationQM : OsApplication {
    doc /* OS application for non-safety critical software. */
    :>> osAppEcucPartitionRef = partition2; // partition reference for OS application
    :>> osTrusted = false;
    :>> osAppTaskRef = root.cswc2.aswc2.task3; // reference to OS task(s) contained in this application
}

/* client server operation 'op'
 * provided by 'aswc1'
 * requested by 'task2' */
interface CS_ASWC1_op connect root.cswc1.cswc3.aswc1.op to root.cswc1.cswc3.aswc1.task2.op;
/* sender receiver interface 'sr1' data 'var'
 * provided by 'task2' and 'task4'
 * requested by 'task2' and 'task4' */
flow sr1 of var from 
root.cswc1.cswc3.aswc1.task2.sr to root.cswc1.cswc3.cswc4.aswc3.task4.sr;
/* sender receiver interface 'sr2' data 'var'
 * provided by 'task1', 'task2' and 'task4',
 * requested by 'task3' */
interface def sr2 {
    end[0..*] port provider : SenderReceiverIF;
    end port consumer : SenderReceiverIF;
    flow of var from root.cswc1.cswc3.aswc1.task1.sr to root.cswc2.aswc2.task3.sr;
    flow of var from root.cswc1.cswc3.aswc1.task2.sr to root.cswc2.aswc2.task3.sr;
    flow of var from root.cswc1.cswc3.cswc4.aswc3.task4.sr to root.cswc2.aswc2.task3.sr;
}