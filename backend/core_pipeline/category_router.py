# ==============================================================================
# LEGALMETRY — Category-Aware Verification Router (Person 3 / Module 2.5)
# Track 3: Core Pipeline
#
# Digitizes the Sixth Schedule & Rule 19 of the Legal Metrology Rules, 2011.
# Generates category-specific manual physical verification directives for field inspectors.
# ==============================================================================

from typing import Dict, Optional

class CategoryVerificationRouter:
    """Routes physical manual inspection requirements based on commodity category."""

    CATEGORY_DIRECTIVES: Dict[str, str] = {
        "Edible Oils & Vanaspati": (
            "Sixth Schedule & Rule 12 Directive: Verify declared volume against weight using declared density. "
            "Perform physical gross weight check on weighing balance (tolerance ± 1.5%)."
        ),
        "Biscuits, Bread & Confectionery": (
            "Second Schedule Item 4 Directive: Check standard pack size compliance. "
            "Verify presence of Unit Sale Price (USP in ₹/g or ₹/kg) alongside MRP."
        ),
        "Packaged Drinking Water & Beverages": (
            "Second Schedule Item 12 Directive: Verify standard volume size (200ml, 250ml, 500ml, 1L, 2L, 5L). "
            "Perform physical fill-level and tamper-evident cap seal verification."
        ),
        "Tea & Coffee": (
            "Second Schedule Item 2 Directive: Inspect standard mass packaging (25g, 50g, 100g, 250g, 500g, 1kg). "
            "Verify net weight on certified class II/III balance."
        ),
        "Milk Powder, Butter & Dairy": (
            "First Schedule Directive: Check net weight declaration and apply standard moisture loss tolerance "
            "allowance based on days elapsed since packaging."
        ),
        "Cement & Building Materials": (
            "Rule 27 & Sixth Schedule Directive: Standard 50kg bag check. Perform tare bag weight subtraction "
            "and verify gross mass on calibrated platform scale (tolerance ± 1.0%)."
        ),
        "Pulses, Cereals & Food Grains": (
            "Second Schedule Item 1 Directive: Check standardized packaging size (500g, 1kg, 2kg, 5kg). "
            "Perform 5-sample batch average tare verification."
        ),
        "Paints, Enamels & Varnishes": (
            "Second Schedule Item 9 Directive: Standard size verification (50ml, 100ml, 200ml, 500ml, 1L, 4L, 10L, 20L). "
            "Check viscosity and container headspace limit (< 10%)."
        ),
        "Soaps, Detergents & Cleaning": (
            "First Schedule Directive: Toilet soaps must declare TFM (Total Fatty Matter) percentage grade "
            "and nominal net weight at the time of packing."
        ),
    }

    DEFAULT_DIRECTIVE: str = (
        "Rule 19 General Directive: Verify package seal integrity and compare declared net quantity "
        "against certified reference standard weights if package appears tampered or underweight."
    )

    @classmethod
    def get_directive(cls, category: Optional[str]) -> str:
        """Returns statutory Sixth Schedule physical check directive for category."""
        if not category:
            return cls.DEFAULT_DIRECTIVE

        for key, directive in cls.CATEGORY_DIRECTIVES.items():
            if key.lower() in category.lower() or category.lower() in key.lower():
                return directive

        return cls.DEFAULT_DIRECTIVE
