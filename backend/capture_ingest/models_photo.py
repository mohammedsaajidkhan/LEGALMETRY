# ==============================================================================
# LEGALMETRY — Capture Ingest Data Models (Person 2 - Ingest)
# ==============================================================================

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class CoinDetectionResult(BaseModel):
    detected: bool = Field(..., description="Whether a standard reference coin was detected")
    center_x: Optional[float] = Field(None, description="X coordinate of detected coin center")
    center_y: Optional[float] = Field(None, description="Y coordinate of detected coin center")
    radius_pixels: Optional[float] = Field(None, description="Radius in pixels of detected coin")
    coin_type: Optional[str] = Field("Rs. 10 (27mm)", description="Recognized coin denomination / series")
    known_diameter_mm: float = Field(27.0, description="Standard statutory diameter in millimeters")
    mm_per_pixel: Optional[float] = Field(None, description="Calibrated optical scaling factor")
    confidence: float = Field(0.0, description="Geometric circularity score (0.0 - 1.0)")

class QualityGateResult(BaseModel):
    passed: bool = Field(..., description="Whether image satisfies capture quality thresholds")
    blur_score: float = Field(..., description="Laplacian variance blur metric")
    is_blurry: bool = Field(..., description="True if blur_score is below minimum threshold")
    brightness_mean: float = Field(..., description="Average grayscale brightness value (0-255)")
    is_too_dark: bool = Field(..., description="True if mean brightness < 40")
    is_too_bright: bool = Field(..., description="True if mean brightness > 220")
    glare_detected: bool = Field(False, description="True if specular highlights occlude label")
    recommendation: Optional[str] = Field(None, description="Guidance to improve capture quality")

class PhotoCapturePayload(BaseModel):
    photo_id: str
    category: str
    quality: QualityGateResult
    coin_calibration: CoinDetectionResult
    sha256_hash: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
