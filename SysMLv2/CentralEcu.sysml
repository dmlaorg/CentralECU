package CentralECUDomain {

    private import ScalarValues::*; 
    private import Automotive::*;
    private import SequenceFunctions::size;

    requirement <'PTCnumber123456789'> MinimumNumberOfMemoryBanks : AutomotiveRequirement {
        doc /* The system shall have at least two separate non-volatile memory banks. */
        :>> id = "OTA-1-1";
        :>> text = "The system shall have at least two separate non-volatile memory banks.";
        :>> safetyLevel = ASIL::ASIL_D;
        :>> supplier {
                :>> isInternal = true;
                :>> domain = AutomotiveDomain::Chassis;
                :>> name = "InternalSupplier";
                :>> id = "INT-001";
                :>> contactInfo = "Budapest, Hungary";
            }

        subject soc : SoC;
        attribute memBanksRequired : Integer = 2;

        assume constraint { soc.safetyLevel == ASIL::ASIL_D }

        require constraint { size(soc.memory) >= memBanksRequired }
    }

    part def CentralEcuComposition specializes AutomotiveElement {
        // Replace explicit interface block with built-in SysML ports
        port channels[0..*];
    }

    part def CentralECU specializes CentralEcuComposition {
        public part elements : AutomotiveElement[1..*];
        part socs : SoC[1..*] subsets elements;
    }

    // Use SysML port definition for shared memory communication
    port def SharedMemoryPort {
        attribute memory : MemoryRegion;
        in attribute accessedMemory : MemoryRegion;
    }

    interface def SharedMemoryInterface {
        end [0..*] port read : SharedMemoryPort;
        end port write  : ~SharedMemoryPort; 

        flow of MemoryRegion
            from write.accessedMemory to read.accessedMemory;
    }

    part def SoC :> CentralEcuComposition {
        part cores : Core[1..*] nonunique; 
        //"Subsetting feature cannot be nonunique if subsetted feature is unique" warning:
        // only in Syside, pointing to `Items::Item::subparts` as unique subsetted feature
        part softwares : EmbeddedSoftware[1..*];
        part memory : MemoryModule[1..*];

        :> channels : SharedMemoryPort[1..*];
    }

    part def Mcu :> SoC {
        // empty array redefinition to "seal" interfaces
        :>> channels = ();
        
        :> cores[1];
    }

    part def Core :> AutomotiveElement {
        attribute frequencyHz : Real;
        attribute isLockstep : Boolean;
    }

    part def EmbeddedSoftware :> AutomotiveElement { }

    part def MemoryModule :> AutomotiveElement {
        attribute memoryRegion : MemoryRegion[1..*];
    }

    attribute def MemoryRegion {
        attribute startAddress : Integer;
        attribute endAddress : Integer;
        attribute sizeKB : Integer;
    }

    part def ACC :> EmbeddedSoftware {
        redefines safetyLevel = ASIL::ASIL_B;
    }
    // Concrete software components

    part concreteACC : ACC {
        redefines supplier.name = "Tier1Supplier-B";
    }

    part brakeControl : EmbeddedSoftware {
        attribute redefines safetyLevel[*] = ASIL::ASIL_D; 
        // "smaller/larger multiplicity ulower/upper bound" warning only in Jupyter, not in Syside!
        redefines supplier.name = "Tier1Supplier-B";
    }

    part swUpManager : EmbeddedSoftware {
        :>> safetyLevel[4] = ASIL::QM; 
        // "larger multiplicity upper bound" warning only in Jupyter, not in Syside!
        :>> supplier.name = "Tier1Supplier-A";
    }

    // cores
    part cr7 : Core {
        :>> safetyLevel = ASIL::ASIL_D;
        :>> supplier.name = "Arm";
        :>> frequencyHz = 800000000;
        :>> isLockstep : Real = "true"; 
        // "Not conforming types" warning by Jupyter and Syside both!
    }

    part ca57 : Core {
        redefines safetyLevel = ASIL::ASIL_B;
        :>> supplier.name = "Arm";
        :>> frequencyHz = 1900000000;
        :>> isLockstep = false;
    }

    part ca53 : Core {
        redefines safetyLevel = 0;
        redefines supplier.name = "Arm";
        :>> frequencyHz : Integer = 1500000000;
        redefines isLockstep : Boolean = false;
    }

    // SoC types
    part def SoC_A :> SoC {
        redefines cores = (cr7, ca57, ca57, ca53, ca53);

        //part acc1         : ACC = ConcreteACC;
        part acc2         : ACC = concreteACC;
        part brakeCtrl   : EmbeddedSoftware = concreteACC;
        part swUpManager = swUpManager;
        :>> softwares = (acc2, brakeCtrl, swUpManager);

        :>> safetyLevel = ASIL::ASIL_D;

        part flash1 : MemoryModule {
            :>> memoryRegion {
                :>> sizeKB = 512.1; 
                // No "conforming types" warning in Jupyter, only in Syside!
                :>> safetyLevel = ASIL::QM;
                :>> supplier.name = "MemorySupplier-A";
            }
        }
        part flash2 : MemoryModule {
            :>> memoryRegion {
                redefines sizeKB = 512;
                :>> safetyLevel = ASIL::QM;
                :>> supplier.name = "MemorySupplier-A";
            }
        }
        
        :>> memory = (flash1, flash2);

        // channel using built-in port/interface
        port sharedMem : SharedMemoryPort;
        :>> channels = sharedMem;
    }

    part def SoC_B :> SoC {
        port sharedMem : ~SharedMemoryPort;
        :>> safetyLevel = ASIL::ASIL_D;
    }

    // Central ECU instance
    part domainController : CentralECU {
        :>> supplier.name = "Tier1Supplier-A";
        part socInstanceA : SoC_A;
        part socInstanceB : SoC_B;
        :>> socs : SoC[2] = (socInstanceA, socInstanceB);

        interface : SharedMemoryInterface connect
            consumerPort ::> socInstanceA.sharedMem to 
            supplierPort references socInstanceB.sharedMem;

        satisfy MinimumNumberOfMemoryBanks by socInstanceA;
        satisfy MinimumNumberOfMemoryBanks by socInstanceB;
    }
    
}