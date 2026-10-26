import unittest
import sys
import tempfile
from unittest.mock import patch
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from server import (
    DashboardError,
    approve_idea,
    idea_marker,
    idea_metadata,
    idea_record,
    is_tracked_idea,
    issue_body,
    deny_idea,
    replace_idea_metadata,
    repo_slug,
    validate_idea,
    write_project_docs,
)


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
        self.assertIn("only after CEO approval", body)
        self.assertIn("Not specified yet", body)

    def test_issue_metadata_persists_dashboard_state(self):
        body = issue_body({"title": "Invoice helper", "idea": "Remind owners.", "audience": "Shops"})
        metadata = idea_metadata(body)
        self.assertEqual(metadata["status"], "pending")
        updated = replace_idea_metadata(
            body,
            {"status": "changes_requested", "slug": "product-invoice-12"},
            "Changes requested",
        )
        self.assertEqual(idea_metadata(updated)["slug"], "product-invoice-12")
        self.assertIn("**Changes requested**", updated)

    def test_idea_record_links_to_created_private_project(self):
        record = idea_record(
            {
                "number": 12,
                "title": "Idea: Invoice helper",
                "url": "https://github.com/Nithub-IT-Solutions/Company-hq/issues/12",
                "state": "OPEN",
                "body": idea_marker({"status": "discovery", "slug": "product-invoice-helper-12"}),
            }
        )
        self.assertEqual(record["repo_url"], "https://github.com/Nithub-IT-Solutions/product-invoice-helper-12")
        self.assertEqual(record["status"], "discovery")

    def test_manual_idea_issues_remain_visible_without_dashboard_actions(self):
        issue = {
            "number": 14,
            "title": "Idea: Existing manual intake",
            "url": "https://github.com/Nithub-IT-Solutions/Company-hq/issues/14",
            "body": "An idea created before the dashboard.",
            "labels": [],
        }
        self.assertTrue(is_tracked_idea(issue))
        self.assertEqual(idea_record(issue)["status"], "manual")

    def test_repository_names_are_safe_and_issue_unique(self):
        self.assertEqual(repo_slug("  Invoice reminders! ", 123), "product-invoice-reminders-123")

    def test_project_scaffold_has_required_documentation(self):
        idea = {"title": "Invoice helper", "idea": "Remind owners.", "audience": "Shops"}
        issue = {"url": "https://github.com/Nithub-IT-Solutions/Company-hq/issues/12"}
        with tempfile.TemporaryDirectory() as temp_dir:
            write_project_docs(Path(temp_dir), idea, issue, "product-invoice-helper-12")
            docs = Path(temp_dir) / "docs"
            self.assertIn("Remind owners.", (docs / "Idea-Report.md").read_text(encoding="utf-8"))
            self.assertIn("Next process", (docs / "Next-Process.md").read_text(encoding="utf-8"))
            self.assertIn("Suggestions", (docs / "Suggestions.md").read_text(encoding="utf-8"))

    def test_deny_requires_and_persists_expectations(self):
        body = issue_body({"title": "Invoice helper", "idea": "Remind owners.", "audience": "Shops"})
        issue = {
            "number": 12,
            "title": "Idea: Invoice helper",
            "url": "https://github.com/Nithub-IT-Solutions/Company-hq/issues/12",
            "body": body,
            "state": "OPEN",
            "createdAt": "2026-10-26T10:00:00Z",
            "metadata": idea_metadata(body),
        }
        with (
            patch("server.require_ceo_identity"),
            patch("server.read_idea", return_value=issue),
            patch("server.run_gh") as run,
        ):
            with self.assertRaises(DashboardError):
                deny_idea(12, " ")
            result = deny_idea(12, "Narrow the audience to independent retailers.")

        self.assertEqual(result["status"], "changes_requested")
        edited_body = run.call_args_list[0].args[0][-1]
        self.assertIn("## CEO expectations", edited_body)
        self.assertIn("independent retailers", edited_body)
        self.assertIsNotNone(idea_metadata(edited_body))

    def test_approval_creates_project_then_dispatches_discovery(self):
        body = issue_body({"title": "Invoice helper", "idea": "Remind owners.", "audience": "Shops"})
        issue = {
            "number": 12,
            "title": "Idea: Invoice helper",
            "url": "https://github.com/Nithub-IT-Solutions/Company-hq/issues/12",
            "body": body,
            "state": "OPEN",
            "metadata": idea_metadata(body),
        }
        with (
            patch("server.require_ceo_identity"),
            patch("server.read_idea", return_value=issue),
            patch("server.save_idea_state", side_effect=lambda item, status, *_: {"status": status}),
            patch("server.repository_exists", return_value=False),
            patch("server.create_project_repository") as create_repo,
            patch("server.configure_project_repository") as configure_repo,
            patch("server.run_gh") as run,
        ):
            result = approve_idea(12)

        self.assertEqual(result["status"], "discovery")
        self.assertEqual(result["repo_name"], "product-invoice-helper-12")
        create_repo.assert_called_once()
        configure_repo.assert_called_once_with("product-invoice-helper-12")
        self.assertIn("workflow", run.call_args.args[0])
        self.assertIn("idea-discovery.yml", run.call_args.args[0])


if __name__ == "__main__":
    unittest.main()
