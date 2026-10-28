import unittest
import sys
import tempfile
import zipfile
from email.message import Message
from io import BytesIO
from unittest.mock import patch
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from server import (
    DashboardError,
    DashboardHandler,
    approve_idea,
    copy_idea_attachments_to_project,
    idea_marker,
    idea_metadata,
    idea_record,
    is_tracked_idea,
    issue_body,
    deny_idea,
    replace_idea_metadata,
    repo_slug,
    run_gh,
    validate_idea,
    validate_attachments,
    save_idea_attachments,
    write_project_docs,
)


class ValidateIdeaTests(unittest.TestCase):
    def test_github_cli_output_uses_utf8(self):
        output = "Daisy’s companion"
        with patch("server.subprocess.run") as run:
            run.return_value.returncode = 0
            run.return_value.stdout = output
            self.assertEqual(run_gh(["issue", "list"]), output)

        self.assertEqual(run.call_args.kwargs["encoding"], "utf-8")

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

    def test_issue_metadata_lists_uploaded_knowledge_base_files(self):
        attachment = {
            "name": "market.pdf",
            "size": 1200,
            "media_type": "application/pdf",
        }
        body = issue_body(
            {"title": "Market research", "idea": "Review the market.", "audience": "Founders"},
            [attachment],
        )
        self.assertEqual(idea_metadata(body)["attachments"], [attachment])
        record = idea_record({"number": 21, "title": "Idea: Market research", "body": body})
        self.assertEqual(record["attachments"], [attachment])

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


class AttachmentTests(unittest.TestCase):
    @staticmethod
    def make_docx() -> bytes:
        output = BytesIO()
        with zipfile.ZipFile(output, "w") as document:
            document.writestr("word/document.xml", "<document/>")
        return output.getvalue()

    def test_accepts_supported_files_and_detects_mime_from_content(self):
        files = validate_attachments(
            [
                ("brief.pdf", b"%PDF-1.7\nsample"),
                ("plan.docx", self.make_docx()),
                ("photo.png", bytes.fromhex("89504E470D0A1A0A") + b"sample"),
                ("old-plan.doc", bytes.fromhex("D0CF11E0A1B11AE1") + b"sample"),
            ]
        )
        self.assertEqual([item["media_type"] for item in files], [
            "application/pdf",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "image/png",
            "application/msword",
        ])

    def test_rejects_mismatched_type_empty_file_and_unsafe_filename(self):
        for filename, content in (
            ("fake.pdf", b"not a PDF"),
            ("empty.png", b""),
            ("CON.pdf", b"%PDF-1.7"),
        ):
            with self.subTest(filename=filename), self.assertRaises(DashboardError):
                validate_attachments([(filename, content)])
        sanitized = validate_attachments([("../brief.pdf", b"%PDF-1.7")])
        self.assertEqual(sanitized[0]["name"], "brief.pdf")

    def test_enforces_file_count_and_size_caps(self):
        with self.assertRaises(DashboardError):
            validate_attachments([("brief.pdf", b"%PDF-1.7")] * 6)
        with self.assertRaises(DashboardError):
            validate_attachments([("brief.pdf", b"%PDF-" + b"x" * (8 * 1024 * 1024))])
        large_pdf = b"%PDF-" + b"x" * (8 * 1024 * 1024 - 5)
        with self.assertRaises(DashboardError):
            validate_attachments([(f"{index}.pdf", large_pdf) for index in range(4)])

    def test_persists_then_copies_attachments_into_project_knowledge_base(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            files = validate_attachments([("brief.pdf", b"%PDF-1.7\nsample")])
            with patch("server.APP_DATA_ROOT", root / "local-data"):
                metadata = save_idea_attachments(42, files)
                project = root / "project"
                project.mkdir()
                copy_idea_attachments_to_project(project, 42)
                self.assertEqual(metadata[0]["name"], "brief.pdf")
                self.assertEqual(
                    (project / "Knowledge base" / "brief.pdf").read_bytes(),
                    b"%PDF-1.7\nsample",
                )
                self.assertIn(
                    "untrusted data",
                    (project / "Knowledge base" / "README.md").read_text(encoding="utf-8"),
                )

    def test_reads_confirmation_and_files_from_multipart_request(self):
        boundary = "test-boundary"
        raw = (
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"confirmation\"\r\n\r\n"
            "abc123\r\n"
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"attachments\"; "
            "filename=\"brief.pdf\"\r\nContent-Type: application/pdf\r\n\r\n"
        ).encode() + b"%PDF-1.7\r\n" + f"--{boundary}--\r\n".encode()
        handler = object.__new__(DashboardHandler)
        handler.headers = Message()
        handler.headers["Content-Type"] = f"multipart/form-data; boundary={boundary}"
        handler.headers["Content-Length"] = str(len(raw))
        handler.rfile = BytesIO(raw)
        payload, files = handler._read_idea_confirmation()
        self.assertEqual(payload["confirmation"], "abc123")
        self.assertEqual(files[0]["name"], "brief.pdf")

if __name__ == "__main__":
    unittest.main()
