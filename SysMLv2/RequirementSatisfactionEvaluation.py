# Requirement Satisfaction Evaluation Example based on SysIDE, tailored for the Central ECU example model.
import syside
import pathlib

EXAMPLE_DIR = pathlib.Path(__file__).parent
MODEL_FILE_PATHS = [
    EXAMPLE_DIR / "CentralEcu.sysml",
    EXAMPLE_DIR / "Automotive.sysml"
]
STANDARD_LIBRARY = syside.Environment.get_default().lib

def collect_requirements(model):
    requirements = [
        req
        for req in model.elements(syside.RequirementUsage, include_subtypes=True)
        if req.document.document_tier is syside.DocumentTier.Project
        and isinstance(req.owning_type, syside.Usage)
        and (
            not req.is_composite or not isinstance(req.owning_type, syside.RequirementUsage)
        )
    ]
    return requirements

def evaluate_requirements(requirements, compiler):
    for req in requirements:
        value, report = compiler.evaluate(
            req, stdlib=STANDARD_LIBRARY, experimental_quantities=True
        )
        if report.fatal or not isinstance(value, bool):
            marker = "[ ?? ]"
        else:
            marker = "[ OK ]" if value else "[FAIL]"
        print(f"  {marker} {req}")

def main():
    import sys
    import os
    sys.path.append(os.path.dirname(__file__))
    model, _ = syside.load_model(MODEL_FILE_PATHS)
    compiler = syside.Compiler()
    requirements = collect_requirements(model)
    evaluate_requirements(requirements, compiler)

if __name__ == "__main__":
    main()