# ==============================================================================
# LEGALMETRY — Jan Vishwas Improvement Notice State Machine (Person 4 / Module 2.11)
# Track 4: Rules & Workflow
#
# Implements the statutory 15-day Improvement Notice lifecycle under the
# Jan Vishwas (Amendment of Provisions) Act, 2026.
#
# NON-NEGOTIABLE RULE: The system NEVER auto-transitions a case to
# SECOND_OFFENCE_CONFIRMED purely by timer expiration. A human supervisor
# MUST confirm re-inspection physically.
# ==============================================================================

from enum import Enum
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any

class NoticeStatus(str, Enum):
    NOTICE_ISSUED = "NOTICE_ISSUED"
    DISPUTED = "DISPUTED"
    PENDING_SUPERVISOR_VERIFICATION = "PENDING_SUPERVISOR_VERIFICATION"
    ESCALATED_PENDING_VERIFICATION = "ESCALATED_PENDING_VERIFICATION"
    SECOND_OFFENCE_CONFIRMED = "SECOND_OFFENCE_CONFIRMED"
    CLOSED = "CLOSED"

class ImprovementNoticeStateMachine:
    CORRECTION_WINDOW_DAYS = 15

    @classmethod
    def create_notice(cls, notice_id: str, violation_id: str, manufacturer_id: str) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        window_end = now + timedelta(days=cls.CORRECTION_WINDOW_DAYS)
        return {
            "notice_id": notice_id,
            "violation_id": violation_id,
            "manufacturer_id": manufacturer_id,
            "status": NoticeStatus.NOTICE_ISSUED.value,
            "issued_at": now.isoformat(),
            "window_end_date": window_end.isoformat(),
            "is_disputed": False,
            "resolution_notes": None,
        }

    @classmethod
    def transition(cls, current_notice: Dict[str, Any], action: str, notes: Optional[str] = None) -> Dict[str, Any]:
        status = current_notice.get("status")
        updated = dict(current_notice)

        if action == "DISPUTE" and status == NoticeStatus.NOTICE_ISSUED.value:
            updated["status"] = NoticeStatus.DISPUTED.value
            updated["is_disputed"] = True

        elif action == "SELF_REPORT_FIX" and status in (NoticeStatus.NOTICE_ISSUED.value, NoticeStatus.DISPUTED.value):
            updated["status"] = NoticeStatus.PENDING_SUPERVISOR_VERIFICATION.value
            updated["resolution_notes"] = notes

        elif action == "WINDOW_EXPIRED" and status == NoticeStatus.NOTICE_ISSUED.value:
            # Routes to supervisor queue; never auto-declares 2nd offence
            updated["status"] = NoticeStatus.ESCALATED_PENDING_VERIFICATION.value

        elif action == "SUPERVISOR_CONFIRM_FIX":
            updated["status"] = NoticeStatus.CLOSED.value
            updated["resolution_notes"] = notes or "Compliance verified upon re-inspection."

        elif action == "SUPERVISOR_CONFIRM_REVIOLATION":
            # Explicit human supervisor action required per statutory safeguard
            updated["status"] = NoticeStatus.SECOND_OFFENCE_CONFIRMED.value
            updated["resolution_notes"] = notes or "Second offence confirmed during supervisor spot-check."

        return updated
