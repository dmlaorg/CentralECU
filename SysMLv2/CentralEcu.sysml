package CentralECUDomain {

    private import SysML;
    private import SysML::PartUsage::*;
    private import SysML::PartDefinition::*;
    private import SysML::Systems::*;
    private import SysML::RequirementUsage::*;
    private import ScalarValues::*; 
    private import Automotive::*;

    requirement <'PTCnumber123456789'> MinimumNumberOfMemoryBanks : AutomotiveRequirement {
        doc /* The system shall have at least two separate non-volatile memory banks. */
        ::> id = "OTA-1-1";
        ::> text = "The system shall have at least two separate non-volatile memory banks.";
        ::> safetyLevel = ASIL::ASIL_D;
        //::> supplier = supplier {
        //    isInternal = true;
        //    domain = AutomotiveDomain::Power;
        //    name = "InternalSupplier";
        //    id = "INT-001";
        //    contactInfo = "";
        //    }

        subject soc : SoC;
        attribute memBanksRequired : Integer = 2;

        assume constraint { soc.safetyLevel == ASIL::ASIL_D }

        require constraint { soc.memory.matingOccurrences >= memBanksRequired }
    }

    part def CentralECU specializes AutomotiveElement {
        public part elements : AutomotiveElement[1..*];
        part socs : SoC[1..*] subsets elements;
    }

    part def SoC :> AutomotiveElement {
        part cores : Core[1..*];
        part softwares : eSoftware[1..*];
        part memory : memoryRegion[1..*];

        // Replace explicit Interface block with built-in SysML ports
        port channels : SharedMemoryPort[1..*];
    }

    part def Core :> AutomotiveElement {
        attribute FrequencyHz : Real;
        attribute isLockstep : Boolean;
    }

    part def eSoftware :> AutomotiveElement { }
    part def memoryRegion :> AutomotiveElement {
        attribute startAddress : Integer;
        attribute endAddress : Integer;
        attribute sizeKB : Integer;
    }

    part def ACC :> eSoftware {
        redefines safetyLevel = ASIL::ASIL_B;
    }
    // Concrete software components

    part ConcreteACC : ACC {
        redefines supplier.name = "Tier1Supplier-B";
    }

    part BrakeControl : eSoftware {
        attribute redefines safetyLevel[*] = ASIL::ASIL_D;
        redefines supplier.name = "Tier1Supplier-B";
    }

    part SwUpManager : eSoftware {
        redefines safetyLevel[4] = ASIL::QM;
        redefines supplier.name = "Tier1Supplier-A";
    }

    // Cores
    part CR7 : Core {
        :>> safetyLevel = ASIL::ASIL_D;
        redefines supplier.name = "Arm";
        redefines FrequencyHz = 800000000;
        redefines isLockstep = "true";
    }

    part CA57 : Core {
        redefines safetyLevel = ASIL::ASIL_B;
        redefines supplier.name = "Arm";
        redefines FrequencyHz = 1900000000;
        :>> isLockstep = false;
    }

    part CA53 : Core {
        redefines safetyLevel = 0;
        redefines supplier.name = "Arm";
        redefines FrequencyHz = 1500000000;
        redefines isLockstep = false;
    }

    // Use SysML port definition for shared memory communication
    port def SharedMemoryPort {
        attribute memory : memoryRegion;
        in item access : memoryRegion;
    }

    interface def SharedMemoryInterface {
        end [0..*] port consumerPort : SharedMemoryPort;
        end port supplierPort : ~SharedMemoryPort; 
    }

    // SoC instance
    part socInstance : SoC {
        redefines cores = (CR7, CA57, CA57, CA53, CA53);

        //part acc1         : ACC = ConcreteACC;
        part acc2         : ACC = ConcreteACC;
        part brakeCtrl   : eSoftware = ConcreteACC;
        part swUpManager = SwUpManager;
        part flash1 : memoryRegion {
            redefines sizeKB = 512.1; // No "conforming types" warning!
            :>> safetyLevel = ASIL::QM;
            :>> supplier.name = "MemorySupplier-A";
        }
        part flash2 : memoryRegion {
            :>> sizeKB = 512;
            :>> safetyLevel = ASIL::QM;
            :>> supplier.name = "MemorySupplier-A";
        }
        
        //:>> memory = {flash1, flash2}

        // channel using built-in port/interface
        port sharedMem : SharedMemoryPort;
    }

    part socInstanceB : SoC {
        port sharedMem : ~SharedMemoryPort;
    }

    // Central ECU instance
    part DomainController : CentralECU {
        ::> supplier.name = "Tier1Supplier-A";
        ::> socs : SoC[2] = {socInstance, socInstanceB};

        interface : SharedMemoryInterface
            consumerPort ::> socs[0].sharedMem to 
            supplierPort ::> socs[1].sharedMem;
    }
    
}