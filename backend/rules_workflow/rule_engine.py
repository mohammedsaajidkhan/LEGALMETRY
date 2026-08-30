# ==============================================================================
# LEGALMETRY — Statutory Rule Engine (Person 4 / Module 2.6)
# Track 4: Rules & Workflow
#
# Deterministic rule checking against Legal Metrology (Packaged Commodities) Rules, 2011:
# - Rule 6 Mandatory Declarations
# - Table I Minimum Font Dimensions by PDP area
# - Second Schedule Standard Commodity Sizes
# ==============================================================================

from typing import Dict, Any, List, Optional

def evaluate_table_i_font(font_height_mm: Optional[float], pdp_sq_cm: Optional[float] = 140.0) -> tuple[bool, float, float]:
    """
    Evaluates font height compliance according to Table I of Legal Metrology Rules, 2011.
    Returns: (is_compliant, min_required_mm, deficit_mm)
    """
    if pdp_sq_cm is None:
        pdp_sq_cm = 140.0

    # Statutory Table I Minimums by Principal Display Area (PDP)
    if pdp_sq_cm <= 50.0:
        min_required_mm = 1.0
    elif pdp_sq_cm <= 100.0:
        min_required_mm = 1.5
    elif pdp_sq_cm <= 500.0:
        min_required_mm = 2.0
    elif pdp_sq_cm <= 2500.0:
        min_required_mm = 4.0
    else:
        min_required_mm = 6.0

    if font_height_mm is None or font_height_mm <= 0:
        return False, min_required_mm, min_required_mm

    is_compliant = font_height_mm >= min_required_mm
    deficit = max(0.0, round(min_required_mm - font_height_mm, 2))
    return is_compliant, min_required_mm, deficit


def evaluate_rule_6_declarations(extracted_fields: Dict[str, Any]) -> List[Dict[str, str]]:
    """
    Checks the presence and formatting of Rule 6 mandatory declarations.
    """
    violations = []

    mrp = extracted_fields.get("mrp")
    if not mrp or "missing" in str(mrp).lower() or not str(mrp).strip():
        violations.append({
            "field": "mrp",
            "rule_reference": "Rule 6(1)(e)",
            "description": "Maximum Retail Price (MRP) declaration is missing or unreadable on principal display panel.",
            "severity": "CRITICAL",
            "remedy": "Print unambiguous MRP inclusive of all taxes on Principal Display Panel."
        })

    net_quantity = extracted_fields.get("net_quantity")
    if not net_quantity or "missing" in str(net_quantity).lower() or not str(net_quantity).strip():
        violations.append({
            "field": "net_quantity",
            "rule_reference": "Rule 6(1)(d)",
            "description": "Net quantity with standard units of weight, measure or number is missing.",
            "severity": "CRITICAL",
            "remedy": "Declare net quantity using standard SI units (g, kg, ml, l) in statutory font size."
        })

    mfr_name = extracted_fields.get("manufacturer_name")
    mfr_address = extracted_fields.get("manufacturer_address")
    if not mfr_name and not mfr_address:
        violations.append({
            "field": "manufacturer_details",
            "rule_reference": "Rule 6(1)(a)",
            "description": "Name and complete address of the manufacturer, packer or importer is missing.",
            "severity": "CRITICAL",
            "remedy": "Affix complete registered entity name and physical address on package."
        })

    mfg_date = extracted_fields.get("mfg_date")
    if not mfg_date or "missing" in str(mfg_date).lower() or not str(mfg_date).strip():
        violations.append({
            "field": "mfg_date",
            "rule_reference": "Rule 6(1)(b)",
            "description": "Month and year of manufacture, packaging or import is missing.",
            "severity": "MODERATE",
            "remedy": "Print month and year of packaging in MM/YYYY format."
        })

    consumer_care = extracted_fields.get("consumer_care")
    if not consumer_care or "missing" in str(consumer_care).lower() or not str(consumer_care).strip():
        violations.append({
            "field": "consumer_care",
            "rule_reference": "Rule 6(1)(g)",
            "description": "Consumer care contact details (telephone number / email / address) missing.",
            "severity": "MODERATE",
            "remedy": "Provide dedicated consumer grievance email, phone number, and address."
        })

    return violations


def evaluate_compliance(
    extracted_fields: Dict[str, Any],
    measurements: Dict[str, Any],
    category: str = "General"
) -> Dict[str, Any]:
    """
    Executes full statutory rule evaluation.
    """
    violations = evaluate_rule_6_declarations(extracted_fields)

    font_height = measurements.get("font_height_mm")
    pdp_area = measurements.get("principal_display_area_sq_cm", 140.0)

    is_font_pass, min_font, deficit = evaluate_table_i_font(font_height, pdp_area)

    if not is_font_pass and font_height is not None:
        violations.append({
            "field": "font_height",
            "rule_reference": "Table I (Rule 7)",
            "description": f"Font height of {font_height:.2f} mm is below Table I statutory minimum of {min_font:.2f} mm (Deficit: {deficit:.2f} mm).",
            "severity": "MODERATE",
            "remedy": f"Increase principal numeral font height to minimum {min_font:.2f} mm for PDP area {pdp_area:.1f} cm²."
        })

    return {
        "violations": violations,
        "is_font_compliant": is_font_pass,
        "table_i_minimum_mm": min_font,
        "font_deficit_mm": deficit,
    }
