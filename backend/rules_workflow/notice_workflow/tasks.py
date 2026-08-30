# ==============================================================================
# LEGALMETRY — Celery Background Tasks (Person 4 / Module 2.11)
# Track 4: Rules & Workflow
# ==============================================================================

import logging
from .celery_app import celery_app
from .state_machine import ImprovementNoticeStateMachine

logger = logging.getLogger(__name__)

@celery_app.task(name="tasks.check_notice_window_expiration")
def check_notice_window_expiration(notice_dict: dict) -> dict:
    """
    Scheduled to wake up when 15-day correction window ends.
    Routes to supervisor verification without auto-penalizing.
    """
    logger.info(f"Checking notice expiration for {notice_dict.get('notice_id')}")
    updated = ImprovementNoticeStateMachine.transition(notice_dict, "WINDOW_EXPIRED")
    return updated
