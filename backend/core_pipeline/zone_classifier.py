# ==============================================================================
# LEGALMETRY — Zone & Declaration Classifier (Person 3 / Module 2.3)
# Track 3: Core Pipeline
#
# Deterministic regex & keyword pattern classifier mapping extracted OCR text
# into statutory Rule 6 declaration fields.
# Deliberately NOT a machine learning layout model — fast, zero training data, auditable.
# ==============================================================================

import re
from typing import Dict, Optional, Any

class ZoneClassifier:
    """Classifies raw OCR text into Rule 6 mandatory declaration fields."""

    MRP_PATTERN = re.compile(
        r'(?:MRP|M\.R\.P\.?|MAX\.?\s*RETAIL\s*PRICE|₹|Rs\.?)\s*(?:INCL\.?\s*ALL\s*TAXES)?[:\s\.]*([₹Rs\.]*\s*[\d,]+\.?\d*)',
        re.IGNORECASE
    )

    NET_QTY_PATTERN = re.compile(
        r'(?:NET\s*(?:QTY|QUANTITY|WEIGHT|WT|VOLUME|VOL)?|CONTENTS?)[:\s\.]*([\d\.]+\s*(?:g|kg|gm|gms|ml|l|ltr|litre|litres|m|cm|units|u|pieces|pcs|n))\b',
        re.IGNORECASE
    )

    MFG_DATE_PATTERN = re.compile(
        r'(?:MFD|MFG|PACKED|PKD|MFR|DATE\s*OF\s*(?:MFG|PKG|PACKING))[:\s\.]*([0-3]?\d[\/\-\.][0-1]?\d[\/\-\.](?:20)?\d{2}|[0-1]?\d[\/\-\.](?:20)?\d{2}|(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[\/\-\.\s]*(?:20)?\d{2})',
        re.IGNORECASE
    )

    CONSUMER_CARE_EMAIL = re.compile(
        r'[\w\.-]+@[\w\.-]+\.\w+',
        re.IGNORECASE
    )

    CONSUMER_CARE_PHONE = re.compile(
        r'(?:1800\s*\d{3}\s*\d{3,4}|(?:\+91[\-\s]?)?[6-9]\d{9}|\b\d{3,5}[\-\s]?\d{6,8}\b)',
        re.IGNORECASE
    )

    MANUFACTURER_KEYWORDS = re.compile(
        r'(?:MFG\s*BY|MANUFACTURED\s*BY|PACKED\s*BY|IMPORTED\s*BY|MARKETED\s*BY|MFR)[\s:]*([^\n\r]+)',
        re.IGNORECASE
    )

    @classmethod
    def classify_text(cls, raw_text: str) -> Dict[str, Optional[str]]:
        """
        Parses text and extracts all statutory Rule 6 declarations.
        """
        if not raw_text:
            return {
                "mrp": None,
                "net_quantity": None,
                "manufacturer_name": None,
                "manufacturer_address": None,
                "mfg_date": None,
                "consumer_care": None,
            }

        extracted: Dict[str, Optional[str]] = {}

        # 1. Maximum Retail Price (MRP)
        mrp_match = cls.MRP_PATTERN.search(raw_text)
        if mrp_match:
            val = mrp_match.group(1).strip()
            if not val.startswith("Rs") and not val.startswith("₹"):
                val = f"₹ {val}"
            extracted["mrp"] = val
        else:
            extracted["mrp"] = None

        # 2. Net Quantity & Units
        net_qty_match = cls.NET_QTY_PATTERN.search(raw_text)
        if net_qty_match:
            extracted["net_quantity"] = net_qty_match.group(1).strip()
        else:
            # Fallback simple search for numbers + units
            fallback_qty = re.search(r'\b(\d+(?:\.\d+)?\s*(?:g|kg|ml|l|ltr))\b', raw_text, re.IGNORECASE)
            extracted["net_quantity"] = fallback_qty.group(1) if fallback_qty else None

        # 3. Manufacturer Details
        mfr_match = cls.MANUFACTURER_KEYWORDS.search(raw_text)
        if mfr_match:
            mfr_line = mfr_match.group(1).strip()
            extracted["manufacturer_name"] = mfr_line
            extracted["manufacturer_address"] = mfr_line
        else:
            # Look for entity indicators (Ltd, Pvt Ltd, Foods, Industries)
            entity_match = re.search(r'([^\n,]+(?:Pvt\.?\s*Ltd|Private\s*Limited|Limited|Ltd|Industries|Foods|Beverages|Corporation|Enterprises)[^\n]*)', raw_text, re.IGNORECASE)
            if entity_match:
                extracted["manufacturer_name"] = entity_match.group(1).strip()
                extracted["manufacturer_address"] = entity_match.group(1).strip()
            else:
                extracted["manufacturer_name"] = None
                extracted["manufacturer_address"] = None

        # 4. Month & Year of Mfg / Import
        date_match = cls.MFG_DATE_PATTERN.search(raw_text)
        if date_match:
            extracted["mfg_date"] = date_match.group(1).strip()
        else:
            extracted["mfg_date"] = None

        # 5. Consumer Care Details
        email_match = cls.CONSUMER_CARE_EMAIL.search(raw_text)
        phone_match = cls.CONSUMER_CARE_PHONE.search(raw_text)

        care_parts = []
        if email_match:
            care_parts.append(f"Email: {email_match.group(0)}")
        if phone_match:
            care_parts.append(f"Tel: {phone_match.group(0)}")

        if care_parts:
            extracted["consumer_care"] = ", ".join(care_parts)
        else:
            extracted["consumer_care"] = None

        return extracted
