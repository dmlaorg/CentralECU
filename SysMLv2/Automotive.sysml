package Automotive {
    
    private import SysML;
    private import SysML::Systems::*;
    private import SysML::RequirementUsage::*;
    private import ScalarValues::*; 

    comment about Automotive
    /*
     * This package defines the types of items, parts and requirements that are specific to the automotive domain.
     */

    enum def ASIL :> Integer { 
        doc Summary 
            /* Automotive Safety Integrity Level (ASIL) is a risk classification scheme defined in the ISO 26262 standard 
             * for functional safety of road vehicles. The ASIL levels range from ASIL A (lowest risk) to ASIL D (highest risk), 
             * with QM (Quality Management) indicating that the item is not safety-related.
             */
        QM = 0;
        ASIL_A = 1;
        ASIL_B = 2;
        ASIL_C = 3;
        ASIL_D = 4;
    }

    enum def AutomotiveDomain {
        doc Summary
            /* AutomotiveDomain is an enumeration that categorizes the various domains within the automotive industry, 
             * such as powertrain, chassis, body, infotainment, and ADAS (Advanced Driver Assistance Systems).
             */
        Power;
        Chassis;
        Body;
        Cockpit;
        Telematic;
        Trailer;
    }

    attribute def Supplier {
        doc Summary
            /* Supplier is an attribute that indicates the supplier responsible for a particular automotive element, such as a software component or hardware part. */
        attribute isInternal : Boolean;
        attribute domain : AutomotiveDomain[1..*];
        attribute name : String;
        attribute id : String;
        attribute contactInfo : String[0..*];
        ref alternatives : Supplier[0..*];
    }

    abstract item def AutomotiveElement {
        doc Summary
            /* AutomotiveElement is the base type of all automotive-specific parts and requirements,
             * having attributes for SafetyLevel and Supplier.
             */
        attribute safetyLevel : ASIL[1];
        attribute supplier : Supplier;
    }

    requirement def AutomotiveRequirement {
        doc Summary
            /* AutomotiveRequirement is inherits from AutomotiveElement and includes additional ID and Text attributes.
             */
        attribute id : String;
        attribute text : String;
        subject : AutomotiveElement;
    }

}