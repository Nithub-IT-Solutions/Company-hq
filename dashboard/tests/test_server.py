import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from server import DashboardError, issue_body, validate_idea


class ValidateIdeaTests(unittest.TestCase):
    def test_normalizes_idea_fields(self):
        result = validate_idea(
            {"title": "  Invoice helper  ", "idea": "  Remind owners to invoice.  ", "audience": ""}
        )
        self.assertEqual(result["title"], "Invoice helper")
        self.assertEqual(result["idea"], "Remind owners to invoice.")
        self.assertEqual(result["audience"], "")

    def test_requires_title_and_description(self):
        with self.assertRaises(DashboardError):
            validate_idea({"title": "", "idea": "Description"})
        with self.assertRaises(DashboardError):
            validate_idea({"title": "Name", "idea": " "})

    def test_rejects_oversized_fields(self):
        with self.assertRaises(DashboardError):
            validate_idea({"title": "x" * 121, "idea": "Description"})
        with self.assertRaises(DashboardError):
            validate_idea({"title": "Name", "idea": "x" * 5001})

    def test_rejects_obvious_credentials(self):
        with self.assertRaises(DashboardError):
            validate_idea({"title": "Idea", "idea": "token github_pat_123456789012345678901234"})
        with self.assertRaises(DashboardError):
            validate_idea({"title": "Idea", "idea": "password=do-not-share"})

    def test_issue_body_declares_intake_only(self):
        body = issue_body(
            {"title": "Invoice helper", "idea": "Remind owners.", "audience": ""}
        )
        self.assertIn("Remind owners.", body)
        self.assertIn("does not start agent work", body)
        self.assertIn("Not specified yet", body)


if __name__ == "__main__":
    unittest.main()
