from fastapi import FastAPI, UploadFile, File, Form
from typing import Optional
from backend.auth.router import auth_router

app = FastAPI(
    title="LEGALMETRY Core API", 
    version="1.0.0",
    description="AI-Assisted Compliance Scanner for Legal Metrology (Packaged Commodities) Rules, 2011"
)

# Include Authentication Router
app.include_router(auth_router)

@app.get("/")
def health_check():
    return {"status": "ok", "service": "LEGALMETRY Backend"}

@app.post("/scan")
async def scan_endpoint(
    image: UploadFile = File(...),
    category: str = Form(...),
    coin_detected: Optional[bool] = Form(False)
):
    # Mock / real routing matching shared/api_contract.yaml
    return {
        "scan_id": "scan_mock_001",
        "extracted_fields": {
            "mrp": "Rs. 50.00",
            "net_quantity": "500 g",
            "manufacturer_address": "ABC Foods Ltd, Industrial Area, Mumbai",
            "mfg_date": "01/2026",
            "consumer_care": "care@abcfoods.com"
        },
        "measurements_mm": {
            "font_height_mm": 2.1,
            "principal_display_area_sq_cm": 120.0
        },
        "violations": [],
        "overall_severity": "COMPLIANT"
    }
