# ==============================================================================
# Unit Tests for LEGALMETRY Rules Engine & Jan Vishwas State Machine
# ==============================================================================

import unittest
from backend.rules_workflow.rule_engine import evaluate_compliance
from backend.rules_workflow.severity_classifier import classify_overall_severity
from backend.rules_workflow.confidence_router import route_by_confidence
from backend.rules_workflow.notice_workflow.state_machine import (
    ImprovementNoticeStateMachine, NoticeStatus
)

class TestRulesEngine(unittest.TestCase):

    def test_rule_6_compliant_package(self):
        fields = {
            "mrp": "₹ 50.00",
            "net_quantity": "500 g",
            "manufacturer_name": "ABC Foods Ltd",
            "manufacturer_address": "Mumbai",
            "mfg_date": "01/2026",
            "consumer_care": "care@abcfoods.com",
        }
        measurements = {
            "font_height_mm": 2.5,
            "principal_display_area_sq_cm": 120.0
        }
        result = evaluate_compliance(fields, measurements)
        self.assertEqual(len(result["violations"]), 0)
        self.assertTrue(result["is_font_compliant"])

    def test_rule_6_missing_mrp_critical(self):
        fields = {
            "mrp": None,
            "net_quantity": "500 g",
            "manufacturer_name": "ABC Foods Ltd",
            "mfg_date": "01/2026",
            "consumer_care": "care@abcfoods.com",
        }
        measurements = {
            "font_height_mm": 2.5,
            "principal_display_area_sq_cm": 120.0
        }
        result = evaluate_compliance(fields, measurements)
        self.assertGreater(len(result["violations"]), 0)
        severity = classify_overall_severity(result["violations"])
        self.assertEqual(severity, "CRITICAL")

    def test_jan_vishwas_state_machine_workflow(self):
        notice = ImprovementNoticeStateMachine.create_notice(
            notice_id="NOT_101",
            violation_id="VIOL_202",
            manufacturer_id="MFR_001"
        )
        self.assertEqual(notice["status"], NoticeStatus.NOTICE_ISSUED.value)

        # 1. Dispute during 15-day window
        disputed = ImprovementNoticeStateMachine.transition(notice, "DISPUTE")
        self.assertEqual(disputed["status"], NoticeStatus.DISPUTED.value)

        # 2. Self report fix
        pending_review = ImprovementNoticeStateMachine.transition(disputed, "SELF_REPORT_FIX", "Reprinted packaging")
        self.assertEqual(pending_review["status"], NoticeStatus.PENDING_SUPERVISOR_VERIFICATION.value)

        # 3. Supervisor confirms fix
        closed = ImprovementNoticeStateMachine.transition(pending_review, "SUPERVISOR_CONFIRM_FIX")
        self.assertEqual(closed["status"], NoticeStatus.CLOSED.value)

    def test_human_supervisor_second_offence_guardrail(self):
        # Window expired transition must lead to supervisor queue, NOT second offence directly
        notice = ImprovementNoticeStateMachine.create_notice("NOT_102", "VIOL_203", "MFR_002")
        expired = ImprovementNoticeStateMachine.transition(notice, "WINDOW_EXPIRED")
        self.assertEqual(expired["status"], NoticeStatus.ESCALATED_PENDING_VERIFICATION.value)

        # Only manual supervisor confirmation sets second offence
        second_offence = ImprovementNoticeStateMachine.transition(
            expired, "SUPERVISOR_CONFIRM_REVIOLATION", "Physical spot-check confirms identical non-compliance"
        )
        self.assertEqual(second_offence["status"], NoticeStatus.SECOND_OFFENCE_CONFIRMED.value)

if __name__ == "__main__":
    unittest.main()
