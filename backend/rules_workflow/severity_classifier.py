# ==============================================================================
# LEGALMETRY — Statutory Severity Classifier (Person 4 / Module 2.7)
# Track 4: Rules & Workflow
#
# Classifies statutory non-compliances and computes overall case verdict.
# CRITICAL: Missing mandatory origin / deceptive packaging / unmetered quantity.
# MODERATE: Font height deficit under Table I / missing customer care.
# MINOR: Formatting abbreviations / compliant pass.
# ==============================================================================

from typing import List, Dict, Any

def classify_overall_severity(violations: List[Dict[str, Any]]) -> str:
    """
    Computes overall statutory severity from a list of violations.
    """
    if not violations:
        return "COMPLIANT"

    severities = {v.get("severity", "MINOR").upper() for v in violations}

    if "CRITICAL" in severities:
        return "CRITICAL"
    if "MODERATE" in severities:
        return "MODERATE"
    if "MINOR" in severities:
        return "MINOR"

    return "NEEDS_REVIEW"
